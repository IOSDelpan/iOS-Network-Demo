//
//  BusinessResponseSerializer.h
//  HTTPNetworkDemo
//
//  Created by DelpanSun on 2020/5/12.
//  Copyright © 2020 DelpanSun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DSHTTPResponseSerializer.h"

typedef NS_ENUM(u_int8_t, BusinessResponseStatus)
{
    BusinessResponseStatusSuccess = 0,
    BusinessResponseStatusError = 1
};

/**
 *
 * BusinessResponse
 *
 */
@interface BusinessResponse : NSObject

/**
 * @brief 数据
 */
@property (nonatomic, copy) NSDictionary *data;

/**
 * @brief 状态
 */
@property (nonatomic, assign) BusinessResponseStatus status;

/**
 * @brief 信息
 */
@property (nonatomic, copy) NSString *message;

@end



/**
 *
 * BusinessResponseSerializer
 *
 */
@protocol BusinessResponseSerializer <DSHTTPResponseSerializer>

@property (nonatomic, strong) id <DSHTTPResponseSerializer> serializer;

- (BusinessResponse *)responseWithParameters:(NSDictionary *)parameters;

@end



/**
 *
 * BusinessResponseSerializerType1
 *
 */
@interface BusinessResponseSerializerType1 : NSObject <BusinessResponseSerializer>

@end



/**
 *
 * BusinessResponseSerializerType2
 *
 */
@interface BusinessResponseSerializerType2 : NSObject <BusinessResponseSerializer>

@end



/**
 *
 * BusinessResponseComposeSerializer
 *
 */
@interface BusinessResponseComposeSerializer : NSObject <BusinessResponseSerializer>

+ (instancetype)composeWithSerializers:(NSArray<id <BusinessResponseSerializer>> *)serializers;

@end



















































