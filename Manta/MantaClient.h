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
- (id)init;

- (id)initWithAccountName:(NSString *)accountName
              andMantaURL:(NSURL *)mantaURL;

- (id)initWithAccountName:(NSString *)accountName
              andMantaURL:(NSURL *)mantaURL
            andPrivateKey:(NSData *)privateKey;

- (void)ls:(NSString *)remotePath 
  callback:(void(^)(AFHTTPRequestOperation *operation, NSError *error, NSArray *objects))callback;

@property (nonatomic, strong) NSString *accountName;
@property (nonatomic, strong) NSURL *mantaURL;
@property (nonatomic, strong) NSData *privateKey;
@end
