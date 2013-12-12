//
//  UsersTableViewController.h
//  Manta
//
//  Created by Dave Eddy on 12/11/13.
//  Copyright (c) 2013 Dave Eddy. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MantaClient.h"

@interface UsersTableViewController : UITableViewController
@property (strong, nonatomic) NSMutableDictionary *mantaClients;
@property (strong, nonatomic) NSMutableArray *users;
@end