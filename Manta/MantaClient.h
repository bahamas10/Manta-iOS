//
//  MantaClient.h
//  Manta
//
//  Created by Dave Eddy on 12/9/13.
//  Copyright (c) 2013 Dave Eddy. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AFNetworking/AFHTTPRequestOperation.h>

@interface MantaClient : NSObject

#define MANTA_MAX_LS_LIMIT 1000

@property (nonatomic, strong) NSString *accountName;
@property (nonatomic, strong) NSURL *mantaURL;
@property (nonatomic, strong) NSData *privateKey;

- (id)init;

- (id)initWithAccountName:(NSString *)accountName
              andMantaURL:(NSURL *)mantaURL;

- (id)initWithAccountName:(NSString *)accountName
              andMantaURL:(NSURL *)mantaURL
            andPrivateKey:(NSData *)privateKey;

- (NSURL *)URLForPath:(NSString *)path;

- (void)ls:(NSString *)remotePath 
  callback:(void(^)(AFHTTPRequestOperation *, NSError *, NSArray *))callback;

- (void)ls:(NSString *)remotePath
     limit:(NSInteger)limit
  callback:(void(^)(AFHTTPRequestOperation *, NSError *, NSArray *))callback;

- (void)ls:(NSString *)remotePath
     limit:(NSInteger)limit
    marker:(NSString *)marker
  callback:(void(^)(AFHTTPRequestOperation *, NSError *, NSArray *))callback;

@end
