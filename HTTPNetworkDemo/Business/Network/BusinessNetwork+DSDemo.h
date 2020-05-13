//
//  BusinessNetwork+DSDemo.h
//  HTTPNetworkDemo
//
//  Created by DelpanSun on 2020/5/12.
//  Copyright © 2020 DelpanSun. All rights reserved.
//

#import "BusinessNetwork.h"

@interface BusinessNetwork (DSDemo)

+ (void)type1WithParameters:(NSDictionary *)parameters completion:(void (^)(NSURLRequest *request, BusinessResponse *response, NSError *error))completion;
+ (void)type2WithParameters:(NSDictionary *)parameters completion:(void (^)(NSURLRequest *request, BusinessResponse *response, NSError *error))completion;

@end

