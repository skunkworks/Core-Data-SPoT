//
//  ManagedDocumentHelper.m
//  Core Data SPoT
//
//  Created by Richard Shin on 7/31/13.
//  Copyright (c) 2013 Richard Shin. All rights reserved.
//

#import "ManagedDocumentHelper.h"

@implementation ManagedDocumentHelper

static NSURL *url;

+ (UIManagedDocument *)sharedDocument
{
    static UIManagedDocument *document;
    
    @synchronized(self) {
        if (!document) {
            url = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
            url = [url URLByAppendingPathComponent:@"SPoT Core Data Document"];
            document = [[UIManagedDocument alloc] initWithFileURL:url];
        }
    }
    
    return document;
}

+ (void)managedObjectContextUsingBlock:(completion_block_t)block
{
    UIManagedDocument *document = [[self class] sharedDocument];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
        // Create document
        [document saveToURL:url forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            if (success) {
                block(document.managedObjectContext);
            } else {
                block(nil);
            }
        }];
    } else {
        if (document.documentState == UIDocumentStateClosed) {
            // Open document if closed
            [document openWithCompletionHandler:^(BOOL success) {
                if (success) {
                    block(document.managedObjectContext);
                } else {
                    block(nil);
                }
            }];
        } else {
            // Document is already open
            block(document.managedObjectContext);
        }
    }
}

@end
