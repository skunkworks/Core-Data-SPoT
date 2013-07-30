//
//  PhotoCache.h
//  Fast SPoT
//
//  Created by Richard Shin on 7/20/13.
//  Copyright (c) 2013 Richard Shin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotoCache : NSObject

// Set up the cache with a certain capacity. Setting persists between app launches
@property (nonatomic) NSUInteger capacity;

// Access singleton instance
+ (PhotoCache *)sharedInstance;

// Add a photo to the cache
- (void)addPhoto:(UIImage *)photo fromURL:(NSURL *)url;

// Retrieves a photo from the cache. Returns nil on cache miss
- (UIImage *)retrievePhotoForURL:(NSURL *)url;

// Clear out the cache
- (void)clear;
@end
