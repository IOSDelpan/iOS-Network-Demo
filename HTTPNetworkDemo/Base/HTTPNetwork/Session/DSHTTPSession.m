//
//  DSHTTPSession.m
//  HTTPNetworkDemo
//
//  Created by DelpanSun on 2020/5/12.
//  Copyright © 2020 DelpanSun. All rights reserved.
//

#import "DSHTTPSession.h"

/**
*
* DSHTTPSession
*
*/
@interface DSHTTPSession () <NSURLSessionDataDelegate>

@end

@implementation DSHTTPSession

#pragma mark - Factory
+ (instancetype)session
{
    return [DSHTTPSession new];
}

#pragma mark - Public Methods
- (void)taskWithRequest:(NSURLRequest *)request
                handler:(id <DSHTTPSessionHandler>)handler
{
    NSData *responseData;
    
    if ([request.URL.absoluteString isEqualToString:@"Type1"])
    {
        NSDictionary *parameters = @{ @"data" : @{ @"key1" : @"value1" },
                                      @"message" : @"Success"
        };
        
        responseData = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:nil];
    }
    else
    {
        NSDictionary *parameters = @{ @"result" : @{ @"key2" : @"value2" },
                                      @"content" : @"Success"
        };
        
        responseData = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:nil];
    }
    
    [handler httpSession:self didReceiveHTTPResponse:nil];
    [handler httpSession:self didReceiveData:responseData];
    [handler httpSession:self httpResponse:nil didCompleteWithError:nil];
}

@end









































