//
//  JSONStreamResponseSerializer.h
//  Manta
//
//  Created by Dave Eddy on 12/2/13.
//  Copyright (c) 2013 Dave Eddy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AFNetworking/AFURLResponseSerialization.h>

@interface JSONStreamResponseSerializer : AFHTTPResponseSerializer

+ (instancetype)serializer;
- (instancetype)init;
- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error;
@end
