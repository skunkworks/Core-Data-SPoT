//
//  StanfordPhotosByTag.m
//  Core Data SPoT
//
//  Created by Richard Shin on 7/31/13.
//  Copyright (c) 2013 Richard Shin. All rights reserved.
//

#import "StanfordPhotosByTag.h"
#import "Photo.h"

@interface StanfordPhotosByTag ()
// @property (strong, nonatomic) NSArray *photos;
@end

@implementation StanfordPhotosByTag

- (void)setTag:(Tag *)tag {
    _tag = tag;
    [self setupFetchedResultsController];
}

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

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Tagged Photo"];
    Photo *photo = (Photo *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.textLabel.text = photo.title;
    cell.detailTextLabel.text = photo.subtitle;
    // Only load cached thumbnails; defer new downloads until scrolling ends
    if (photo.thumbnailPhoto) {
        cell.imageView.image = [UIImage imageWithData:photo.thumbnailPhoto];
    } else {
        if (self.tableView.dragging == NO && self.tableView.decelerating == NO) {
            [self startThumbnailDownload:photo forIndexPath:indexPath];
        }
        // if a download is deferred or in progress, return a placeholder image
        cell.imageView.image = [UIImage imageNamed:@"placeholder.png"];
    }
    
    return cell;
}

// Starts thumbnail download for thumbnails on screen
- (void)startThumbnailDownload:(Photo *)photo forIndexPath:(NSIndexPath *)indexPath
{

}

// Loads thumbnails for rows currently displayed in table view
- (void)loadThumbnailsForOnscreenRows
{
    
}

#pragma mark - UIScrollViewDelegate methods

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    // Load thumbnails
    [self loadThumbnailsForOnscreenRows];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        // Load thumbnails
        [self loadThumbnailsForOnscreenRows];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
}

@end
