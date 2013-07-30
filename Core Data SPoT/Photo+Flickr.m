//
//  Photo+Flickr.m
//  Core Data SPoT
//
//  Created by Richard Shin on 7/30/13.
//  Copyright (c) 2013 Richard Shin. All rights reserved.
//

#import "Photo+Flickr.h"

@implementation Photo (Flickr)

+ (Photo *)photoWithFlickrInfo:(NSDictionary *)photoDictionary
        inManagedObjectContext:(NSManagedObjectContext *)context
{
    Photo *photo = nil;
    
    // Check to see if photo already exists
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
    request.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES]];
    request.predicate = [NSPredicate predicateWithFormat:@"uniqueID = %@", [photoDictionary[FLICKR_PHOTO_ID] description]];
    
    NSError *error;
    NSArray *results = [context executeFetchRequest:request error:&error];
    
    if (!results || [results count] > 1) {
        // Error occurred
    } else if (![results count]){
        photo = [NSEntityDescription insertNewObjectForEntityForName:@"Photo"
                                              inManagedObjectContext:context];
        photo.uniqueID = photoDictionary[FLICKR_PHOTO_ID];
        photo.title = photoDictionary[FLICKR_PHOTO_TITLE];
        photo.subtitle = [photoDictionary valueForKeyPath:FLICKR_PHOTO_DESCRIPTION];
        photo.originalImageURL = [[FlickrFetcher urlForPhoto:photoDictionary format:FlickrPhotoFormatOriginal] absoluteString];
        photo.largeImageURL = [[FlickrFetcher urlForPhoto:photoDictionary format:FlickrPhotoFormatLarge] absoluteString];
        photo.thumbnailURL = [[FlickrFetcher urlForPhoto:photoDictionary format:FlickrPhotoFormatSquare] absoluteString];
        photo.lastViewed = [NSDate distantPast];
        photo.thumbnailPhoto = nil; // TODO
        photo.tags = nil; // TODO
        photo.whoTook = nil; // TODO
    } else {
        photo = results[0];
    }
    
    return photo;
}

@end
