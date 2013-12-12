//
//  UsersTableViewController.m
//  Manta
//
//  Created by Dave Eddy on 12/11/13.
//  Copyright (c) 2013 Dave Eddy. All rights reserved.
//

#import "UsersTableViewController.h"

#import "MantaClient.h"
#import "FilesTableViewController.h"
#import "ModifyAccountTableViewController.h"

@interface UsersTableViewController ()

@end

@implementation UsersTableViewController

#pragma mark - Lifecycle
- (void)awakeFromNib
{
    self.mantaClients = [NSMutableDictionary new];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self refresh:self];
}

#pragma mark - IBAction and Selectors
- (IBAction)refresh:(id)sender
{
    self.users = [NSMutableArray arrayWithArray:[NSUserDefaults.standardUserDefaults arrayForKey:@"Manta_Users_List"]];
    [self.tableView reloadData];
    [self createMantaClients];
    [self.refreshControl endRefreshing];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.users.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"UsersCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
   
    cell.textLabel.text = self.users[indexPath.row][@"name"];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [self.users removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // nothing
    }
    
    [NSUserDefaults.standardUserDefaults setObject:self.users forKey:@"Manta_Users_List"];
    [self createMantaClients];
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    id obj = self.users[fromIndexPath.row];
    [self.users removeObjectAtIndex:fromIndexPath.row];
    [self.users insertObject:obj atIndex:toIndexPath.row];
    
    [NSUserDefaults.standardUserDefaults setObject:self.users forKey:@"Manta_Users_List"];
    [self createMantaClients];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath)
        return;
    
    if (!self.users.count) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }

    NSDictionary *account = self.users[indexPath.row];
    
    FilesTableViewController *newSubdirectoryController = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"FilesTableVC"];
    NSString *subpath = [NSString stringWithFormat:@"/%@", account[@"name"]];
    newSubdirectoryController.currentPath = subpath;
    newSubdirectoryController.title = subpath.lastPathComponent;
    newSubdirectoryController.mantaClient = self.mantaClients[account[@"name"]];
        
    // make the subdirectory if necessary
    NSString *localSubDirectory = [[self documentsDirectoryPath] stringByAppendingPathComponent:subpath];
    NSLog(@"localSubDirectory = %@", localSubDirectory);
    BOOL isDir = NO;
    BOOL fileExists = [NSFileManager.defaultManager fileExistsAtPath:localSubDirectory isDirectory:&isDir];
    if (!fileExists) {
        // create the dir
        [NSFileManager.defaultManager createDirectoryAtPath:localSubDirectory withIntermediateDirectories:NO attributes:nil error:nil];
    } else if (fileExists && !isDir) {
        // delete the file, then create the dir
        [NSFileManager.defaultManager removeItemAtPath:localSubDirectory error:nil];
        [NSFileManager.defaultManager createDirectoryAtPath:localSubDirectory withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.navigationController pushViewController:newSubdirectoryController animated:YES];
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"AddAccountSegue"]) {
        ModifyAccountTableViewController *vc = (ModifyAccountTableViewController *)segue.destinationViewController;
        vc.title = @"Add Acount";
    } else if ([segue.identifier isEqualToString:@"ModifyAccountSegue"]) {
        ModifyAccountTableViewController *vc = (ModifyAccountTableViewController *)segue.destinationViewController;
        UITableViewCell *cell = (UITableViewCell *)sender;
        vc.title = @"Modify Acount";
        vc.nameField.text = @"something";
        vc.urlField.text = @"something else";
    }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"AddAccountSegue"])
        return YES;
    else if ([identifier isEqualToString:@"ModifyAccountSegue"])
        return YES;
    return NO;
}

#pragma mark - Helper functions
// return the document directory path
- (NSString *)documentsDirectoryPath
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
}

// return the document directory URL
- (NSURL *)documentsDirectoryURL
{
    return [NSURL fileURLWithPath:[self documentsDirectoryPath]];
}

// create manta clients
- (void)createMantaClients
{
    NSArray *u = [NSUserDefaults.standardUserDefaults arrayForKey:@"Manta_Users_List"];
    for (NSDictionary *account in u) {
        NSString *accountName = account[@"name"];
        NSURL *mantaURL = [NSURL URLWithString:account[@"url"]];
        MantaClient *mc = [[MantaClient alloc] initWithAccountName:accountName andMantaURL:mantaURL];
        self.mantaClients[accountName] = mc;
    }
}

@end