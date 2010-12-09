//
//  CatalogueWindowController.m
//  Catalogue
//
//  Created by Jim Dovey on 10-12-08.
//  Copyright 2010 Kobo Inc. All rights reserved.
//

#import "CatalogueWindowController.h"

@interface CatalogueWindowController ()
@property (nonatomic, retain, readwrite) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readwrite) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readwrite) NSManagedObjectContext *managedObjectContext;
@end

@implementation CatalogueWindowController

@synthesize storeURL, persistentStoreCoordinator, managedObjectModel, managedObjectContext, readOnly, listArrayController;

- (id) initWithStoreURL: (NSURL *) aURL
{
    self = [super initWithWindowNibName: @"CatalogueWindow"];
    if ( self == nil )
        return ( nil );
    
    self.storeURL = aURL;
    
    return ( self );
}

- (void) dealloc
{
    [storeURL release];
    [listArrayController release];
    [persistentStoreCoordinator release];
    [managedObjectModel release];
    [managedObjectContext release];
    [super dealloc];
}

- (void) importItems: (NSArray *) items fromForeignContext: (NSManagedObjectContext *) foreignContext
{
    dispatch_async( dispatch_get_main_queue(), ^{
        for ( NSManagedObject * obj in items )
        {
            NSManagedObject * newBook = [NSEntityDescription insertNewObjectForEntityForName: @"Book"
                                                                      inManagedObjectContext: self.managedObjectContext];
            NSDictionary * values = [obj dictionaryWithValuesForKeys: [NSArray arrayWithObjects: @"category", @"publicationDate", @"title", nil]];
            [newBook setValuesForKeysWithDictionary: values];
            
            // now determine the Author
            NSManagedObject * author = [obj valueForKey: @"author"];
            if ( author == nil )
                continue;
            
            NSFetchRequest * req = [NSFetchRequest new];
            [req setEntity: [NSEntityDescription entityForName: @"Author" inManagedObjectContext: self.managedObjectContext]];
            [req setFetchLimit: 1];
            [req setPredicate: [NSPredicate predicateWithFormat: @"(firstName == %@) and (lastName == %@)", [author valueForKey: @"firstName"], [author valueForKey: @"lastName"]]];
            
            id existingAuthor = [[self.managedObjectContext executeFetchRequest: req error: NULL] lastObject];
            if ( existingAuthor != nil )
            {
                [newBook setValue: existingAuthor forKey: @"author"];
                continue;
            }
            
            NSManagedObject * newAuthor = [NSEntityDescription insertNewObjectForEntityForName: @"Author"
                                                                        inManagedObjectContext: self.managedObjectContext];
            values = [author dictionaryWithValuesForKeys: [NSArray arrayWithObjects: @"firstName", @"lastName", nil]];
            [newAuthor setValuesForKeysWithDictionary: values];
            
            [newBook setValue: newAuthor forKey: @"author"];
        }
    });
    
    [self saveAction: self];
}

- (void) setStoreURL: (NSURL *) newURL
{
    self.managedObjectContext = nil;
    self.managedObjectModel = nil;
    self.persistentStoreCoordinator = nil;
    
    NSURL * aURL = [newURL copy];
    [storeURL release];
    storeURL = aURL;
    
    // load the new context stack
    (void)[self managedObjectContext];
}

/**
 Creates, retains, and returns the managed object model for the application 
 by merging all of the models found in the application bundle.
 */

- (NSManagedObjectModel *)managedObjectModel {
    
    if (managedObjectModel) return managedObjectModel;
	
    self.managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.  This 
 implementation will create and return a coordinator, having added the 
 store for the application to it.  (The directory for the store is created, 
 if necessary.)
 */

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
    
    if (persistentStoreCoordinator) return persistentStoreCoordinator;
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSAssert(NO, @"Managed object model is nil");
        NSLog(@"%@:%s No model to generate a store from", [self class], _cmd);
        return nil;
    }
    
    NSError * error = nil;
    
    self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: mom];
    if (![persistentStoreCoordinator addPersistentStoreWithType: NSXMLStoreType 
                                                  configuration: nil 
                                                            URL: storeURL 
                                                        options: nil 
                                                          error: &error]){
        [[NSApplication sharedApplication] presentError:error];
        [persistentStoreCoordinator release], persistentStoreCoordinator = nil;
        return nil;
    }    
    
    return persistentStoreCoordinator;
}

/**
 Returns the managed object context for the application (which is already
 bound to the persistent store coordinator for the application.) 
 */

- (NSManagedObjectContext *) managedObjectContext {
    
    if (managedObjectContext) return managedObjectContext;
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    self.managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator: coordinator];
    
    return managedObjectContext;
}

/**
 Returns the NSUndoManager for the application.  In this case, the manager
 returned is that of the managed object context for the application.
 */

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[self managedObjectContext] undoManager];
}


/**
 Performs the save action for the application, which is to send the save:
 message to the application's managed object context.  Any encountered errors
 are presented to the user.
 */

- (IBAction) saveAction:(id)sender {
    
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%s unable to commit editing before saving", [self class], _cmd);
    }
    
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

@end
