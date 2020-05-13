//
//  BusinessNetwork.m
//  HTTPNetworkDemo
//
//  Created by DelpanSun on 2020/5/12.
//  Copyright © 2020 DelpanSun. All rights reserved.
//

#import "BusinessNetwork.h"
#import "DSHTTPOperation.h"
#import <objc/runtime.h>

@implementation BusinessNetwork

#pragma mark - Public Methods
+ (void)postWithURLString:(NSString *)urlString
               parameters:(NSDictionary *)parameters
                     json:(BOOL)json
               completion:(void (^)(NSURLRequest *request, BusinessResponse *response, NSError *error))completion
{
    DSHTTPOperation *operation = [self.httpManager operationWithURLString:urlString method:DSHTTPRequestMethodPOST parameters:parameters completion:completion];
    
    if (!json)
    {
        operation.requestSerializer = self.urlEncodeRequestSerializer;
    }
    
    [self.httpManager addOperation:operation];
}

#pragma mark - Get
+ (DSHTTPOperationManager *)httpManager
{
    DSHTTPOperationManager *manager = objc_getAssociatedObject(self, @selector(httpManager));
    
    if (!manager)
    {
        // RequestSerializer
        DSHTTPRequestBodyJSONSerializer *jsonSerializer = [DSHTTPRequestBodyJSONSerializer new];
        jsonSerializer.serializer = [DSHTTPRequestSerializer new];
        
        // responseSerializer
        BusinessResponseComposeSerializer *responseComposeSerializer = [BusinessResponseComposeSerializer composeWithSerializers:@[ [BusinessResponseSerializerType1 new], [BusinessResponseSerializerType2 new] ]];
        responseComposeSerializer.serializer = [DSHTTPResponseJSONSerializer new];
        
        manager = [DSHTTPOperationManager managerWithHTTPSession:[DSHTTPSession session]
                                               requestSerializer:jsonSerializer
                                              responseSerializer:responseComposeSerializer
                                                 completionQueue:dispatch_get_main_queue()];
        objc_setAssociatedObject(self, @selector(httpManager), manager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return manager;
}

+ (id <DSHTTPRequestSerializer>)requestSerializer
{
    DSHTTPRequestSerializer *requestSerializer = objc_getAssociatedObject(self, @selector(requestSerializer));
    
    if (!requestSerializer)
    {
        requestSerializer = [DSHTTPRequestSerializer new];
        objc_setAssociatedObject(self, @selector(requestSerializer), requestSerializer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return requestSerializer;
}

+ (id <DSHTTPRequestSerializer>)urlEncodeRequestSerializer
{
    DSHTTPRequestBodyURLEncodeSerializer *urlEncodeRequestSerializer = objc_getAssociatedObject(self, @selector(urlEncodeRequestSerializer));
    
    if (!urlEncodeRequestSerializer)
    {
        urlEncodeRequestSerializer = [DSHTTPRequestBodyURLEncodeSerializer new];
        urlEncodeRequestSerializer.serializer = self.requestSerializer;
        objc_setAssociatedObject(self, @selector(urlEncodeRequestSerializer), urlEncodeRequestSerializer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return urlEncodeRequestSerializer;
}

@end

























































