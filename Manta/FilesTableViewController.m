//
//  FilesTableViewController.m
//  Manta
//
//  Created by Dave Eddy on 12/2/13.
//  Copyright (c) 2013 Dave Eddy. All rights reserved.
//

#import "FilesTableViewController.h"
#import "JSONStreamResponseSerializer.h"
#import "FilesTableViewCell.h"
#import "IndividualFileTableViewController.h"

#import <CommonCrypto/CommonCrypto.h>

#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import <AFNetworking/AFURLSessionManager.h>

@interface FilesTableViewController ()

@end

@implementation FilesTableViewController

#pragma mark - Lifecycle
- (void)awakeFromNib
{
    if (self.isRootView) {
        NSArray *u = [NSUserDefaults.standardUserDefaults arrayForKey:@"Manta_Users_List"];
        self.files = [NSMutableArray arrayWithArray:u];
        self.currentPath = @"/";
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.isRootView) {
        self.navigationItem.leftBarButtonItem = self.editButtonItem;
    }
    
    if (!self.isRootView) {
        self.navigationItem.rightBarButtonItem = nil;
        
        //UIBarButtonItem *addBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonPressed:)];
        //self.navigationItem.rightBarButtonItem = addBarButtonItem;
    }

    // load the table
    [self refresh];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.isRootView)
        [self refresh];
}

#pragma mark - Manta API
- (void)refresh
{
    if (self.isRootView) {
        NSArray *u = [NSUserDefaults.standardUserDefaults arrayForKey:@"Manta_Users_List"];
        self.files = [NSMutableArray arrayWithArray:u];
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
        return;
    }

    UIApplication.sharedApplication.networkActivityIndicatorVisible = YES;
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:self.mantaURL];
    manager.responseSerializer = [JSONStreamResponseSerializer serializer];
    [manager GET:self.currentPath parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        UIApplication.sharedApplication.networkActivityIndicatorVisible = NO;
        NSArray *sortedArray;
        // sort the files
        sortedArray = [responseObject sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            if ([a[@"type"] isEqualToString:@"directory"] && ![b[@"type"] isEqualToString:@"directory"])
                return NSOrderedAscending;
            if ([b[@"type"] isEqualToString:@"directory"] && ![a[@"type"] isEqualToString:@"directory"])
                return NSOrderedDescending;
            return [a[@"name"] compare:b[@"name"]];
        }];
        self.files = [NSMutableArray arrayWithArray:sortedArray];
        
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        UIApplication.sharedApplication.networkActivityIndicatorVisible = NO;
        
        if (operation.response.statusCode == 403 && self.getLevel == 1) {
            // if these conditions are true, we are accesing something we only have public access to
            self.files = [NSMutableArray arrayWithArray:@[@{@"name": @"public", @"type": @"directory"}]];
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
        
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
    }];
}


#pragma mark - IBAction and Selectors
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
        cell.imageView.image = icons[icons.count - 1];
    else
        cell.imageView.image = nil;
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.canEdit;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [self.files removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        
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
        // file click
        //[self downloadFile:object[@"name"]];
        IndividualFileTableViewController *individualFileViewController = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"IndividualFileTableVC"];
        
        NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/%@",
                                           self.mantaURL.absoluteString,
                                           self.currentPath,
                                           object[@"name"]]];
        NSString *localFile = [[self documentsDirectoryPath] stringByAppendingPathComponent:URL.path];
        
        individualFileViewController.file = object;
        individualFileViewController.title = object[@"name"];
        individualFileViewController.localFilePath = localFile;
        individualFileViewController.remoteURL = URL;
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.navigationController pushViewController:individualFileViewController animated:YES];
    } else {
        // sub-directory click
        FilesTableViewController *newSubdirectoryController = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"FilesTableVC"];
        NSString *subpath = [self.currentPath stringByAppendingPathComponent:object[@"name"]];
        newSubdirectoryController.currentPath = subpath;
        newSubdirectoryController.title = subpath.lastPathComponent;
        newSubdirectoryController.mantaURL = self.mantaURL;
        
        if (!newSubdirectoryController.mantaURL) {
            NSMutableString *URLString = [NSMutableString stringWithString:object[@"url"]];
            // remove trailing slash from URL
            while ([URLString hasSuffix: @"/"])
                [URLString deleteCharactersInRange:NSMakeRange(URLString.length - 1, 1)];
            
            newSubdirectoryController.mantaURL = [NSURL URLWithString:URLString];
        }
        
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
// check if the current view is the root of the stack
- (BOOL)isRootView
{
    return self.getLevel ? NO : YES;
}

// get the current stack level of the views
- (NSInteger)getLevel
{
    return self.navigationController.viewControllers.count - 1;
}

// determine if the current view should be editable
- (BOOL)canEdit
{
    NSArray *components = [self.currentPath componentsSeparatedByString:@"/"];
    return (self.isRootView) ||
           (self.getLevel >= 2 && components.count >= 3 && ![components[2] isEqualToString:@"public"]);
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

#pragma mark - RSA
- (NSData *)getSignatureBytes:(NSData *)plainText withPrivateKey:(SecKeyRef)privateKey
{
	OSStatus sanityCheck = noErr;
	NSData * signedHash = nil;
	
	size_t signedHashBytesSize = SecKeyGetBlockSize(privateKey);
	uint8_t *signedHashBytes = malloc(signedHashBytesSize * sizeof(uint8_t));
    if (signedHashBytes == NULL)
        return nil;
    
	memset((void *)signedHashBytes, 0x0, signedHashBytesSize);
	sanityCheck = SecKeyRawSign(privateKey,
                                kSecPaddingPKCS1SHA256,
                                (const uint8_t *)[[self getHash256Bytes:plainText] bytes],
                                CC_SHA256_DIGEST_LENGTH,
                                (uint8_t *)signedHashBytes,
                                &signedHashBytesSize);
	
	signedHash = [NSData dataWithBytes:(const void *)signedHashBytes length:(NSUInteger)signedHashBytesSize];
	if (signedHashBytes)
        free(signedHashBytes);
	
	return signedHash;
}

- (NSData *)getHash256Bytes:(NSData *)plainText
{
    NSMutableData *macOut = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(plainText.bytes, plainText.length,  macOut.mutableBytes);
    return macOut;
}



@end
