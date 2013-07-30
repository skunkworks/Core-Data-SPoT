//
//  UIApplication+NetworkActivity.m
//  Fast SPoT
//
//  Created by Richard Shin on 7/19/13.
//  Copyright (c) 2013 Richard Shin. All rights reserved.
//

#import "UIApplication+NetworkActivity.h"
#import <libkern/OSAtomic.h>

@implementation UIApplication (NetworkActivity)

static int networkActivityCount = 0;
- (void)pushNetworkActivity
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    OSAtomicIncrement32(&networkActivityCount);
}

- (void)popNetworkActivity
{
    OSAtomicDecrement32(&networkActivityCount);
    if (!networkActivityCount) [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}
@end
