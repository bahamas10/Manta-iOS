//
//  IndividualFileTableViewController.h
//  Manta
//
//  Created by Dave Eddy on 12/8/13.
//  Copyright (c) 2013 Dave Eddy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IndividualFileTableViewController : UITableViewController
@property (strong, nonatomic) NSDictionary *file;
@property (strong, nonatomic) NSString *localFilePath;
@property (strong, nonatomic) NSURL *remoteURL;
@property (weak, nonatomic) IBOutlet UILabel *pathLabel;
@property (weak, nonatomic) IBOutlet UILabel *mtimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *availableLabel;
- (IBAction)downloadFileButtonPressed:(id)sender;
- (IBAction)openURLButtonPressed:(id)sender;
@end
