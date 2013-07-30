//
//  Tag+Create.m
//  Core Data SPoT
//
//  Created by Richard Shin on 7/30/13.
//  Copyright (c) 2013 Richard Shin. All rights reserved.
//

#import "Tag+Create.h"

@implementation Tag (Create)

+ (Tag *)tagWithText:(NSString *)text inManagedObjectContext:(NSManagedObjectContext *)context
{
    Tag *tag = nil;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Tag"];
    request.predicate = [NSPredicate predicateWithFormat:@"text = %@", text];
    
    NSError *error;
    NSArray *results = [context executeFetchRequest:request error:&error];
    
    if (!results || [results count] > 1) {
        NSLog(@"Error searching for tag. Tag text: %@ Error: %@", text, error);
    } else if ([results count] == 1) {
        tag = results[0];
    } else {
        tag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:context];
        tag.text = text;
    }
    
    return tag;
}

@end
