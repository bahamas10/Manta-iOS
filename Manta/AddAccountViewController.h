//
//  AddAccountViewController.h
//  Manta
//
//  Created by Dave Eddy on 12/8/13.
//  Copyright (c) 2013 Dave Eddy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddAccountViewController : UITableViewController
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *urlField;
- (IBAction)dismissKeyboard:(id)sender;
- (IBAction)addAccountButtonPressed:(id)sender;
@end
