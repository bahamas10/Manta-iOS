//
//  FilesTableViewController.m
//  Manta
//
//  Created by Dave Eddy on 12/2/13.
//  Copyright (c) 2013 Dave Eddy. All rights reserved.
//

#import "FilesTableViewController.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "JSONStreamResponseSerializer.h"

@interface FilesTableViewController ()

@end

@implementation FilesTableViewController

// only called for root view
- (void)awakeFromNib
{
    NSArray *u = [NSUserDefaults.standardUserDefaults arrayForKey:@"Manta_Users_List"];
    // XXX DEBUG
    u = @[
          @{
              @"name": @"bahamas10",
              @"url": @"https://us-east.manta.joyent.com"
              },
          @{
              @"name": @"Joyent_Dev",
              @"url": @"https://us-east.manta.joyent.com"
              },
          @{
              @"name": @"devops@voxer.com",
              @"url": @"https://us-east.manta.joyent.com"
              }
          ];
    self.files = [NSMutableArray arrayWithArray:u];
    self.currentPath = @"/";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"UserCell"];
    
    // conditional edit button
    NSArray *components = [self.currentPath componentsSeparatedByString:@"/"];
    
    if ((self.isRootView) ||
        (self.getLevel >= 2 && components.count >= 3 && ![components[2] isEqualToString:@"public"]))
        self.navigationItem.rightBarButtonItem = self.editButtonItem;

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // add pull to refresh
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
    [refresh addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refresh;
    
    // load the table
    [self refresh];
}

#pragma mark - Manta API
- (void)refresh
{
    if (self.isRootView) {
        [self.refreshControl endRefreshing];
        return;
    }

    UIApplication.sharedApplication.networkActivityIndicatorVisible = YES;
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:self.mantaURL];
    manager.responseSerializer = [JSONStreamResponseSerializer serializer];
    [manager GET:self.currentPath parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        UIApplication.sharedApplication.networkActivityIndicatorVisible = NO;
        self.files = responseObject;
        
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        UIApplication.sharedApplication.networkActivityIndicatorVisible = NO;
        
        // if these conditions are true, we are accesing something we only have public access to
        if (operation.response.statusCode == 403 && self.getLevel == 1)
            self.files = [NSMutableArray arrayWithArray:@[@{@"name": @"public", @"type": @"directory"}]];
        
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
    }];
}

#pragma mark - IBAction
- (IBAction)refresh:(id)sender
{
    [self refresh];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.files.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"UserCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    NSDictionary *file = self.files[indexPath.row];
    cell.textLabel.text = file[@"name"];
    
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
        [self.files removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
    if (self.isRootView)
        [NSUserDefaults.standardUserDefaults setObject:self.files forKey:@"Manta_Users_List"];
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    id obj = self.files[fromIndexPath.row];
    [self.files removeObjectAtIndex:fromIndexPath.row];
    [self.files insertObject:obj atIndex:toIndexPath.row];
    if (self.isRootView)
        [NSUserDefaults.standardUserDefaults setObject:self.files forKey:@"Manta_Users_List"];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.isRootView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath)
        return;
    
    if (!self.files.count) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }

    NSDictionary *object = self.files[indexPath.row];
    if ([object[@"type"] isEqualToString:@"object"]) {
        NSString *urlString = [NSString stringWithFormat:@"%@%@/%@",
                               self.mantaURL.absoluteString,
                               self.currentPath,
                               object[@"name"]];
        NSLog(@"urlString = %@", urlString);
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:urlString]];
    } else {
        FilesTableViewController *newSubdirectoryController = [[FilesTableViewController alloc] init];
        NSString *subpath = [self.currentPath stringByAppendingPathComponent:object[@"name"]];
        newSubdirectoryController.currentPath = subpath;
        newSubdirectoryController.title = subpath.lastPathComponent;
        newSubdirectoryController.mantaURL = self.mantaURL ? self.mantaURL : [NSURL URLWithString:object[@"url"]];
        
        //newSubdirectoryController.shouldDisplaySearchBar = self.shouldDisplaySearchBar;
        //newSubdirectoryController.deliverDownloadNotifications = self.deliverDownloadNotifications;
        //newSubdirectoryController.allowedFileTypes = self.allowedFileTypes;
        //newSubdirectoryController.tableCellID = self.tableCellID;
        
        //[newSubdirectoryController listDirectoryAtPath:subpath];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.navigationController pushViewController:newSubdirectoryController animated:YES];
    }
}

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

#pragma mark - Helper functions
- (BOOL)isRootView
{
    return self.getLevel ? NO : YES;
}
- (NSInteger)getLevel
{
    return self.navigationController.viewControllers.count - 1;
}

@end
