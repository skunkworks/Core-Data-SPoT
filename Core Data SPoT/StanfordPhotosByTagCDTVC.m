//
//  StanfordPhotosByTagCDTVC.m
//  Core Data SPoT
//
//  Created by Richard Shin on 7/30/13.
//  Copyright (c) 2013 Richard Shin. All rights reserved.
//

#import "StanfordPhotosByTagCDTVC.h"
#import "FlickrFetcher.h"
#import "Photo+Flickr.h"
#import "UIApplication+NetworkActivity.h"

@interface StanfordPhotosByTagCDTVC ()

@end

@implementation StanfordPhotosByTagCDTVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Refresh control has to have target/action set up in viewDidLoad programmatically
    [self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // Create/open the document before this VC goes on screen. We don't want this in viewDidLoad because we want to
    // wait until just before VC goes on screen, but because we can appear multiple times we have to check that we
    // haven't already loaded
    if (!self.managedObjectContext) [self useDocument];
}

// Open/create managed object document to get a managed object context for our Core Data database access
- (void)useDocument
{
    NSURL *url = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    url = [url URLByAppendingPathComponent:@"SPoT Core Data Document"];

    UIManagedDocument *document = [[UIManagedDocument alloc] initWithFileURL:url];
    if (![[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
        // Create document
        [document saveToURL:url forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            if (success) self.managedObjectContext = document.managedObjectContext;
            // TODO: Putting up an activity indicator overlay on the table view might be nice, since on first
            // load there's no indication that a refresh is occurring because the UIRefreshControl is not visible
            [self refresh];
        }];
    } else {
        if (document.documentState == UIDocumentStateClosed) {
            // Open document if closed
            [document openWithCompletionHandler:^(BOOL success) {
                if (success) self.managedObjectContext = document.managedObjectContext;
            }];
        } else {
            // Document is already open
            self.managedObjectContext = document.managedObjectContext;
        }
    }
}

// Refreshes data from Flickr. Used by refreshControl and also when we first create our database in useDocument
- (IBAction)refresh
{
    [self.refreshControl beginRefreshing];
    
    // Fetch photos on another thread
    dispatch_queue_t tagPhotoQ = dispatch_queue_create("Stanford Tagged Photos", NULL);
    dispatch_async(tagPhotoQ, ^{
        [[UIApplication sharedApplication] pushNetworkActivity];
        NSArray *photos = [FlickrFetcher stanfordPhotos];
        [[UIApplication sharedApplication] popNetworkActivity];

        // Go through each photo and update our Core Data database. We have to do this on the managed object context's thread.
        [self.managedObjectContext performBlock:^{
            for (NSDictionary *photoDictionary in photos) {
                // This method takes care of inserting new objects (and not inserting any that we already have)
                [Photo photoWithFlickrInfo:photoDictionary inManagedObjectContext:self.managedObjectContext];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.refreshControl endRefreshing];
            });
        }];
    });
}

@end
