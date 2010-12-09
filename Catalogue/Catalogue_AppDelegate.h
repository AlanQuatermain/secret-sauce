//
//  Catalogue_AppDelegate.h
//  Catalogue
//
//  Created by Jim Dovey on 10-12-08.
//  Copyright Kobo Inc. 2010 . All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CatalogueWindowController;

@interface Catalogue_AppDelegate : NSObject <NSApplicationDelegate> 
{
    CatalogueWindowController * mainWindowController;
}

@property (nonatomic, retain) CatalogueWindowController * mainWindowController;
@property (nonatomic, readonly) NSURL * defaultStoreURL;

@end
