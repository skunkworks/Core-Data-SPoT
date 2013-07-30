//
//  CachedPhoto.h
//  Fast SPoT
//
//  Created by Richard Shin on 7/20/13.
//  Copyright (c) 2013 Richard Shin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CachedPhoto : NSObject
@property (strong, nonatomic) NSString *fileName;
@property (strong, nonatomic) NSDate *lastAccessed;
@end
