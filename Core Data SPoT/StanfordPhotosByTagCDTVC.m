//
//  StanfordPhotosByTagCDTVC.m
//  Core Data SPoT
//
//  Created by Richard Shin on 7/31/13.
//  Copyright (c) 2013 Richard Shin. All rights reserved.
//

#import "StanfordPhotosByTagCDTVC.h"
#import "Photo.h"
#import "UIApplication+NetworkActivity.h"

@interface StanfordPhotosByTagCDTVC ()
@property (readonly, nonatomic) BOOL useOriginalSizeImage;
@end

@implementation StanfordPhotosByTagCDTVC

- (void)setTag:(Tag *)tag {
    _tag = tag;
    [self setupFetchedResultsController];
}

- (BOOL)useOriginalSizeImage {
    if (self.splitViewController) return YES;
    return NO;
}

// Sets up the FRC with a query for photos with a matching tag
- (void)setupFetchedResultsController
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Photo"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"title"
                                                              ascending:YES
                                                               selector:@selector(localizedCaseInsensitiveCompare:)]];
    request.predicate = [NSPredicate predicateWithFormat:@"any tags.text = %@", self.tag.text];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:self.tag.managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
}

// Displays image in image scroll view
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show Stanford Tagged Photo"]) {
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

#pragma mark - UITableViewDataSource methods

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Tagged Photo"];
    Photo *photo = (Photo *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.textLabel.text = photo.title;
    cell.detailTextLabel.text = photo.subtitle;
    
    // Display thumbnail if we have it. If not...
    if (photo.thumbnailPhoto) {
        cell.imageView.image = [UIImage imageWithData:photo.thumbnailPhoto];
    } else {
        // ...download thumbnail photo, but only if table view is not being scrolled or decelerating from scrolling.
        // This will prevent us from loading thumbnails while things are still in motion
        if (self.tableView.dragging == NO && self.tableView.decelerating == NO) {
            [self startThumbnailDownload:photo forIndexPath:indexPath];
        }
        
        // Until we get the downloaded thumbnail, use a placeholder image
        cell.imageView.image = [UIImage imageNamed:@"placeholder.png"];
    }
    
    return cell;
}

// Starts asynchronous thumbnail download for thumbnails on screen
- (void)startThumbnailDownload:(Photo *)photo forIndexPath:(NSIndexPath *)indexPath
{
    dispatch_queue_t thumbnailQ = dispatch_queue_create("Thumbnail queue", NULL);
    dispatch_async(thumbnailQ, ^{
        NSURL *thumbnailURL = [[NSURL alloc] initWithString:photo.thumbnailURL];
        
        // Fetch the thumbnail data
        [[UIApplication sharedApplication] pushNetworkActivity];
        NSData *photoData = [[NSData alloc] initWithContentsOfURL:thumbnailURL];
        [[UIApplication sharedApplication] popNetworkActivity];
        
        // Put thumbnail data into Core Data database. Use performBlock because we are not on the managed object context thread
        [photo.managedObjectContext performBlock:^{
            photo.thumbnailPhoto = photoData;
        }];
        
        // Finished downloading thumbnail, so display it in its cell
        UIImage *thumbnailImage = [[UIImage alloc] initWithData:photoData];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self displayThumbnail:thumbnailImage forIndexPath:indexPath];
        });
    });
}

// Displays thumbnail image in table view cell for a given index path
- (void)displayThumbnail:(UIImage *)thumbnail forIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.imageView.image = thumbnail;
}

// Loads thumbnails for rows currently displayed in table view. This is necessary to load thumbnails for cells
// that didn't get loaded because user was scrolling in table view.
- (void)loadThumbnailsForOnscreenRows
{
    NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
    for (NSIndexPath *indexPath in visiblePaths) {
        Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
        // Only download thumbnails for cells that don't have them
        if (!photo.thumbnailPhoto) {
            [self startThumbnailDownload:photo forIndexPath:indexPath];
        }
    }
}

#pragma mark - UIScrollViewDelegate methods

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    // Table view has fully decelerated from scrolling, so load thumbnails
    [self loadThumbnailsForOnscreenRows];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    // If user has finished scrolling in the table view and there's no further deceleration, load thumbnails
    if (!decelerate) {
        [self loadThumbnailsForOnscreenRows];
    }
}

@end
