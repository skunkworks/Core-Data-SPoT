//
//  StanfordPhotosByTag.h
//  Core Data SPoT
//
//  Created by Richard Shin on 7/31/13.
//  Copyright (c) 2013 Richard Shin. All rights reserved.
//

#import "CoreDataTableViewController.h"
#import "Tag.h"

@interface StanfordPhotosByTag : CoreDataTableViewController

@property (strong, nonatomic) Tag *tag;

@end
