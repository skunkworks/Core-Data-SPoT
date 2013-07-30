//
//  Photo+Flickr.h
//  Core Data SPoT
//
//  Created by Richard Shin on 7/30/13.
//  Copyright (c) 2013 Richard Shin. All rights reserved.
//

#import "Photo.h"
#import "FlickrFetcher.h"

@interface Photo (Flickr)

+ (Photo *)photoWithFlickrInfo:(NSDictionary *)photoDictionary
        inManagedObjectContext:(NSManagedObjectContext *)context;

@end
