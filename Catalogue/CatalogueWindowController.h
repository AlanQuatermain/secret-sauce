//
//  CatalogueWindowController.h
//  Catalogue
//
//  Created by Jim Dovey on 10-12-08.
//  Copyright 2010 Kobo Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CatalogueWindowController : NSWindowController
{
    NSURL *storeURL;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
}

- (id) initWithStoreURL: (NSURL *) aURL;

@property (copy) NSURL * storeURL;
@property (assign) BOOL readOnly;
@property (retain) IBOutlet NSArrayController * listArrayController;

@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

- (IBAction)saveAction:sender;

- (void) importItems: (NSArray *) items fromForeignContext: (NSManagedObjectContext *) foreignContext;

@end
