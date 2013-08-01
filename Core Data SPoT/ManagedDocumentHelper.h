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

+ (void)managedObjectContextUsingBlock:(completion_block_t)block;

+ (UIManagedDocument *)sharedDocument;

@end
