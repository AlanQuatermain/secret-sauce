//
//  TimeMachineController.h
//  Catalogue
//
//  Created by Jim Dovey on 10-12-08.
//  Copyright 2010 Kobo Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <dispatch/dispatch.h>

@class CatalogueWindowController;

@interface TimeMachineController : NSObject
{
    CatalogueWindowController * __weak _mainWindowController;
    CatalogueWindowController * _snapshotWindowController;
    NSOperationQueue * _snapshotQ;
}

+ (TimeMachineController *) sharedController;

@property (assign) CatalogueWindowController * __weak mainWindowController;
@property (readonly) NSOperationQueue * snapshotQ;

- (IBAction) startTimeMachine: (id) sender;
- (void) endTimeMachine;

- (void) updateSnapshotForStoreURL: (NSURL *) storeURL;
- (void) invalidateSnapshots;

@end
