//
//  Photographer+Create.m
//  Core Data SPoT
//
//  Created by Richard Shin on 7/30/13.
//  Copyright (c) 2013 Richard Shin. All rights reserved.
//

#import "Photographer+Create.h"

@implementation Photographer (Create)

+ (Photographer *)photographerWithName:(NSString *)name
                inManagedObjectContext:(NSManagedObjectContext *)context
{
    Photographer *photographer = nil;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Photographer"];
    request.predicate = [NSPredicate predicateWithFormat:@"name = %@", name];
    
    NSError *error;
    NSArray *results = [context executeFetchRequest:request error:&error];
    
    if (!results || [results count] > 1) {
        // Log error
        NSLog(@"Error searching for photographer. Photographer name: %@ Error: %@", name, error);
    } else if ([results count] == 1) {
        // Use existing photographer
        photographer = results[0];
    } else {
        photographer = [NSEntityDescription insertNewObjectForEntityForName:@"Photographer" inManagedObjectContext:context];
        photographer.name = name;
    }
    
    return photographer;
}

@end
