//
//  ModifyAccountTableViewController.m
//  Manta
//
//  Created by Dave Eddy on 12/8/13.
//  Copyright (c) 2013 Dave Eddy. All rights reserved.
//

#import "ModifyAccountTableViewController.h"

@interface ModifyAccountTableViewController ()

@end

@implementation ModifyAccountTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBAction
- (IBAction)dismissKeyboard:(id)sender
{
    [self becomeFirstResponder];
    [self resignFirstResponder];
}

- (IBAction)ModifyAccountButtonPressed:(id)sender
{
    NSString *username = self.nameField.text;
    NSString *mantaURL = self.urlField.text;
    
    if (!username || !mantaURL)
        return;
    
    NSDictionary *account = @{
                              @"name": username,
                              @"url": mantaURL
                              };
    
    NSMutableArray *u = [[NSUserDefaults.standardUserDefaults arrayForKey:@"Manta_Users_List"] mutableCopy];
    [u addObject:account];
    NSLog(@"u = %@", u);
    [NSUserDefaults.standardUserDefaults setObject:u forKey:@"Manta_Users_List"];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
