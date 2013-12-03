//
//  JSONStreamResponseSerializer.m
//  Manta
//
//  Created by Dave Eddy on 12/2/13.
//  Copyright (c) 2013 Dave Eddy. All rights reserved.
//

#import "JSONStreamResponseSerializer.h"

@implementation JSONStreamResponseSerializer

+ (instancetype)serializer {
    return [[self alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (!self)
        return nil;
    
    self.acceptableContentTypes = [NSSet setWithObjects:@"application/x-json-stream", nil];
    
    return self;
}

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    if (![self validateResponse:(NSHTTPURLResponse *)response data:data error:error]) {
        if ([(NSError *)(*error) code] == NSURLErrorCannotDecodeContentData) {
            return nil;
        }
    }
    
    NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (responseString) {
        NSMutableArray *objects = [NSMutableArray new];
        for (NSString *entry in [responseString componentsSeparatedByString:@"\n"]) {
            if (!entry)
                continue;
            id j = [NSJSONSerialization JSONObjectWithData:[entry dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
            if (!j)
                continue;
            [objects addObject:j];
        }
        return objects;
    } else {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        [userInfo setValue:NSLocalizedStringFromTable(@"Data failed decoding as a UTF-8 string", nil, @"AFNetworking") forKey:NSLocalizedDescriptionKey];
        [userInfo setValue:[NSString stringWithFormat:NSLocalizedStringFromTable(@"Could not decode string: %@", nil, @"AFNetworking"), responseString] forKey:NSLocalizedFailureReasonErrorKey];
        if (error) {
            *error = [[NSError alloc] initWithDomain:@"something" code:NSURLErrorCannotDecodeContentData userInfo:userInfo];
        }
    }
    
    return nil;
}

@end
