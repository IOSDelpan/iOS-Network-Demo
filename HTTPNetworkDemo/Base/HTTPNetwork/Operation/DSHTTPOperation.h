//
//  DSHTTPOperation.h
//  HTTPNetworkDemo
//
//  Created by DelpanSun on 2020/5/12.
//  Copyright © 2020 DelpanSun. All rights reserved
//

#import "DSOperation.h"
#import "DSHTTPRequestSerializer.h"
#import "DSHTTPResponseSerializer.h"
#import "DSHTTPSession.h"

/**
 * @brief HTTP交互完成回调
 */
typedef void (^DSHTTPCompletion)(NSURLRequest *request, id responseData, NSError *error);

/**
 *
 * DSHTTPOperation
 *
 */
@interface DSHTTPOperation : DSOperation

/**
 * @brief HTTP请求序列化
 */
@property (nonatomic, strong) id <DSHTTPRequestSerializer> requestSerializer;

/**
 * @brief HTTP响应序列化
 */
@property (nonatomic, strong) id <DSHTTPResponseSerializer> responseSerializer;

/**
 * @brief HTTP交互
 */
@property (nonatomic, strong) DSHTTPSession *httpSession;

/**
 * @brief HTTP原始Reqeust
 */
@property (nonatomic, copy) NSURLRequest *request;

/**
 * @brief 请求参数
 */
@property (nonatomic, copy) NSDictionary *parameters;

/**
 * @brief 超时重试次数
 */
@property (nonatomic, assign) NSUInteger timeoutCount;

/**
 * @brief 回调队列
 */
@property (nonatomic) dispatch_queue_t completionQueue;

/**
 * @brief HTTP交互完成回调
 */
@property (nonatomic, copy) DSHTTPCompletion httpCompletion;

@end



/**
 *
 * DSHTTPOperationManager
 *
 */
@interface DSHTTPOperationManager : NSObject

+ (instancetype)sharedManager;

/**
 * @brief 创建HTTP管理
 *
 * @param httpSession HTTP交互
 * @param requestSerializer HTTP请求序列化
 * @param responseSerializer HTTP响应序列化
 * @param completionQueue 回调队列
 *
 * @return HTTP管理
 */
+ (instancetype)managerWithHTTPSession:(DSHTTPSession *)httpSession
                     requestSerializer:(id <DSHTTPRequestSerializer>)requestSerializer
                    responseSerializer:(id <DSHTTPResponseSerializer>)responseSerializer
                       completionQueue:(dispatch_queue_t)completionQueue;

/**
 * @brief HTTP交互
 */
@property (strong) DSHTTPSession *httpSession;

/**
 * @brief HTTP请求序列化
 */
@property (strong) id <DSHTTPRequestSerializer> requestSerializer;

/**
 * @brief HTTP响应序列化
 */
@property (strong) id <DSHTTPResponseSerializer> responseSerializer;

/**
 * @brief 回调队列
 */
@property (nonatomic) dispatch_queue_t completionQueue;

/**
 * @brief HTTP Operation的最大并发数
 */
@property (assign) NSUInteger maxConcurrentOperationCount;

/**
 * @brief 根URL
 */
@property (copy) NSURL *baseURL;

/**
 * @brief 创建HTTP交互操作
 *
 * @param urlString HTTP URL String
 * @param method HTTP交互方法
 * @param parameters 请求参数
 * @param completion HTTP交互完成回调
 *
 * @return HTTP交互操作
 */
- (DSHTTPOperation *)operationWithURLString:(NSString *)urlString
                                     method:(DSHTTPRequestMethod)method
                                 parameters:(NSDictionary *)parameters
                                 completion:(DSHTTPCompletion)completion;

/**
 * @brief 创建HTTP交互操作
 *
 * @param request 原始Request
 * @param parameters 请求参数
 * @param completion HTTP交互完成回调
 *
 * @return HTTP交互操作
 */
- (DSHTTPOperation *)operationWithRequest:(NSURLRequest *)request
                               parameters:(NSDictionary *)parameters
                               completion:(DSHTTPCompletion)completion;

/**
 * @brief 创建并启动HTTP交互操作
 *
 * @param urlString HTTP URL String
 * @param method HTTP交互方法
 * @param parameters 请求参数
 * @param completion HTTP交互完成回调
 *
 * @return HTTP交互操作
 */
- (DSHTTPOperation *)scheduledWithURLString:(NSString *)urlString
                                     method:(DSHTTPRequestMethod)method
                                 parameters:(NSDictionary *)parameters
                                 completion:(DSHTTPCompletion)completion;

/**
 * @brief 创建并启动HTTP交互操作
 *
 * @param request 原始Request
 * @param parameters 请求参数
 * @param completion HTTP交互完成回调
 *
 * @return HTTP交互操作
 */
- (DSHTTPOperation *)scheduledWithRequest:(NSURLRequest *)request
                               parameters:(NSDictionary *)parameters
                               completion:(DSHTTPCompletion)completion;

/**
 * @brief 添加HTTP交互操作
 *
 * @param operation HTTP交互操作
 */
- (void)addOperation:(DSHTTPOperation *)operation;

@end














































