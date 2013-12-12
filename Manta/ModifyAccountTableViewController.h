//
//  ModifyAccountViewController.h
//  Manta
//
//  Created by Dave Eddy on 12/8/13.
//  Copyright (c) 2013 Dave Eddy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ModifyAccountTableViewController : UITableViewController
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *urlField;
- (IBAction)dismissKeyboard:(id)sender;
- (IBAction)ModifyAccountButtonPressed:(id)sender;
@end
