//
//  DSHTTPResponseSerializer.m
//  HTTPNetworkDemo
//
//  Created by DelpanSun on 2020/5/12.
//  Copyright © 2020 DelpanSun. All rights reserved.
//

#import "DSHTTPResponseSerializer.h"

/**
 *
 * DSHTTPResponseJSONSerializer
 *
 */
@implementation DSHTTPResponseJSONSerializer
{
@public
    NSJSONReadingOptions _readingOptions;
}

#pragma mark - Factory
+ (instancetype)serializerWithReadingOptions:(NSJSONReadingOptions)readingOptions
{
    DSHTTPResponseJSONSerializer *serializer = [DSHTTPResponseJSONSerializer new];
    serializer->_readingOptions = readingOptions;
    return serializer;;
}

#pragma mark - Life cycle
- (instancetype)init
{
    if (self = [super init])
    {
        _readingOptions = NSJSONReadingAllowFragments;
    }
    
    return self;
}

#pragma mark - Public Methods
- (id)serializeWithHTTPResponse:(NSHTTPURLResponse *)httpResponse
                       httpBody:(NSData *)httpBody
                          error:(NSError *__autoreleasing *)error
{
    return [NSJSONSerialization JSONObjectWithData:httpBody options:_readingOptions error:error];
}

@end

























