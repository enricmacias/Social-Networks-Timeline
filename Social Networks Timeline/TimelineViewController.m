//
//  TimelineViewController.m
//  Social Networks Timeline
//
//  Created by KiKe on 18/01/13.
//  Copyright (c) 2013 KiKe. All rights reserved.
//

#import "TimelineViewController.h"

@interface TimelineViewController ()

@property (nonatomic, strong) NSArray *timelineDataArray;
@property (nonatomic, strong) NSMutableArray *auxTimelineDataArray;
@property (nonatomic, strong) NSArray *twitterAccounts;
@property (nonatomic) int numberOfRetrievedInfo;
@property (nonatomic, strong) UIRefreshControl *refreshControl;

- (void)retrieveDataFromFacebook;
- (void)retrieveDataFromTwitter;
- (void)saveDataFromFacebookResponse:(NSArray *)data;
- (void)saveDataFromTwitterResponse:(NSArray *)data;
- (void)facebookLogin;
- (void)checkTwitterSession;
- (void)sortRetrievedInformationAndReloadTimelineTable;
- (NSArray *)sortByStringDate:(NSMutableArray *)unsortedArray;
- (NSString *)phraseDateStringFromDate:(NSDate *)activityDate;
- (void)showAlertMessage:(NSString *)message andTitle:(NSString *)title;
- (void)refreshTimelineTableView;

@end

@implementation TimelineViewController

# pragma mark - Life cycle methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Init user interface
    [_timelineTableView setHidden:YES];
    [_loginButton setHidden:NO];
    [_backgroundLoadingView setHidden:YES];
    [_loadingActivityIndicatorView setHidden:YES];
    
    // Notification center for Facebook Login
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionStateChanged:) name:FBSessionStateChangedNotification object:nil];
    
    // Check the session for a cached token to show the proper authenticated
    // UI. However, since this is not user intitiated, do not show the login UX.
    // Facebook
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate openSessionWithAllowLoginUI:NO];
    // Twitter
    [self checkTwitterSession];
    
    // Init variables
    _auxTimelineDataArray = [NSMutableArray array];
    _numberOfRetrievedInfo = 0;
    
    // Add UIRefreshControl
    _refreshControl = [[UIRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(refreshTimelineTableView) forControlEvents:UIControlEventValueChanged];
    [_timelineTableView addSubview:_refreshControl];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    //_auxTimelineDataArray = nil;
    //_twitterAccounts = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// Autorotation for devices with iOS 5.1 or below
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// Autorotation for devices with iOS 6.0 and above
// Tell the system It should autorotate
- (BOOL) shouldAutorotate
{
    return YES;
}

// Tell the system what we support
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


- (void)sessionStateChanged:(NSNotification*)notification
{
    if (FBSession.activeSession.isOpen)
    {
        // Modify user interface
        [_timelineTableView setHidden:NO];
        [_loginButton setHidden:YES];
        [_loadingActivityIndicatorView setHidden:NO];
        [_backgroundLoadingView setHidden:NO];
        [_loadingActivityIndicatorView startAnimating];
        
        [self retrieveDataFromFacebook];
    }
    else
    {
        // Set user interface properly
        [_timelineTableView setHidden:YES];
        [_loginButton setHidden:NO];
        [_backgroundLoadingView setHidden:YES];
        [_loadingActivityIndicatorView setHidden:YES];
    }
}

# pragma mark - Private methods
- (void)retrieveDataFromFacebook
{
    if (FBSession.activeSession.isOpen)
    {
        // Retrieve feed data from registered user.
        NSString *request = [NSString stringWithFormat:@"me/posts?access_token=%@",FBSession.activeSession.accessToken];
        
        FBRequest *feedRequest = [FBRequest requestForGraphPath:request];
        [feedRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error)
        {
             if (!error)
             {
                 // We've obtained the response from the server
                 NSArray *data = [result objectForKey:@"data"];
                 //NSLog(@"DATA: %@",data);
                 
                 [self saveDataFromFacebookResponse:data];
             }
             else   [self showAlertMessage:error.localizedDescription andTitle:@"Error"];
            
            // We need to do this also in case of an error, so we don't know if the other
            // request was successfull.
            _numberOfRetrievedInfo++;
            if (_numberOfRetrievedInfo == 2)
            {
                [self performSelectorOnMainThread:@selector(sortRetrievedInformationAndReloadTimelineTable)
                                       withObject:nil
                                    waitUntilDone:YES];
            }
        }];
    }
}

- (void)retrieveDataFromTwitter
{
    if ([_twitterAccounts count] > 0)
    {
        NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
        
        NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
        [parameters setObject:@"50" forKey:@"count"];
        
        // Create a POST request for the target endpoint
        TWRequest *request = [[TWRequest alloc] initWithURL:url
                                                 parameters:parameters
                                              requestMethod:TWRequestMethodGET];
        
        // We use the first one for simplicity
        [request setAccount:[_twitterAccounts objectAtIndex:0]];
        
        // Perform the request.
        [request performRequestWithHandler:
         ^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
        {
            if (responseData)
            {
                // We've obtained the response from the server
                NSArray *data = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
                //NSLog(@"%@", data);
                
                [self saveDataFromTwitterResponse:data];
            }
            else    [self showAlertMessage:error.localizedDescription andTitle:@"Error"];
            
            // We need to do this also in case of an error, so we don't know if the other
            // request was successfull.
            _numberOfRetrievedInfo++;
            if (_numberOfRetrievedInfo == 2)
            {
                [self performSelectorOnMainThread:@selector(sortRetrievedInformationAndReloadTimelineTable)
                                       withObject:nil
                                    waitUntilDone:YES];
            }
        }];
    }
}

- (void)saveDataFromFacebookResponse:(NSArray *)data
{
    for (NSDictionary *feed in data)
    {
        //NSLog(@"%@", [feed objectForKey:@"type"]);
        
        // We only keep the feeds marked as status type, and ones with message field.
        // This way we are going to be able to blend this ones with the ones in Twitter.
        if([[feed objectForKey:@"type"] isEqualToString:@"status"] && [feed objectForKey:@"message"])
        {
            // Set Object with data
            StatusData *statusData = [[StatusData alloc] init];
            
            // Name
            NSDictionary *fromDictionary = [feed objectForKey:@"from"];
            [statusData setName:[fromDictionary objectForKey:@"name"]];
            
            // Photo
            NSString *photoURL = [NSString stringWithFormat:@"http://graph.facebook.com/%@/picture",[fromDictionary objectForKey:@"id"]];
            [statusData setPhoto:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:photoURL]]]];
            
            // Description
            [statusData setDescription:[feed objectForKey:@"message"]];
            
            // Date
            [statusData setFacebookDate:[feed objectForKey:@"created_time"]];
            
            [_auxTimelineDataArray addObject:statusData];
        }
    }
}

- (void)saveDataFromTwitterResponse:(NSArray *)data
{
    for (NSDictionary *feed in data)
    {
        // Set Object with data
        StatusData *statusData = [[StatusData alloc] init];
        
        // Name
        NSDictionary *userDictionary = [feed objectForKey:@"user"];
        [statusData setName:[userDictionary objectForKey:@"name"]];
        
        // Photo
        [statusData setPhoto:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[userDictionary objectForKey:@"profile_image_url"]]]]];
        
        // Description
        [statusData setDescription:[feed objectForKey:@"text"]];
        
        // Date
        [statusData setTwitterDate:[feed objectForKey:@"created_at"]];
        
        [_auxTimelineDataArray addObject:statusData];
    }
}

- (void)facebookLogin
{
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    // The user has initiated a login, so call the openSession method
    // and show the login UX if necessary.
    [appDelegate openSessionWithAllowLoginUI:YES];
}

- (void)checkTwitterSession
{
    //  Obtain the account instance for the user's Twitter account
    ACAccountStore *store = [[ACAccountStore alloc] init];
    ACAccountType *twitterAccountType =
    [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    //  Request permission from the user to access the available Twitter accounts
    [store requestAccessToAccountsWithType:twitterAccountType
                                   options:nil
                                completion:^(BOOL granted, NSError *error)
     {
         if (granted)
         {
             // Grab the available accounts
             _twitterAccounts = [store accountsWithAccountType:twitterAccountType];
             
             [self performSelectorOnMainThread:@selector(retrieveDataFromTwitter) withObject:nil waitUntilDone:YES];
         }
         else   NSLog(@"Twitter account unregistered");
     }];
}

- (void)sortRetrievedInformationAndReloadTimelineTable
{
    [self sortByStringDate:_auxTimelineDataArray];
    
    // Copy auxiliar array to the real one, so the information is ready to be visualized.
    _timelineDataArray = [[NSArray alloc] initWithArray:_auxTimelineDataArray];
    
    // Reload table
    [_timelineTableView reloadData];
    
    // Update user interface
    [_refreshControl endRefreshing];
    [_loadingActivityIndicatorView setHidden:YES];
    [_backgroundLoadingView setHidden:YES];
    [_loadingActivityIndicatorView stopAnimating];
    
    _numberOfRetrievedInfo = 0;
}

- (NSArray *)sortByStringDate:(NSMutableArray *)unsortedArray
{
    NSMutableArray *tempArray=[NSMutableArray array];
    for(int i=0;i<[unsortedArray count];i++)
    {
        NSDateFormatter *df=[[NSDateFormatter alloc]init];
        StatusData *statusData = [unsortedArray objectAtIndex:i];
        
        [df setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
        [df setDateFormat:@"EEE LLL dd HH:mm:ss ZZZZ yyyy"];
        NSDate *date=[df dateFromString:statusData.date];
        NSMutableDictionary *dict=[NSMutableDictionary dictionary];
        [dict setObject:statusData forKey:@"entity"];
        [dict setObject:date forKey:@"date"];
        [tempArray addObject:dict];
    }
    
    NSInteger counter=[tempArray count];
    NSDate *compareDate;
    NSInteger index;
    for(int i=0;i<counter;i++)
    {
        index=i;
        compareDate=[[tempArray objectAtIndex:i] valueForKey:@"date"];
        NSDate *compareDateSecond;
        for(int j=i+1;j<counter;j++)
        {
            compareDateSecond=[[tempArray objectAtIndex:j] valueForKey:@"date"];
            NSComparisonResult result = [compareDate compare:compareDateSecond];
            if(result == NSOrderedAscending)
            {
                compareDate=compareDateSecond;
                index=j;
            }
        }
        if(i!=index)
            [tempArray exchangeObjectAtIndex:i withObjectAtIndex:index];
    }
    
    
    [unsortedArray removeAllObjects];
    for(int i=0;i<[tempArray count];i++)
    {
        [unsortedArray addObject:[[tempArray objectAtIndex:i] valueForKey:@"entity"]];
    }
    return unsortedArray;
}

- (NSString *)phraseDateStringFromDate:(NSDate *)activityDate
{
    //Get current date time
    
    NSDate *currentDateTime = [NSDate dateWithTimeIntervalSinceNow:[[NSTimeZone timeZoneWithName:@"Europe/London"] secondsFromGMT]];
    
    //Get difference of time between two dates
    NSTimeInterval distanceBetweenDates = [currentDateTime timeIntervalSinceDate:activityDate];
    
    double secondsInAnWeek = 604800;
    double secondsInAnDay = 86400;
    double secondsInAnHour = 3600;
    double secondsInAnMinute = 60;
    
    NSInteger weeksBetweenDates = abs(distanceBetweenDates / secondsInAnWeek);
    NSInteger daysBetweenDates = abs(distanceBetweenDates / secondsInAnDay);
    NSInteger minutesBetweenDates = abs(distanceBetweenDates / secondsInAnMinute);
    NSInteger hoursBetweenDates = abs(distanceBetweenDates / secondsInAnHour);
    
    if (hoursBetweenDates < 1)
    {
        //Less than 1 hour
        if (minutesBetweenDates < 1)        return @"just now";
        else
        {
            //More than 1 minute
            if (minutesBetweenDates == 1)   return [NSString stringWithFormat:@"%d minute ago", minutesBetweenDates];
            else                            return [NSString stringWithFormat:@"%d minutes ago", minutesBetweenDates];
        }
    }
    else if (hoursBetweenDates < 24)
    {
        // < 24 hours
        if (hoursBetweenDates == 1)         return [NSString stringWithFormat:@"%d hour ago", hoursBetweenDates];
        else                                return [NSString stringWithFormat:@"%d hours ago", hoursBetweenDates];
    }
    else if (weeksBetweenDates < 1)
    {
        // > 24 hours & < 1 week
        if (daysBetweenDates == 1)          return [NSString stringWithFormat:@"%d day ago", daysBetweenDates];
        else                                return [NSString stringWithFormat:@"%d days ago", daysBetweenDates];
    }
    else
    {
        // > 1 week
        if (weeksBetweenDates == 1)         return [NSString stringWithFormat:@"%d week ago", weeksBetweenDates];
        else                                return [NSString stringWithFormat:@"%d weeks ago", weeksBetweenDates];
    }
    
    return @"";
}

- (void)showAlertMessage:(NSString *)message andTitle:(NSString *)title
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
}

- (void)refreshTimelineTableView
{
    //NSLog(@"refresh");
    
    [_auxTimelineDataArray removeAllObjects];
    
    [self retrieveDataFromFacebook];
    [self retrieveDataFromTwitter];
}

# pragma mark - Action button methods
- (IBAction)loginButtonClick
{
    //  First, we need to obtain the account instance for the user's Twitter account
    ACAccountStore *store = [[ACAccountStore alloc] init];
    ACAccountType *twitterAccountType =
    [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    //  Request permission from the user to access the available Twitter accounts
    [store requestAccessToAccountsWithType:twitterAccountType
                                   options:nil
                                completion:^(BOOL granted, NSError *error)
    {
         if (!granted)
         {
             // The user has no Twitter configured accounts
             [self showAlertMessage:@"Please, register your Twitter account at Settings." andTitle:@"Attention!"];
         }
         else
         {
             // Grab the available accounts
             _twitterAccounts = [store accountsWithAccountType:twitterAccountType];
             
             if ([_twitterAccounts count] > 0)
             {
                 //NSLog(@"OK");
                 //[self performSelectorOnMainThread:@selector(retrieveDataFromTwitter) withObject:nil waitUntilDone:NO];
                 
                 // If at least one Twitter account is well configured,
                 // we are ready take care of Facebook login.
                 [self performSelectorOnMainThread:@selector(facebookLogin) withObject:nil waitUntilDone:YES];
             }
         }
    }];
}

# pragma mark - UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _timelineDataArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
    return cell.frame.size.height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TimelineViewCell";
    
    TimelineViewCell *cell = (TimelineViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        [[NSBundle mainBundle] loadNibNamed:@"TimelineViewCell" owner:self options:nil];
        cell = _timelineViewCell;
        _timelineViewCell = nil;
    }
    
    // Configure the cell...
    StatusData *statusFeedInfo = [_timelineDataArray objectAtIndex:indexPath.row];
    
    // Set Name
    cell.userNameLabel.text = [statusFeedInfo name];
    
    // Set Description
    cell.userDescriptionLabel.text = [statusFeedInfo description];
    
    // Set date time
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    [dateFormatter setDateFormat:@"EEE LLL dd HH:mm:ss ZZZZ yyyy"];
    NSDate *date = [dateFormatter dateFromString: [statusFeedInfo date]];
    cell.dateLabel.text = [self phraseDateStringFromDate:date];
    
    // Set photo
    cell.userPhotoImageView.image = [statusFeedInfo photo];
    
    return cell;
}

@end
