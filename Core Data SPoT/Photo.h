//
//  Photo.h
//  Core Data SPoT
//
//  Created by Richard Shin on 7/30/13.
//  Copyright (c) 2013 Richard Shin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Photographer, Tag;

@interface Photo : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * contentDescription;
@property (nonatomic, retain) NSString * uniqueID;
@property (nonatomic, retain) NSString * thumbnailURL;
@property (nonatomic, retain) NSString * imageURL;
@property (nonatomic, retain) NSData * thumbnailPhoto;
@property (nonatomic, retain) NSDate * lastViewed;
@property (nonatomic, retain) NSSet *tags;
@property (nonatomic, retain) Photographer *whoTook;
@end

@interface Photo (CoreDataGeneratedAccessors)

- (void)addTagsObject:(Tag *)value;
- (void)removeTagsObject:(Tag *)value;
- (void)addTags:(NSSet *)values;
- (void)removeTags:(NSSet *)values;

@end
