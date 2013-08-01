//
//  RecentPhotosCDTVC.m
//  Core Data SPoT
//
//  Created by Richard Shin on 7/31/13.
//  Copyright (c) 2013 Richard Shin. All rights reserved.
//

#import "RecentPhotosCDTVC.h"
#import "Photo.h"
#import "ManagedDocumentHelper.h"

@interface RecentPhotosCDTVC ()
@property (readonly, nonatomic) BOOL useOriginalSizeImage;

@end

@implementation RecentPhotosCDTVC

- (BOOL)useOriginalSizeImage {
    if (self.splitViewController) return YES;
    return NO;
}

#define MAX_RECENT_PHOTOS 5;

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    _managedObjectContext = managedObjectContext;

    // Now that we have a context, set up the fetched results controller (FRC) with a fetch request for recent photos.
    // The FRC will then be hooked up to the table view data source methods (in CDTVC).
    if (_managedObjectContext) {
        [self setupFetchedResultsController];
    }
}

- (void)setupFetchedResultsController
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"lastViewed" ascending:NO selector:@selector(compare:)]];
    request.predicate = [NSPredicate predicateWithFormat:@"lastViewed != nil"];
    request.fetchLimit = MAX_RECENT_PHOTOS;
    
    NSError *error;
    NSArray *results = [_managedObjectContext executeFetchRequest:request error:&error];
    
    if (!results) {
        self.fetchedResultsController = nil;
        NSLog(@"Error fetching results in %@: %@", [self class], error);
    } else {
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                            managedObjectContext:_managedObjectContext
                                                                              sectionNameKeyPath:nil
                                                                                       cacheName:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated
{    
    [super viewWillAppear:animated];
    // Create/open the document before this VC goes on screen. We don't want this in viewDidLoad because we want to
    // wait until just before VC goes on screen, but because we can appear multiple times we have to check that we
    // haven't already loaded
    if (!self.managedObjectContext) {
        [ManagedDocumentHelper managedObjectContextUsingBlock:^(NSManagedObjectContext *managedObjectContext) {
            self.managedObjectContext = managedObjectContext;
        }];
        //        [self useDocument];
    }
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

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Recently Viewed Photo"];
    Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.textLabel.text = photo.title;
    cell.detailTextLabel.text = photo.subtitle;
    // Unlike StanfordPhotosByTagCDTVC, we will never have to download a thumbnail because the image has already
    // been viewed and has therefore had its thumbnail downloaded
    cell.imageView.image = [[UIImage alloc] initWithData:photo.thumbnailPhoto];
    
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show Recently Viewed Photo"]) {
        if ([segue.destinationViewController respondsToSelector:@selector(setImageURL:)]) {
            NSIndexPath *indexPath = [self.tableView indexPathForCell: ((UITableViewCell *)sender)];
            Photo *photo = (Photo *)[self.fetchedResultsController objectAtIndexPath:indexPath];
            [photo.managedObjectContext performBlock:^{
                photo.lastViewed = [NSDate date];
            }];
            
            NSURL *imageURL = (self.useOriginalSizeImage) ?
            [[NSURL alloc] initWithString:photo.originalImageURL] :
            [[NSURL alloc] initWithString:photo.largeImageURL];
            [segue.destinationViewController performSelector:@selector(setImageURL:) withObject:imageURL];
        }
    }
}

@end
