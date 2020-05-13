//
//  BusinessNetwork.h
//  HTTPNetworkDemo
//
//  Created by DelpanSun on 2020/5/12.
//  Copyright © 2020 DelpanSun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BusinessResponseSerializer.h"

@interface BusinessNetwork : NSObject

/**
 * @brief POST交互
 *
 * @param urlString HTTP URL String
 * @param parameters 请求参数
 * @param json 是否JSON序列化方式
 * @param completion HTTP交互完成回调
 */
+ (void)postWithURLString:(NSString *)urlString
               parameters:(NSDictionary *)parameters
                     json:(BOOL)json
               completion:(void (^)(NSURLRequest *request, BusinessResponse *response, NSError *error))completion;

@end





















































