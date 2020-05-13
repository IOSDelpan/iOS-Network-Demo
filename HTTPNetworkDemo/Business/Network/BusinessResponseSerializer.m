//
//  BusinessResponseSerializer.m
//  HTTPNetworkDemo
//
//  Created by DelpanSun on 2020/5/12.
//  Copyright © 2020 DelpanSun. All rights reserved.
//

#import "BusinessResponseSerializer.h"

/**
 *
 * BusinessResponse
 *
 */
@implementation BusinessResponse

@end



/**
 *
 * BusinessResponseSerializerType1
 *
 */
@implementation BusinessResponseSerializerType1

@synthesize serializer = _serializer;

#pragma mark - Public Methods
- (id)serializeWithHTTPResponse:(NSHTTPURLResponse *)httpResponse httpBody:(NSData *)httpBody error:(NSError *__autoreleasing *)error
{
    BusinessResponse *response;
    
    if (_serializer)
    {
        NSDictionary *parameters = [[_serializer serializeWithHTTPResponse:httpResponse httpBody:httpBody error:error] copy];
        response = [self responseWithParameters:parameters];
    }
    
    return response;
}

- (BusinessResponse *)responseWithParameters:(NSDictionary *)parameters
{
    BusinessResponse *response;
    
    if (parameters && parameters[@"data"])
    {
        response = [BusinessResponse new];
        response.data = parameters[@"data"];
        response.status = BusinessResponseStatusSuccess;
        response.message = parameters[@"message"];
    }
    
    return response;
}

@end

/**
 *
 * BusinessResponseSerializerType2
 *
 */
@implementation BusinessResponseSerializerType2

@synthesize serializer = _serializer;

#pragma mark - Public Methods
- (id)serializeWithHTTPResponse:(NSHTTPURLResponse *)httpResponse httpBody:(NSData *)httpBody error:(NSError *__autoreleasing *)error
{
    BusinessResponse *response;
    
    if (_serializer)
    {
        NSDictionary *parameters = [[_serializer serializeWithHTTPResponse:httpResponse httpBody:httpBody error:error] copy];
        response = [self responseWithParameters:parameters];
    }
    
    return response;
}

- (BusinessResponse *)responseWithParameters:(NSDictionary *)parameters
{
    BusinessResponse *response;
    
    if (parameters && parameters[@"result"])
    {
        response = [BusinessResponse new];
        response.data = parameters[@"result"];
        response.status = BusinessResponseStatusSuccess;
        response.message = parameters[@"content"];
    }
    
    return response;
}

@end



/**
 *
 * BusinessResponseComposeSerializer
 *
 */
@implementation BusinessResponseComposeSerializer
{
    @public
    NSArray *_serializers;
}

@synthesize serializer = _serializer;

#pragma mark - Factory
+ (instancetype)composeWithSerializers:(NSArray<id<BusinessResponseSerializer>> *)serializers
{
    BusinessResponseComposeSerializer *compose = [BusinessResponseComposeSerializer new];
    compose->_serializers = [serializers copy];
    return compose;
}

#pragma mark - Public Methods
- (id)serializeWithHTTPResponse:(NSHTTPURLResponse *)httpResponse httpBody:(NSData *)httpBody error:(NSError *__autoreleasing *)error
{
    BusinessResponse *response;
    
    if (_serializer)
    {
        NSDictionary *parameters = [_serializer serializeWithHTTPResponse:httpResponse httpBody:httpBody error:error];
        
        for (id <BusinessResponseSerializer> serializer in _serializers)
        {
            response = [serializer responseWithParameters:parameters];
            
            if (response)
            {
                break;
            }
        }
    }
    
    return response;
}

- (BusinessResponse *)responseWithParameters:(NSDictionary *)parameters
{
    return nil;
}

@end
































