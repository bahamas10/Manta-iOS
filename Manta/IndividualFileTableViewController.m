//
//  IndividualFileTableViewController.m
//  Manta
//
//  Created by Dave Eddy on 12/8/13.
//  Copyright (c) 2013 Dave Eddy. All rights reserved.
//

#import "IndividualFileTableViewController.h"

#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import <AFNetworking/AFURLSessionManager.h>

@interface IndividualFileTableViewController ()

@end

@implementation IndividualFileTableViewController {
    UIDocumentInteractionController *interactionController;
    UIActionSheet *actionSheet;
}

#pragma mark - Lifecycle
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"file = %@", self.file);
    
    self.pathLabel.text = [NSString stringWithFormat:@"\n%@\n\n", self.remoteURL.path];
    [self.pathLabel sizeToFit];
    self.mtimeLabel.text = self.file[@"mtime"];
    self.sizeLabel.text = [self humanReadableBytes:[self.file[@"size"] integerValue]];
    
    actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                              delegate:self
                                     cancelButtonTitle:nil
                                destructiveButtonTitle:nil
                                     otherButtonTitles:nil];
    
    [actionSheet addButtonWithTitle:@"Open in Safari"];
    [actionSheet addButtonWithTitle:@"Copy Link"];
    actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:@"Cancel"];
    
    NSArray *components = [self.remoteURL.path componentsSeparatedByString:@"/"];
    if (components.count < 2 || ![components[2] isEqualToString:@"public"])
        self.navigationItem.rightBarButtonItem = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refresh:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBAction
- (IBAction)downloadFileButtonPressed:(id)sender
{
    if ([self.file[@"size"] integerValue] > MAX_DOWNLOAD_SIZE_BYTES) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"File too big"
                                                          message:[NSString stringWithFormat:@"File is greater than %@", [self humanReadableBytes:MAX_DOWNLOAD_SIZE_BYTES]]
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        [message show];
        return;
    }
    
    self.openButton.enabled = NO;
    self.downloadButton.enabled = NO;
    
    BOOL isDir = NO;
    BOOL fileExists = [NSFileManager.defaultManager fileExistsAtPath:self.localFilePath isDirectory:&isDir];
    if (fileExists && isDir) {
        // delete the directory, because the remote end says it is a file (object)
        NSLog(@"%@ is a directory when it should be a file, removing it", self.localFilePath);
        [NSFileManager.defaultManager removeItemAtPath:self.localFilePath error:nil];
    }
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    NSURLRequest *request = [NSURLRequest requestWithURL:self.remoteURL];
    
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        return [NSURL fileURLWithPath:self.localFilePath];
        
        self.downloadButton.enabled = YES;
        [self refresh:self];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        NSLog(@"File downloaded to: %@", filePath);
        
        self.downloadButton.enabled = YES;
        [self refresh:self];
    }];
    [downloadTask resume];
}

- (IBAction)openFileButtonPressed:(id)sender
{
    NSURL *localFileURL = [NSURL fileURLWithPath:self.localFilePath];
    interactionController = [UIDocumentInteractionController interactionControllerWithURL:localFileURL];
    interactionController.delegate = self;
    //[interactionController presentOpenInMenuFromBarButtonItem:self.shareButtonItem animated:YES];
    [interactionController presentPreviewAnimated:YES];
}

- (IBAction)shareButtonPressed:(id)sender
{
    if (!actionSheet.isVisible)
        [actionSheet showFromBarButtonItem:self.shareButtonItem animated:YES];
}

- (IBAction)refresh:(id)sender
{
    BOOL avail = self.fileAvailable;
    self.openButton.enabled = avail;
    self.availableLabel.text = avail ? @"locally" : @"remotely";
    [self.refreshControl endRefreshing];
}

#pragma mark - Helpers
- (BOOL)fileAvailable
{
    BOOL isDir = NO;
    BOOL fileExists = [NSFileManager.defaultManager fileExistsAtPath:self.localFilePath isDirectory:&isDir];
    return fileExists && !isDir;
}

- (NSString *)humanReadableBytes:(NSInteger)bytes
{
    NSString *units;
    NSInteger amount;
    if ((amount = bytes / 1024 / 1024 / 1024 / 1024))
        units = @"T";
    else if ((amount = bytes / 1024 / 1024 / 1024))
        units = @"G";
    else if ((amount = bytes / 1024 / 1024))
        units = @"M";
    else if ((amount = bytes / 1024))
        units = @"K";
    else
        units = @"B";
    if (!amount)
        amount = bytes;
    return [NSString stringWithFormat:@"%d%@", amount, units];
}

#pragma mark - UIActionSheet Delegate
- (void)actionSheet:(UIActionSheet *)actionSheet_ clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle = [actionSheet_ buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:@"Open File"]) {
        [self openFileButtonPressed:self];
    } else if ([buttonTitle isEqualToString:@"Open in Safari"]) {
        [UIApplication.sharedApplication openURL:self.remoteURL];
    } else if ([buttonTitle isEqualToString:@"Copy Link"]) {
        UIPasteboard.generalPasteboard.string = self.remoteURL.absoluteString;
    }
}

#pragma mark - Document Interaction Controller Delegate
- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller
{
    return self;
}

- (UIView *)documentInteractionControllerViewForPreview:(UIDocumentInteractionController *)controller
{
    return self.navigationController.view;
}

@end
