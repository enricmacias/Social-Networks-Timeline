//
//  StatusData.h
//  Social Networks Timeline
//
//  Created by KiKe on 19/01/13.
//  Copyright (c) 2013 KiKe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StatusData : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *description;
@property (nonatomic, strong) NSString *date;
@property (nonatomic, strong) UIImage *photo;

- (void)setFacebookDate:(NSString *)dateString;
- (void)setTwitterDate:(NSString *)dateString;

@end
