//
//  TimelineViewController.h
//  Social Networks Timeline
//
//  Created by KiKe on 18/01/13.
//  Copyright (c) 2013 KiKe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import <Accounts/Accounts.h>
#import <Twitter/Twitter.h>

#import "AppDelegate.h"
#import "TimelineViewCell.h"
#import "StatusData.h"

@interface TimelineViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *timelineTableView;
@property (nonatomic, weak) IBOutlet UIButton *loginButton;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *loadingActivityIndicatorView;
@property (nonatomic, weak) IBOutlet UIView *backgroundLoadingView;
@property (nonatomic, weak) IBOutlet TimelineViewCell *timelineViewCell;

- (IBAction)loginButtonClick;

@end
