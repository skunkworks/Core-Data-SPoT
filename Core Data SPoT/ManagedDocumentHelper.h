//
//  ManagedDocumentHelper.h
//  Core Data SPoT
//
//  Created by Richard Shin on 7/31/13.
//  Copyright (c) 2013 Richard Shin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ManagedDocumentHelper : NSObject

typedef void (^completion_block_t)(NSManagedObjectContext *managedObjectContext);

// Returns shared instance of managed document. Onus is on user to create/open document.
+ (UIManagedDocument *)sharedDocument;

// Alternate method of accessing the context from the shared managed document. Automatically handles creating/opening document.
// To use, pass in a completion block that assigns your context to the argument in the block's method signature.
// If it fails to create/open the managed document, the context will be nil.
//
// Example usage:
// [ManagedDocumentHelper managedObjectContextUsingBlock:^(NSManagedObjectContext *context) { self.context = context; if (!context) etc. etc. }
//
+ (void)managedObjectContextUsingBlock:(completion_block_t)block;


@end
