//
//  DSHTTPResponseSerializer.h
//  HTTPNetworkDemo
//
//  Created by DelpanSun on 2020/5/12.
//  Copyright © 2020 DelpanSun. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *
 * DSHTTPResponseSerializer
 *
 */
typedef void (^DSHTTPResponseSerializerCompletion)(id serializeResponse, NSError *serializeError);

@protocol DSHTTPResponseSerializer <NSObject>

/**
 * @brief 创建HTTP响应报文Body解析对象
 *
 * @param httpResponse HTTP响应报文信息
 * @param httpBody HTTP响应Body
 * @param error 解析错误
 *
 * @return HTTP响应报文Body解析对象
 */
- (id)serializeWithHTTPResponse:(NSHTTPURLResponse *)httpResponse
                       httpBody:(NSData *)httpBody
                          error:(NSError *__autoreleasing *)error;

@end



/**
 *
 * DSHTTPResponseJSONSerializer
 *
 */
@interface DSHTTPResponseJSONSerializer : NSObject <DSHTTPResponseSerializer>

/**
 * @brief 创建HTTP响应报文Body JSON解析对象
 *
 * @param readingOptions JSON编码格式
 *
 * @return HTTP响应报文Body JSON解析对象
 */
+ (instancetype)serializerWithReadingOptions:(NSJSONReadingOptions)readingOptions;

@end

































