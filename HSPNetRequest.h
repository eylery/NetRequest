//
//  HSPNetRequest.h
//  HSPayDemo
//
//  Created by chenwy on 17/8/10.
//  Copyright © 2017年 lincenTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^HSPCompletioBlock)(NSDictionary *responseObject, NSURLResponse *response, NSError *error);
typedef void (^HSPSuccessBlock)(NSDictionary *responseObject);
typedef void (^HSPFailureBlock)(NSError *error);

@interface HSPNetRequest : NSObject

+ (instancetype)shareInstance;

/**
 *  get请求
 */
- (void)getWithUrlString:(NSString *)url parameters:(NSDictionary *)parameters success:(HSPSuccessBlock)successBlock failure:(HSPFailureBlock)failureBlock;

/**
 * post请求
 */
- (void)postWithUrlString:(NSString *)url parameters:(NSDictionary *)parameters success:(HSPSuccessBlock)successBlock failure:(HSPFailureBlock)failureBlock;

@end
