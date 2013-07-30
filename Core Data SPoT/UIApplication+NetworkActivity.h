//
//  UIApplication+NetworkActivity.h
//  Fast SPoT
//
//  Created by Richard Shin on 7/19/13.
//  Copyright (c) 2013 Richard Shin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIApplication (NetworkActivity)
- (void)pushNetworkActivity;
- (void)popNetworkActivity;
@end
