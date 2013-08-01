//
//  Photo+Flickr.m
//  Core Data SPoT
//
//  Created by Richard Shin on 7/30/13.
//  Copyright (c) 2013 Richard Shin. All rights reserved.
//

#import "Photo+Flickr.h"
#import "Tag+Create.h"

@implementation Photo (Flickr)

+ (Photo *)photoWithFlickrInfo:(NSDictionary *)photoDictionary
        inManagedObjectContext:(NSManagedObjectContext *)context
{
    Photo *photo = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
    request.predicate = [NSPredicate predicateWithFormat:@"uniqueID = %@", [photoDictionary[FLICKR_PHOTO_ID] description]];
    
    NSError *error;
    NSArray *results = [context executeFetchRequest:request error:&error];
    
    if (!results || [results count] > 1) {
        NSLog(@"Error searching for photo. Photo ID: %@ Error: %@", [photoDictionary[FLICKR_PHOTO_ID] description], error);
    } else if ([results count] == 1) {
        photo = results[0];
    } else {
        photo = [NSEntityDescription insertNewObjectForEntityForName:@"Photo"
                                              inManagedObjectContext:context];
        photo.uniqueID = photoDictionary[FLICKR_PHOTO_ID];
        photo.title = photoDictionary[FLICKR_PHOTO_TITLE];
        photo.subtitle = [photoDictionary valueForKeyPath:FLICKR_PHOTO_DESCRIPTION];
        photo.originalImageURL = [[FlickrFetcher urlForPhoto:photoDictionary format:FlickrPhotoFormatOriginal] absoluteString];
        photo.largeImageURL = [[FlickrFetcher urlForPhoto:photoDictionary format:FlickrPhotoFormatLarge] absoluteString];
        photo.thumbnailURL = [[FlickrFetcher urlForPhoto:photoDictionary format:FlickrPhotoFormatSquare] absoluteString];
        photo.lastViewed = nil;
        photo.thumbnailPhoto = nil; // TODO
        
        // Flickr photo dictionary contains tags as an NSString. We need to turn each tag string into its equivalent (Tag *) type.
        NSMutableSet *mutableTags = [[NSMutableSet alloc] init];
        NSArray *tokenizedTags = [((NSString *)photoDictionary[FLICKR_TAGS]) componentsSeparatedByString:@" "];
        for (NSString *tagText in tokenizedTags) {
            Tag *tag = [Tag tagWithText:tagText inManagedObjectContext:context];
            [mutableTags addObject:tag];
        }
        photo.tags = mutableTags;
    }
    
    return photo;
}

@end
