//
//  TimelineViewCell.h
//  Social Networks Timeline
//
//  Created by KiKe on 19/01/13.
//  Copyright (c) 2013 KiKe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TimelineViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView *userPhotoImageView;
@property (nonatomic, weak) IBOutlet UILabel *userNameLabel;
@property (nonatomic, weak) IBOutlet UITextView *userDescriptionLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;

@end
