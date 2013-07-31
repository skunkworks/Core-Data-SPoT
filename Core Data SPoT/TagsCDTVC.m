//
//  TagsCDTVC.m
//  Core Data SPoT
//
//  Created by Richard Shin on 7/30/13.
//  Copyright (c) 2013 Richard Shin. All rights reserved.
//

#import "TagsCDTVC.h"
#import "Tag.h"

@implementation TagsCDTVC

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    _managedObjectContext = managedObjectContext;
    
    // Now that we have a context, set up the fetched results controller (FRC) with a fetch request for all tags.
    // The FRC will then be hooked up to the table view data source methods (in CDTVC).
    if (_managedObjectContext) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Tag"];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"text" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
        request.predicate = nil;
        
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
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // On first load the UIRefreshControl is not visible, so show placeholder cell to show that a refresh is occurring
    if ([self.tableView numberOfRowsInSection:0] == 0 && indexPath.row == 0) {
        UITableViewCell *placeholderCell = [tableView dequeueReusableCellWithIdentifier:@"PlaceholderCell"];
        if (placeholderCell == nil)
		{
            placeholderCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                                     reuseIdentifier:@"PlaceholderCell"];
			placeholderCell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
		placeholderCell.detailTextLabel.text = @"Loading…";
        placeholderCell.detailTextLabel.textAlignment = NSTextAlignmentCenter;
		
		return placeholderCell;
    }
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Tag"];
    
    Tag *tag = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = [tag.text capitalizedString];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d photos", [tag.photos count]];
    
    return cell;
}

@end
