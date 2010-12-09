//
//  TimeMachineController.m
//  Catalogue
//
//  Created by Jim Dovey on 10-12-08.
//  Copyright 2010 Kobo Inc. All rights reserved.
//

#import "TimeMachineController.h"
#import "BUTimeMachine.h"
#import "CatalogueWindowController.h"
#import "Catalogue_AppDelegate.h"
#import <dispatch/dispatch.h>

static void _safe_dispatch_sync_main( dispatch_block_t aBlock )
{
    if ( [NSThread isMainThread] )
    {
        aBlock();
    }
    else
    {
        dispatch_sync( dispatch_get_main_queue(), aBlock );
    }
}

static void _TimeMachineStarted( void )
{
    [[TimeMachineController sharedController] startTimeMachine: nil];
}

static void _TimeMachineDismissed( void * context )
{
    TimeMachineController * controller = (TimeMachineController *)context;
    [controller endTimeMachine];
}

static void _TimeMachineRestore( void * context, CFURLRef backupURL, CFURLRef liveURL,
                                 Boolean restoreAll, CFDictionaryRef options )
{
    TimeMachineController * controller = (TimeMachineController *)context;
    
    // keep the object stack around that the snapshot is using
    NSManagedObjectContext * snapshotStack = [controller.mainWindowController.managedObjectContext retain];
    NSArray * selection = [[controller.mainWindowController.listArrayController selectedObjects] copy];
    
    // first, reset the main controller to the default state here
    Catalogue_AppDelegate * delegate = (Catalogue_AppDelegate *)[[NSApplication sharedApplication] delegate];
    controller.mainWindowController.storeURL = delegate.defaultStoreURL;
    
    // if there's nothing selected, no import takes place
    if ( [selection count] == 0 )
        return;
    
    // now tell that controller to insert/reset the values from the selected list
    [controller.mainWindowController importItems: selection fromForeignContext: snapshotStack];
    
    // done with the selection list and the snapshot context now
    [selection release];
    [snapshotStack release];
}

static void _TimeMachineRequestSnapshot( void * context, CFURLRef backupURL )
{
    TimeMachineController * controller = (TimeMachineController *)context;
    [controller.snapshotQ addOperationWithBlock: ^{[controller updateSnapshotForStoreURL: (NSURL *)backupURL];}];
}

static void _TimeMachineActivateSnapshot( void * context, CFURLRef backupURL, CGRect bounds )
{
    TimeMachineController * controller = (TimeMachineController *)context;
    CatalogueWindowController * mainController = controller.mainWindowController;
    
    dispatch_async( dispatch_get_main_queue(), ^{
        mainController.storeURL = (NSURL *)backupURL;
        [[mainController window] makeKeyAndOrderFront: nil];
        BUActivatedSnapshot( [[mainController window] windowNumber], backupURL );
    });
}

static void _TimeMachineDeactivateSnapshot( void * context, CFURLRef backupURL )
{
    TimeMachineController * controller = (TimeMachineController *)context;
    CatalogueWindowController * mainController = controller.mainWindowController;
    
    dispatch_async( dispatch_get_main_queue(), ^{
        [[mainController window] orderOut: nil];
        BUDeactivatedSnapshot( [[mainController window] windowNumber], backupURL );
    });
}

#pragma mark -

@implementation TimeMachineController

@synthesize snapshotQ=_snapshotQ, mainWindowController=_mainWindowController;

+ (void) load
{
    // register once the main queue is up and running
    dispatch_async( dispatch_get_main_queue(), ^{
        BURegisterStartTimeMachineFromDock( &_TimeMachineStarted );
    });
}

+ (TimeMachineController *) sharedController
{
    static TimeMachineController * __singleton = nil;
    
    static dispatch_once_t __singleton_once = 0;
    dispatch_once( &__singleton_once, ^{
        __singleton = [TimeMachineController new];
    });
    
    return ( __singleton );
}

- (id) init
{
    self = [super init];
    if ( self == nil )
        return ( nil );
    
    _snapshotQ = [NSOperationQueue new];
    
    return ( self );
}

- (void) dealloc
{
    [_snapshotWindowController release];
    [_snapshotQ release];
    [super dealloc];
}

- (IBAction) startTimeMachine: (id) sender
{
    BURegisterTimeMachineDismissed( self, &_TimeMachineDismissed );
    BURegisterTimeMachineRestore( self, &_TimeMachineRestore );
    BURegisterRequestSnapshotImage( self, &_TimeMachineRequestSnapshot );
    BURegisterActivateSnapshot( self, &_TimeMachineActivateSnapshot );
    BURegisterDeactivateSnapshot( self, &_TimeMachineDeactivateSnapshot );
    
    self.mainWindowController.readOnly = YES;
    
    CFURLRef url = (CFURLRef)self.mainWindowController.storeURL;
    BUStartTimeMachine( [[self.mainWindowController window] windowNumber], url, 0 );
}

- (void) endTimeMachine
{
    self.mainWindowController.readOnly = NO;
    [_snapshotQ cancelAllOperations];
}

- (void) updateSnapshotForStoreURL: (NSURL *) storeURL
{
    if ( _snapshotWindowController == nil )
    {
        _safe_dispatch_sync_main( ^{
            _snapshotWindowController = [[CatalogueWindowController alloc] initWithStoreURL: storeURL];
            [[_snapshotWindowController window] orderOut: nil];
        });
    }
    
    dispatch_async( dispatch_get_main_queue(), ^{
        BUUpdateSnapshotImage( [[_snapshotWindowController window] windowNumber], (CFURLRef)storeURL );
    });
}

- (void) invalidateSnapshots
{
    // copy across any current state from the main controller, such as search field entry or selection, etc.
    BUInvalidateAllSnapshotImages();
}

@end
