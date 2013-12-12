//
//  FilesTableViewController.h
//  Manta
//
//  Created by Dave Eddy on 12/2/13.
//  Copyright (c) 2013 Dave Eddy. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MantaClient.h"

@interface FilesTableViewController : UITableViewController
@property (strong, nonatomic) MantaClient *mantaClient;
@property (strong, nonatomic) NSArray *files;
@property (strong, nonatomic) NSString *currentPath;
@end
