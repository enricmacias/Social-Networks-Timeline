//
//  AppDelegate.h
//  Social Networks Timeline
//
//  Created by KiKe on 18/01/13.
//  Copyright (c) 2013 KiKe. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TimelineViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

extern NSString *const FBSessionStateChangedNotification;

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) TimelineViewController *viewController;


- (BOOL)openSessionWithAllowLoginUI:(BOOL)allowLoginUI;


@end
