//
//  IndividualFileTableViewController.m
//  Manta
//
//  Created by Dave Eddy on 12/8/13.
//  Copyright (c) 2013 Dave Eddy. All rights reserved.
//

#import "IndividualFileTableViewController.h"

@interface IndividualFileTableViewController ()

@end

@implementation IndividualFileTableViewController

#pragma mark - Lifecycle
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"file = %@", self.file);
    self.pathLabel.text = [NSString stringWithFormat:@"\n%@\n\n", self.remoteURL.path];
    [self.pathLabel sizeToFit];
    self.mtimeLabel.text = self.file[@"mtime"];
    self.sizeLabel.text = [NSString stringWithFormat:@"%d bytes", [self.file[@"size"] intValue]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBAction
- (IBAction)downloadFileButtonPressed:(id)sender
{
    NSLog(@"should download %@", self.remoteURL);
    NSLog(@"to => %@", self.localFilePath);
}

- (IBAction)openURLButtonPressed:(id)sender
{
    [UIApplication.sharedApplication openURL:self.remoteURL];
}

#pragma mark - Table View
/*
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    
    return self.remoteURL.path;
}
 */

@end
