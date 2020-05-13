//
//  DSHTTPRequestSerializer.h
//  HTTPNetworkDemo
//
//  Created by DelpanSun on 2020/5/12.
//  Copyright © 2020 DelpanSun. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * @brief HTTP方法
 */
typedef NSString *DSHTTPRequestMethod;
extern DSHTTPRequestMethod const DSHTTPRequestMethodGET;
extern DSHTTPRequestMethod const DSHTTPRequestMethodPOST;
extern DSHTTPRequestMethod const DSHTTPRequestMethodPUT;
extern DSHTTPRequestMethod const DSHTTPRequestMethodDELETE;
extern DSHTTPRequestMethod const DSHTTPRequestMethodHEAD;
extern DSHTTPRequestMethod const DSHTTPRequestMethodPATCH;

/**
 *
 * DSHTTPRequestSerializer
 *
 */
typedef void (^DSHTTPRequestSerializerCompletion)(NSURLRequest *completeRequest, NSDictionary *completeParameters, NSError *completeError);

@protocol DSHTTPRequestSerializer <NSObject>

/**
 * @brief 序列化HTTP Request
 *
 * @param request 原始Request
 * @param parameters HTTP报文参数
 * @param completion 处理完成回调
 */
- (void)requestBySerializingRequest:(NSURLRequest *)request
                         parameters:(NSDictionary *)parameters
                         completion:(DSHTTPRequestSerializerCompletion)completion;

@end



/**
 *
 * DSHTTPRequestSerializer
 *
 */
@interface DSHTTPRequestSerializer : NSObject <DSHTTPRequestSerializer>

+ (instancetype)serializerWithEncodingParametersInURI:(NSSet *)encodingParametersInURI;

/**
 * @brief 请求超时时间
 */
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

/**
 * @brief HTTP报文头字端
 */
@property (readonly, nonatomic) NSDictionary<NSString *, NSString *> *httpRequestHeaders;

/**
 * @brief 公共参数
 */
@property (nonatomic, readonly) NSDictionary *parameters;

/**
 * @brief HTTP参数编码方法
 */
@property (nonatomic, strong) NSSet <DSHTTPRequestMethod> *httpMethodsEncodingParametersInURI;

/**
 * @brief 设置HTTP报文头公共字段
 *
 * @param value HTTP报文头字段值
 * @param field HTTP报文头字段Key
 */
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

/**
 * @brief 移除HTTP报文头信息
 *
 * @param field HTTP报文头字段Key
 */
- (void)removeValueForField:(NSString *)field;

/**
 * @brief 获取HTTP报文头信息
 *
 * @param field HTTP报文头字段Key
 *
 * @return HTTP报文头字段值
 */
- (NSString *)valueForHTTPHeaderField:(NSString *)field;

/**
 * @brief 添加公共参数
 *
 * @param parameter 参数
 * @param key 参数Key
 */
- (void)setParameter:(NSString *)parameter forKey:(NSString *)key;

/**
 * @brief 移除公共参数
 *
 * @param key 参数Key
 */
- (void)removeParameterForKey:(NSString *)key;

/**
 * @brief 获取公共参数
 *
 * @param key 参数Key
 *
 * @return 参数
 */
- (NSString *)parameterForKey:(NSString *)key;

@end



/**
 *
 * DSHTTPRequestBodySerializer
 *
 */
@protocol DSHTTPRequestBodySerializer <DSHTTPRequestSerializer>

@property (nonatomic, strong) id <DSHTTPRequestSerializer> serializer;

@end



/**
 *
 * DSHTTPRequestBodyURLEncodeSerializer
 *
 */
@interface DSHTTPRequestBodyURLEncodeSerializer : NSObject <DSHTTPRequestBodySerializer>

/**
 * @brief 创建HTTP URLEncode序列化对象
 *
 * @param stringEncoding URLEncode编码格式
 *
 * @return HTTP URLEncode序列化对象
 */
+ (instancetype)serializerWithStringEncoding:(NSStringEncoding)stringEncoding;

@end



/**
 *
 * DSHTTPRequestBodyJSONSerializer
 *
 */
@interface DSHTTPRequestBodyJSONSerializer : NSObject <DSHTTPRequestBodySerializer>

/**
 * @brief 创建HTTP JSON序列化对象
 *
 * @param writingOptions JSON编码格式
 *
 * @return HTTP JSON序列化对象
 */
+ (instancetype)serializerWithWritingOptions:(NSJSONWritingOptions)writingOptions;

@end

























