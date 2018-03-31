//
//  HSPNetRequest.m
//  HSPayDemo
//
//  Created by chenwy on 17/8/10.
//  Copyright © 2017年 lincenTech. All rights reserved.
//

#import "HSPNetRequest.h"

@implementation HSPNetRequest

+ (instancetype)shareInstance
{
    static HSPNetRequest *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[HSPNetRequest alloc] init];
    });
    return manager;
}

// 处理字典参数
- (NSString *)dealWithParam:(NSDictionary *)param encoded:(BOOL)bEncoded
{
    NSArray* sortedKeyArray = [[param allKeys] sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    NSMutableArray *tmpArray = [NSMutableArray new];
    for (NSString* key in sortedKeyArray) {
        NSString* orderItem = [self orderItemWithKey:key andValue:[param objectForKey:key] encoded:bEncoded];
        if (orderItem.length > 0) {
            [tmpArray addObject:orderItem];
        }
    }
    return [tmpArray componentsJoinedByString:@"&"];
    
//    NSArray *allkeys = [param allKeys];
//    
//    NSMutableString *result = [NSMutableString string];
//    
//    for (NSString *key in allkeys) {
//        
//        NSString *str = [NSString stringWithFormat:@"%@=%@&",key,param[key]];
//        
//        [result appendString:str];
//    }
//    
//    return [result substringWithRange:NSMakeRange(0, result.length-1)];
    
}

- (NSString*)orderItemWithKey:(NSString*)key andValue:(NSString*)value encoded:(BOOL)bEncoded
{
    if (key.length > 0 && value.length > 0) {
        if (bEncoded) {
            value = [self encodeValue:value];
        }
        return [NSString stringWithFormat:@"%@=%@", key, value];
    }
    return nil;
}

- (NSString*)encodeValue:(NSString*)value
{
    NSString* encodedValue = value;
    if (value.length > 0) {
        encodedValue = (__bridge_transfer  NSString*)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)value, NULL, (__bridge CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 );
    }
    return encodedValue;
}

//GET请求
- (void)getWithUrlString:(NSString *)url parameters:(NSDictionary *)parameters success:(HSPSuccessBlock)successBlock failure:(HSPFailureBlock)failureBlock
{
    NSParameterAssert(url);
    NSString *urlEnCode = url;
    if (parameters && parameters.count > 0) {
        urlEnCode = [NSString stringWithFormat:@"%@?%@",url,[self dealWithParam:parameters encoded:YES]];
    }
    NSLog(@">>>>>>>%@",[NSString stringWithFormat:@"%@?%@",url,[self dealWithParam:parameters encoded:NO]]);
    NSURL *reqUrl = [NSURL URLWithString:urlEnCode];
    NSParameterAssert(reqUrl);
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:reqUrl cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15];
    urlRequest.HTTPMethod = @"GET";
    NSURLSession *urlSession = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [urlSession dataTaskWithRequest:urlRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@",error);
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
            
        } else {
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            NSLog(@"%@",[self changeToString:dic]);
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(dic);
            });
            
        }
    }];
    [dataTask resume];
}

//POST请求 使用NSMutableURLRequest可以加入请求头
- (void)postWithUrlString:(NSString *)url parameters:(NSDictionary *)parameters success:(HSPSuccessBlock)successBlock failure:(HSPFailureBlock)failureBlock
{
//    NSURL *nsurl = [NSURL URLWithString:url];
//    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:nsurl];
    //如果想要设置网络超时的时间的话，可以使用下面的方法：
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15];
    
    //设置请求类型
    request.HTTPMethod = @"POST";
    // 设置本次请求的提交数据格式
//    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    if (parameters && parameters.count > 0) {
        NSString *body = [self dealWithParam:parameters encoded:YES];
        NSData *bodyData = [body dataUsingEncoding:NSUTF8StringEncoding];
        
        // 设置请求体
        [request setHTTPBody:bodyData];
        // 设置本次请求请求体的长度(因为服务器会根据你这个设定的长度去解析你的请求体中的参数内容)
//        [request setValue:[NSString stringWithFormat:@"%ld",bodyData.length] forHTTPHeaderField:@"Content-Length"];
    }
    
    
    
    NSLog(@">>>>>>>%@",[NSString stringWithFormat:@"%@\nhttpBody:%@",url,[self changeToString:parameters]]);
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {//请求失败
            NSLog(@"%@",error);
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
            
        } else {//请求成功
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            NSLog(@"%@",[self changeToString:dic]);
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(dic);
            });
            
        }
    }];
    [dataTask resume];  //开始请求
}

//重新封装参数 加入app相关信息
//+ (NSString *)parseParams:(NSDictionary *)params
//{
//    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithDictionary:params];
//    [parameters setValue:@"ios" forKey:@"client"];
//    [parameters setValue:@"请替换版本号" forKey:@"auth_version"];
//    NSString* phoneModel = @"获取手机型号" ;
//    NSString* phoneVersion = [[UIDevice currentDevice] systemVersion];//ios系统版本号
//    NSString *system = [NSString stringWithFormat:@"%@(%@)",phoneModel, phoneVersion];
//    [parameters setValue:system forKey:@"system"];
//    NSDate *date = [NSDate date];
//    NSTimeInterval timeinterval = [date timeIntervalSince1970];
//    [parameters setObject:[NSString stringWithFormat:@"%.0lf",timeinterval] forKey:@"auth_timestamp"];//请求时间戳
//    NSString *devicetoken = @"请替换DeviceToken";
//    [parameters setValue:devicetoken forKey:@"uuid"];
//    NSLog(@"请求参数:%@",parameters);
//    
//    NSString *keyValueFormat;
//    NSMutableString *result = [NSMutableString new];
//    //实例化一个key枚举器用来存放dictionary的key
//    
//    //加密处理 将所有参数加密后结果当做参数传递
//    //parameters = @{@"i":@"加密结果 抽空加入"};
//    
//    NSEnumerator *keyEnum = [parameters keyEnumerator];
//    id key;
//    while (key = [keyEnum nextObject]) {
//        keyValueFormat = [NSString stringWithFormat:@"%@=%@&", key, [params valueForKey:key]];
//        [result appendString:keyValueFormat];
//    }
//    return result;
//}

//输出显示中文
- (NSString *)changeToString:(id)responseObject {
//    NSString* responseFixedStr = [NSString stringWithCString:[[responseObject description] cStringUsingEncoding:NSUTF8StringEncoding] encoding:NSNonLossyASCIIStringEncoding];
//    if (!responseFixedStr) {
//        responseFixedStr = [responseObject description];
//    }
//    return responseFixedStr;
    
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:responseObject options:NSJSONWritingPrettyPrinted error:nil];
    NSString* jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    if (!jsonStr) {
        jsonStr = [responseObject description];
    }
    return jsonStr;
}

@end
