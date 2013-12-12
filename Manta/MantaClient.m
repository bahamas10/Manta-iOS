//
//  MantaClient.m
//  Manta
//
//  Created by Dave Eddy on 12/9/13.
//  Copyright (c) 2013 Dave Eddy. All rights reserved.
//

#import "MantaClient.h"

#import "JSONStreamResponseSerializer.h"

#import <AFNetworking/AFHTTPRequestOperationManager.h>

#import <CommonCrypto/CommonCrypto.h>

@implementation MantaClient

- (id)init
{
    return nil;
}

- (id)initWithAccountName:(NSString *)accountName
              andMantaURL:(NSURL *)mantaURL
{
    return [self initWithAccountName:accountName andMantaURL:mantaURL andPrivateKey:nil];
}

- (id)initWithAccountName:(NSString *)accountName
              andMantaURL:(NSURL *)mantaURL
            andPrivateKey:(NSData *)privateKey
{
    self = [super init];
    if (!self)
        return self;
    
    self.accountName = accountName;
    self.mantaURL = mantaURL;
    self.privateKey = privateKey;
    
    return self;
}

- (NSURL *)URLForPath:(NSString *)path
{
    return [[NSURL alloc] initWithScheme:self.mantaURL.scheme host:self.mantaURL.host path:path];
}

- (void)ls:(NSString *)remotePath
  callback:(void(^)(AFHTTPRequestOperation *, NSError *, NSArray *))callback
{
    return [self ls:remotePath limit:MANTA_MAX_LS_LIMIT callback:callback];
}

- (void)ls:(NSString *)remotePath
     limit:(NSInteger)limit
  callback:(void(^)(AFHTTPRequestOperation *, NSError *, NSArray *))callback
{
    return [self ls:remotePath limit:limit marker:nil callback:callback];
}

- (void)ls:(NSString *)remotePath
     limit:(NSInteger)limit
    marker:(NSString *)marker
  callback:(void(^)(AFHTTPRequestOperation *, NSError *, NSArray *))callback
{
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:self.mantaURL];
    manager.responseSerializer = [JSONStreamResponseSerializer serializer];
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    parameters[@"limit"] = [NSNumber numberWithInteger:limit];
    parameters[@"marker"] = marker ? marker : @"";
    
    [manager GET:remotePath
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             callback(operation, nil, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             callback(operation, error, nil);
    }];
}

#pragma mark - Crypto
- (NSData *)getSignatureBytes:(NSData *)plainText
               withPrivateKey:(SecKeyRef)privateKey
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
    CC_SHA256(plainText.bytes, plainText.length, macOut.mutableBytes);
    return macOut;
}

@end
