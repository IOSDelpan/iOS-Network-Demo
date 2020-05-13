//
//  BusinessNetwork+DSDemo.m
//  HTTPNetworkDemo
//
//  Created by DelpanSun on 2020/5/12.
//  Copyright © 2020 DelpanSun. All rights reserved.
//

#import "BusinessNetwork+DSDemo.h"

@implementation BusinessNetwork (DSDemo)

+ (void)type1WithParameters:(NSDictionary *)parameters completion:(void (^)(NSURLRequest *request, BusinessResponse *response, NSError *error))completion
{
    [self postWithURLString:@"Type1" parameters:parameters json:YES completion:completion];
}

+ (void)type2WithParameters:(NSDictionary *)parameters completion:(void (^)(NSURLRequest *request, BusinessResponse *response, NSError *error))completion
{
    [self postWithURLString:@"Type2" parameters:parameters json:YES completion:completion];
}

@end
