//
//  FilesTableViewController.h
//  Manta
//
//  Created by Dave Eddy on 12/2/13.
//  Copyright (c) 2013 Dave Eddy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FilesTableViewController : UITableViewController
@property (strong, nonatomic) NSMutableArray *files;
@property (strong, nonatomic) NSString *currentPath;
@property (strong, nonatomic) NSURL *mantaURL;
@end
