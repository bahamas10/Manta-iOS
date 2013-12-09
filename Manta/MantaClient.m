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
    
    // remove trailing slash from URL
    NSMutableString *URLString = [NSMutableString stringWithString:self.mantaURL.absoluteString];
    while ([URLString hasSuffix: @"/"])
        [URLString deleteCharactersInRange:NSMakeRange(URLString.length - 1, 1)];
    
    self.mantaURL = [NSURL URLWithString:URLString];
    
    return self;
}

- (void)ls:(NSString *)remotePath callback:(void(^)(AFHTTPRequestOperation *, NSError *, NSArray *))callback// *operation, NSError *error, NSArray *objects))callback
{
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:self.mantaURL];
    manager.responseSerializer = [JSONStreamResponseSerializer serializer];
    [manager GET:remotePath parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSArray *sorteddArray = [responseObject sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            if ([a[@"type"] isEqualToString:@"directory"] && ![b[@"type"] isEqualToString:@"directory"])
                return NSOrderedAscending;
            if ([b[@"type"] isEqualToString:@"directory"] && ![a[@"type"] isEqualToString:@"directory"])
                return NSOrderedDescending;
            return [a[@"name"] compare:b[@"name"]];
        }];
        callback(operation, nil, sorteddArray);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        callback(operation, error, nil);
    }];
}

#pragma mark - Crypto
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
    CC_SHA256(plainText.bytes, plainText.length, macOut.mutableBytes);
    return macOut;
}

@end
