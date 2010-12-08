//
//  Catalogue_AppDelegate.m
//  Catalogue
//
//  Created by Jim Dovey on 10-12-08.
//  Copyright Kobo Inc. 2010 . All rights reserved.
//

#import "Catalogue_AppDelegate.h"
#import "CatalogueWindowController.h"

@implementation Catalogue_AppDelegate

@synthesize mainWindowController;

/**
 Returns the support directory for the application, used to store the Core Data
 store file.  This code uses a directory named "Catalogue" for
 the content, either in the NSApplicationSupportDirectory location or (if the
 former cannot be found), the system's temporary directory.
 */

- (NSURL *)applicationSupportDirectory
{
    NSURL * baseURL = [[NSFileManager defaultManager] URLForDirectory: NSApplicationSupportDirectory
                                                             inDomain: NSUserDomainMask
                                                    appropriateForURL: nil
                                                               create: YES
                                                                error: NULL];
    if ( baseURL == nil )
        baseURL = [NSURL fileURLWithPath: NSTemporaryDirectory()];
    
    return [baseURL URLByAppendingPathComponent: @"Catalogue"];
}

- (void) applicationDidFinishLaunching: (NSNotification *) note
{
    NSURL * defaultStoreURL = [[self applicationSupportDirectory] URLByAppendingPathComponent: @"CatalogueStore.cts"];
    
    CatalogueWindowController * controller = [[CatalogueWindowController alloc] initWithStoreURL: defaultStoreURL];
    
    self.mainWindowController = controller;
    [controller release];
}

/**
    Implementation of the applicationShouldTerminate: method, used here to
    handle the saving of changes in the application managed object context
    before the application terminates.
 */
 
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {

    if (self.mainWindowController == nil) return NSTerminateNow;

    if (![self.mainWindowController.managedObjectContext commitEditing]) {
        NSLog(@"%@:%s unable to commit editing to terminate", [self class], _cmd);
        return NSTerminateCancel;
    }
    
    if (![self.mainWindowController.managedObjectContext hasChanges]) return NSTerminateNow;
    
    NSError *error = nil;
    if (![self.mainWindowController.managedObjectContext save:&error]) {
        
        // This error handling simply presents error information in a panel with an 
        // "Ok" button, which does not include any attempt at error recovery (meaning, 
        // attempting to fix the error.)  As a result, this implementation will 
        // present the information to the user and then follow up with a panel asking 
        // if the user wishes to "Quit Anyway", without saving the changes.
        
        // Typically, this process should be altered to include application-specific 
        // recovery steps.  
        
        BOOL result = [sender presentError:error];
        if (result) return NSTerminateCancel;
        
        NSString *question = NSLocalizedString(@"Could not save changes while quitting.  Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];
        
        NSInteger answer = [alert runModal];
        [alert release];
        alert = nil;
        
        if (answer == NSAlertAlternateReturn) return NSTerminateCancel;
        
    }
    
    return NSTerminateNow;
}


/**
    Implementation of dealloc, to release the retained variables.
 */
 
- (void)dealloc
{
    [mainWindowController release];
    [super dealloc];
}


@end
