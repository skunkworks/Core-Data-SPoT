//
//  Tag+Create.h
//  Core Data SPoT
//
//  Created by Richard Shin on 7/30/13.
//  Copyright (c) 2013 Richard Shin. All rights reserved.
//

#import "Tag.h"

@interface Tag (Create)

+ (Tag *)tagWithText:(NSString *)text inManagedObjectContext:(NSManagedObjectContext *)context;

@end
