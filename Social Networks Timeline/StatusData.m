//
//  StatusData.m
//  Social Networks Timeline
//
//  Created by KiKe on 19/01/13.
//  Copyright (c) 2013 KiKe. All rights reserved.
//

#import "StatusData.h"

@implementation StatusData

- (void)setFacebookDate:(NSString *)dateString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZZ"];
    NSDate *date = [dateFormatter dateFromString: dateString];
    
    [dateFormatter setDateFormat:@"EEE LLL dd HH:mm:ss ZZZZ yyyy"];
    
    NSString *realDateString = [dateFormatter stringFromDate:date];
    _date = realDateString;
}

- (void)setTwitterDate:(NSString *)dateString
{
    //NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    //[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    //[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
    //[dateFormatter setDateFormat:@"EEE LLL dd HH:mm:ss ZZZZ yyyy"];
    //NSDate *date = [dateFormatter dateFromString: dateString];
    
    //[dateFormatter setDateFormat:@"dd/MM/yyyy HH:mm:ss"];
    
    //NSString *realDateString = [dateFormatter stringFromDate:date];
    _date = dateString;
}


@end
