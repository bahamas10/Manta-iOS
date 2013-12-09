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
@property (strong, nonatomic) NSMutableDictionary *mantaClients;
@property (strong, nonatomic) MantaClient *mantaClient;
@property (strong, nonatomic) NSMutableArray *files;
@property (strong, nonatomic) NSString *currentPath;
@property (strong, nonatomic) NSURL *mantaURL;
@end
