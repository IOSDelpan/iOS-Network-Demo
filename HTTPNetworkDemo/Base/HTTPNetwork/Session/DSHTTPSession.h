//
//  DSHTTPSession.h
//  HTTPNetworkDemo
//
//  Created by DelpanSun on 2020/5/12.
//  Copyright © 2020 DelpanSun. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DSHTTPSessionHandler;

/**
 *
 * DSHTTPSession
 *
 */
@interface DSHTTPSession : NSObject

+ (instancetype)session;

/**
 * @brief 开始HTTP交互
 *
 * @param request HTTP请求
 * @param handler HTTP交互过程处理
 */
- (void)taskWithRequest:(NSURLRequest *)request
                handler:(id <DSHTTPSessionHandler>)handler;

@end



/**
 *
 * DSHTTPSessionHandler
 *
 */
@protocol DSHTTPSessionHandler <NSObject>

@optional
/**
 * @brief HTTP响应报文
 *
 * @param session 当前HTTP会话
 * @param httpResponse HTTP响应报文
 *
 * @return 是否接收HTTP Body
 */
- (BOOL)httpSession:(DSHTTPSession *)session didReceiveHTTPResponse:(NSHTTPURLResponse *)httpResponse;

/**
 * @brief 接收HTTP Body数据
 *
 * @param session 当前HTTP会话
 * @param data HTTP Body数据
 */
- (void)httpSession:(DSHTTPSession *)session didReceiveData:(NSData *)data;

/**
 * @brief HTTP交互完成
 *
 * @param session 当前HTTP会话
 * @param httpResponse HTTP响应报文
 * @param error 完成错误
 */
- (void)httpSession:(DSHTTPSession *)session httpResponse:(NSHTTPURLResponse *)httpResponse didCompleteWithError:(NSError *)error;

@end
















