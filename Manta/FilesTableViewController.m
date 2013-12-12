//
//  FilesTableViewController.m
//  Manta
//
//  Created by Dave Eddy on 12/2/13.
//  Copyright (c) 2013 Dave Eddy. All rights reserved.
//

#import "FilesTableViewController.h"
#import "FilesTableViewCell.h"
#import "IndividualFileTableViewController.h"
#import "MantaClient.h"

@interface FilesTableViewController ()

@end

@implementation FilesTableViewController

#pragma mark - Lifecycle
- (void)awakeFromNib
{
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self refresh:self];
}

#pragma mark - IBAction and Selectors
- (IBAction)refresh:(id)sender
{
    UIApplication.sharedApplication.networkActivityIndicatorVisible = YES;
    [self.mantaClient ls:self.currentPath callback:^(AFHTTPRequestOperation *operation, NSError *error, NSArray *objects) {
        if (error) {
            if (operation.response.statusCode == 403 && self.getLevel == 1) {
                // if these conditions are true, we are accesing something we only have public access to
                self.files = @[@{@"name": @"public", @"type": @"directory"}];
            } else {
                // a real error occurred, make an alert
                NSString *msg =  error.userInfo[NSLocalizedDescriptionKey];
                if (!msg)
                    msg = @"An unknown error has occurred";
                UIAlertView *alert = [[UIAlertView alloc]
                                      initWithTitle:@"Error"
                                      message:msg
                                      delegate:nil
                                      cancelButtonTitle:@"Dismiss"
                                      otherButtonTitles:nil];
                [alert show];
            }
        } else {
             NSArray *sorteddArray = [objects sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
                 if ([a[@"type"] isEqualToString:@"directory"] && ![b[@"type"] isEqualToString:@"directory"])
                     return NSOrderedAscending;
                 if ([b[@"type"] isEqualToString:@"directory"] && ![a[@"type"] isEqualToString:@"directory"])
                     return NSOrderedDescending;
                 return [a[@"name"] compare:b[@"name"]];
             }];
            self.files = sorteddArray;
        }
        
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
        UIApplication.sharedApplication.networkActivityIndicatorVisible = NO;
    }];
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
    static NSString *CellIdentifier = @"FilesCell";
    FilesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[FilesTableViewCell alloc] init];
    }
    
    NSDictionary *file = self.files[indexPath.row];
    cell.nameLabel.text = file[@"name"];
    cell.mtimeLabel.text = file[@"mtime"];
    
    if (![file[@"type"] isEqualToString:@"object"]) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    if ([file[@"type"] isEqualToString:@"directory"]) {
        cell.nameLabel.text = [NSString stringWithFormat:@"%@/", file[@"name"]];
    }
    
    NSArray *icons = [self iconsForFile:file[@"name"]];
    if (icons.count)
        cell.imageView.image = icons[0];
    else
        cell.imageView.image = nil;
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.canEdit;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // TODO unlink file from manta
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        
    }
    [self refresh:self];
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
        // file click
        //[self downloadFile:object[@"name"]];
        IndividualFileTableViewController *individualFileViewController = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"IndividualFileTableVC"];
        
        NSString *remotePath = [self.currentPath stringByAppendingPathComponent:object[@"name"]];
        NSString *localFile = [[self documentsDirectoryPath] stringByAppendingPathComponent:remotePath];
        
        individualFileViewController.file = object;
        individualFileViewController.title = object[@"name"];
        individualFileViewController.localFilePath = localFile;
        individualFileViewController.remoteFilePath = remotePath;
        individualFileViewController.mantaClient = self.mantaClient;
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.navigationController pushViewController:individualFileViewController animated:YES];
    } else {
        // sub-directory click
        FilesTableViewController *newSubdirectoryController = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"FilesTableVC"];
        NSString *subpath = [self.currentPath stringByAppendingPathComponent:object[@"name"]];
        newSubdirectoryController.currentPath = subpath;
        newSubdirectoryController.title = subpath.lastPathComponent;
        newSubdirectoryController.mantaClient = self.mantaClient;
        
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
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"IndividualFileSegue"])
        return NO;
    return YES;
}

#pragma mark - Helper functions
// get the current stack level of the views
- (NSInteger)getLevel
{
    return self.navigationController.viewControllers.count - 1;
}

// determine if the current view should be editable
- (BOOL)canEdit
{
    NSArray *components = [self.currentPath componentsSeparatedByString:@"/"];
    return components.count >= 3 && ![components[2] isEqualToString:@"public"];
}

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

// return icons for a given filename
- (NSArray *)iconsForFile:(NSString *)file
{
    UIDocumentInteractionController *docController = [[UIDocumentInteractionController alloc] init];
    docController.name = file;
    return docController.icons;
}

@end
