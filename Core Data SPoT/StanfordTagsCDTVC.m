//
//  StanfordTagsCDTVC.m
//  Core Data SPoT
//
//  Created by Richard Shin on 7/30/13.
//  Copyright (c) 2013 Richard Shin. All rights reserved.
//

#import "StanfordTagsCDTVC.h"
#import "FlickrFetcher.h"
#import "Photo+Flickr.h"
#import "UIApplication+NetworkActivity.h"
#import "Tag.h"
#import "ManagedDocumentHelper.h"

@interface StanfordTagsCDTVC () <UISplitViewControllerDelegate>
@property (strong, nonatomic) UIActivityIndicatorView *spinner;
@end

@implementation StanfordTagsCDTVC

- (UIActivityIndicatorView *)spinner {
    if (!_spinner) {
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _spinner.center = self.view.center;
        _spinner.hidesWhenStopped = YES;
        [self.view addSubview:self.spinner];
    }
    return _spinner;
}

- (void)awakeFromNib
{
    self.splitViewController.delegate = self;
}

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
    if (!self.managedObjectContext) {
        //[self useDocument];
        [ManagedDocumentHelper managedObjectContextUsingBlock:^(NSManagedObjectContext *managedObjectContext) {
            // Setting managedObjectContext also sets up our FRC
            self.managedObjectContext = managedObjectContext;
            
            // Force a refresh if there are 0 items in database
            if (![self.fetchedResultsController.fetchedObjects count]) {
                [self.spinner startAnimating];
                [self refresh];
            }
        }];
    }
}

// Open/create managed object document to get a managed object context for our Core Data database access
- (void)useDocument
{
    UIManagedDocument *document = [ManagedDocumentHelper sharedDocument];
    if (![[NSFileManager defaultManager] fileExistsAtPath:[document.fileURL path]]) {
        // Create document
        [document saveToURL:document.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            if (success) self.managedObjectContext = document.managedObjectContext;

            // Show spinner when refreshing Flickr data. Only really necessary for first-run case (i.e. when first creating Core Data database
            // that must be populated by querying Flickr over the network)
            [self.spinner startAnimating];
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
    // Display refreshing animation if this refresh was initiated by refreshControl
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
            
            // Force a save to the database. Helps get rid of pesky non-saves when stopping in XCode.
            [[ManagedDocumentHelper sharedDocument] saveToURL:[ManagedDocumentHelper sharedDocument].fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:nil];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.refreshControl endRefreshing];
                [self.spinner stopAnimating];
            });
        }];
    });
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];

    if (indexPath) {
        if ([[segue identifier] isEqualToString:@"Stanford Photos By Tag"]) {
            if ([segue.destinationViewController respondsToSelector:@selector(setTag:)]) {
                Tag *tag = (Tag *)[self.fetchedResultsController objectAtIndexPath:indexPath];
                NSString *title = [tag.text capitalizedString];
                
                [segue.destinationViewController performSelector:@selector(setTag:) withObject:tag];
                [segue.destinationViewController performSelector:@selector(setTitle:) withObject:title];
            }
        }
    }
}

#pragma mark - UISplitViewControllerDelegate methods
- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc
                                                                    inOrientation:(UIInterfaceOrientation)orientation
{
    return NO;
}

@end
