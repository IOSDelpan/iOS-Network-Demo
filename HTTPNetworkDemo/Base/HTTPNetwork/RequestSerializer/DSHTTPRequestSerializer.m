//
//  DSHTTPRequestSerializer.m
//  HTTPNetworkDemo
//
//  Created by DelpanSun on 2020/5/12.
//  Copyright © 2020 DelpanSun. All rights reserved.
//

#import "DSHTTPRequestSerializer.h"
#import "NSString+DSDemo.h"
#import <pthread.h>

/**
 * @brief HTTP方法
 */
DSHTTPRequestMethod const DSHTTPRequestMethodGET = @"GET";
DSHTTPRequestMethod const DSHTTPRequestMethodPOST = @"POST";
DSHTTPRequestMethod const DSHTTPRequestMethodPUT = @"PUT";
DSHTTPRequestMethod const DSHTTPRequestMethodDELETE = @"DELETE";
DSHTTPRequestMethod const DSHTTPRequestMethodHEAD = @"HEAD";
DSHTTPRequestMethod const DSHTTPRequestMethodPATCH = @"PATCH";

static NSString *const _DSHTTPRequestSerializerErrorDomain = @"com.DSHTTPRequest.error.DSHTTPRequestSerializer";
static const NSUInteger _DSHTTPRequestSerializerErrorCode = 3000;

/**
 *
 * _DSQueryStringPair
 *
 */
@interface _DSQueryStringPair : NSObject

@property (nonatomic, strong) id key;
@property (nonatomic, strong) id value;

@end

@implementation _DSQueryStringPair

- (instancetype)initWithKey:(id)key value:(id)value
{
    if (self = [super init])
    {
        _key = key;
        _value = value;
    }
    
    return self;
}

- (NSString *)encodedString
{
    if (!_value || [_value isEqual:[NSNull null]])
    {
        return [_key description].ds_stringByURLEncode;
    }
    else
    {
        return [NSString stringWithFormat:@"%@=%@", [_key description].ds_stringByURLEncode, [_value description].ds_stringByURLEncode];
    }
}

@end

#pragma mark - URL Encoded
static NSArray *_DSQueryStringPairsFromKeyAndValue(NSString *key, id value)
{
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(compare:)];
    
    if ([value isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *dictionary = value;
        
        for (id nestedKey in [dictionary.allKeys sortedArrayUsingDescriptors:@[ sortDescriptor ]])
        {
            id nestedValue = dictionary[nestedKey];
            
            if (nestedValue)
            {
                [mutableQueryStringComponents addObjectsFromArray:_DSQueryStringPairsFromKeyAndValue((key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey), nestedValue)];
            }
        }
    }
    else if ([value isKindOfClass:[NSArray class]])
    {
        NSArray *array = value;
        
        for (id nestedValue in array)
        {
            [mutableQueryStringComponents addObjectsFromArray:_DSQueryStringPairsFromKeyAndValue([NSString stringWithFormat:@"%@[]", key], nestedValue)];
        }
    }
    else if ([value isKindOfClass:[NSSet class]])
    {
        NSSet *set = value;
        
        for (id obj in [set sortedArrayUsingDescriptors:@[ sortDescriptor ]])
        {
            [mutableQueryStringComponents addObjectsFromArray:_DSQueryStringPairsFromKeyAndValue(key, obj)];
        }
    }
    else
    {
        [mutableQueryStringComponents addObject:[[_DSQueryStringPair alloc] initWithKey:key value:value]];
    }
    
    return mutableQueryStringComponents;
}

static NSArray *_DSQueryStringPairsFromDictionary(id parameters)
{
    return _DSQueryStringPairsFromKeyAndValue(nil, parameters);
}

static NSString *_DSQueryStringFromParameters(id parameters)
{
    NSMutableArray *pairs = [NSMutableArray array];
    
    for (_DSQueryStringPair *pair in _DSQueryStringPairsFromDictionary(parameters))
    {
        [pairs addObject:[pair encodedString]];
    }
    
    return [pairs componentsJoinedByString:@"&"];
}

static NSError *_DSCheckRequest(NSURLRequest *request)
{
    if (!request || (request.URL.absoluteString.length == 0))
    {
        return [NSError errorWithDomain:_DSHTTPRequestSerializerErrorDomain
                                   code:_DSHTTPRequestSerializerErrorCode
                               userInfo:@{ @"error" : @"request error" }];
    }
    
    return nil;
}

/**
 *
 * DSHTTPRequestSerializer
 *
 */
@implementation DSHTTPRequestSerializer
{
    @public
    
    pthread_mutex_t _setLock;
    NSTimeInterval _timeoutInterval;
    NSMutableDictionary *_headers;
    NSMutableDictionary *_parameters;
    NSSet <DSHTTPRequestMethod> *_httpMethodsEncodingParametersInURI;
}

#pragma mark - Factory
+ (instancetype)serializerWithEncodingParametersInURI:(NSSet *)encodingParametersInURI
{
    DSHTTPRequestSerializer *serializer = [DSHTTPRequestSerializer new];
    serializer->_httpMethodsEncodingParametersInURI = encodingParametersInURI;
    return serializer;
}

#pragma mark - Life cycle
- (instancetype)init
{
    if (self = [super init])
    {
        _timeoutInterval = 15;
        pthread_mutex_init(&_setLock, NULL);
        
        _headers = [NSMutableDictionary dictionary];
        _parameters = [NSMutableDictionary dictionary];
        _httpMethodsEncodingParametersInURI = [NSSet setWithObjects:DSHTTPRequestMethodGET, DSHTTPRequestMethodHEAD, DSHTTPRequestMethodDELETE, nil];
    }
    
    return self;
}

- (void)dealloc
{
    pthread_mutex_destroy(&_setLock);
}

#pragma mark - Public Methods
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field
{
    pthread_mutex_lock(&_setLock);
    [_headers setObject:value forKey:field];
    pthread_mutex_unlock(&_setLock);
}

- (void)removeValueForField:(NSString *)field
{
    pthread_mutex_lock(&_setLock);
    [_headers removeObjectForKey:field];
    pthread_mutex_unlock(&_setLock);
}

- (NSString *)valueForHTTPHeaderField:(NSString *)field
{
    pthread_mutex_lock(&_setLock);
    NSString *value = [_headers objectForKey:field];
    pthread_mutex_unlock(&_setLock);
    return value;
}

- (void)setParameter:(NSString *)parameter forKey:(NSString *)key
{
    pthread_mutex_lock(&_setLock);
    [_parameters setObject:parameter forKey:key];
    pthread_mutex_unlock(&_setLock);
}

- (void)removeParameterForKey:(NSString *)key
{
    pthread_mutex_lock(&_setLock);
    [_parameters removeObjectForKey:key];
    pthread_mutex_unlock(&_setLock);
}

- (NSString *)parameterForKey:(NSString *)key
{
    pthread_mutex_lock(&_setLock);
    NSString *parameter = [_parameters objectForKey:key];
    pthread_mutex_unlock(&_setLock);
    return parameter;
}

- (void)requestBySerializingRequest:(NSURLRequest *)request
                         parameters:(NSDictionary *)parameters
                         completion:(DSHTTPRequestSerializerCompletion)completion
{
    if (completion)
    {
        NSError *error = _DSCheckRequest(request);
        
        if (!error)
        {
            NSMutableDictionary *mutableParameters = [parameters mutableCopy];
            NSMutableURLRequest *mutableURLRequest = [request mutableCopy];
            mutableURLRequest.timeoutInterval = self.timeoutInterval;
            
            pthread_mutex_lock(&_setLock);
            
            [_headers enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL *stop) {
                
                [mutableURLRequest setValue:value forHTTPHeaderField:field];
            }];
            
            if (mutableParameters)
            {
                [_parameters enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    
                    [mutableParameters setObject:obj forKey:key];
                }];
            }
            
            pthread_mutex_unlock(&_setLock);
            
            if ([_httpMethodsEncodingParametersInURI containsObject:mutableURLRequest.HTTPMethod])
            {
                NSString *query = _DSQueryStringFromParameters(mutableParameters);
                mutableURLRequest.URL = [NSURL URLWithString:[mutableURLRequest.URL.absoluteString stringByAppendingFormat:mutableURLRequest.URL.query ? @"&%@" : @"?%@", query]];
                completion([mutableURLRequest copy], nil, nil);
            }
            else
            {
                completion([mutableURLRequest copy], [mutableParameters copy], nil);
            }
        }
        else
        {
            completion(request, parameters, error);
        }
    }
}

#pragma mark - Set & Get
- (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval
{
    pthread_mutex_lock(&_setLock);
    _timeoutInterval = timeoutInterval;
    pthread_mutex_unlock(&_setLock);
}

- (NSTimeInterval)timeoutInterval
{
    pthread_mutex_lock(&_setLock);
    NSTimeInterval timeoutInterval = _timeoutInterval;
    pthread_mutex_unlock(&_setLock);
    return timeoutInterval;
}

- (NSDictionary<NSString *, NSString *> *)httpRequestHeaders
{
    pthread_mutex_lock(&_setLock);
    NSDictionary *headers = [_headers copy];
    pthread_mutex_unlock(&_setLock);
    return headers;
}

- (NSDictionary *)parameters
{
    pthread_mutex_lock(&_setLock);
    NSDictionary *parameters = [_parameters copy];
    pthread_mutex_unlock(&_setLock);
    return parameters;
}

@end



/**
*
* DSHTTPRequestBodyURLEncodeSerializer
*
*/
@implementation DSHTTPRequestBodyURLEncodeSerializer
{
    @public
    NSStringEncoding _stringEncoding;
}

@synthesize serializer = _serializer;

#pragma mark - Factory
+ (instancetype)serializerWithStringEncoding:(NSStringEncoding)stringEncoding
{
    DSHTTPRequestBodyURLEncodeSerializer *serializer = [DSHTTPRequestBodyURLEncodeSerializer new];
    serializer->_stringEncoding = stringEncoding;
    return serializer;
}

#pragma mark - Life cycle
- (instancetype)init
{
    if (self = [super init])
    {
        _stringEncoding = NSUTF8StringEncoding;
    }
    
    return self;
}

#pragma mark - Public Methods
- (void)requestBySerializingRequest:(NSURLRequest *)request
                         parameters:(NSDictionary *)parameters
                         completion:(DSHTTPRequestSerializerCompletion)completion
{
    if (completion)
    {
        NSError *error = _DSCheckRequest(request);
        
        if (!error)
        {
            if (_serializer)
            {
                [_serializer requestBySerializingRequest:request parameters:parameters completion:^(NSURLRequest *completeRequest, NSDictionary *completeParameters, NSError *completeError) {
                    
                    if (!completeError)
                    {
                        [self _requestBySerializingRequest:completeRequest parameters:completeParameters completion:completion];
                    }
                }];
            }
            else
            {
                [self _requestBySerializingRequest:request parameters:parameters completion:completion];
            }
        }
        else
        {
            completion(request, parameters, error);
        }
    }
}

#pragma mark - Private Methods
- (void)_requestBySerializingRequest:(NSURLRequest *)request
                          parameters:(NSDictionary *)parameters
                          completion:(DSHTTPRequestSerializerCompletion)completion
{
    NSMutableURLRequest *mutableURLRequest = [request mutableCopy];
    NSMutableDictionary *mutableParameters = [parameters mutableCopy];
    
    if (mutableParameters)
    {
        NSString *query = _DSQueryStringFromParameters(mutableParameters);
        [mutableURLRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        mutableURLRequest.HTTPBody = [query dataUsingEncoding:_stringEncoding];
    }
    
    completion([mutableURLRequest copy], [mutableParameters copy], nil);
}

#pragma mark - Set & Get
- (void)setSerializer:(id<DSHTTPRequestSerializer>)serializer
{
    _serializer = serializer;
}

- (id <DSHTTPRequestSerializer>)serializer
{
    return _serializer;
}

@end



/**
*
* DSHTTPRequestBodyJSONSerializer
*
*/
@implementation DSHTTPRequestBodyJSONSerializer
{
    @public
    NSJSONWritingOptions _writingOptions;
}

@synthesize serializer = _serializer;

#pragma mark - Factory
+ (instancetype)serializerWithWritingOptions:(NSJSONWritingOptions)writingOptions
{
    DSHTTPRequestBodyJSONSerializer *serializer = [DSHTTPRequestBodyJSONSerializer new];
    serializer->_writingOptions = writingOptions;
    return serializer;
}

#pragma mark - Life cycle
- (instancetype)init
{
    if (self = [super init])
    {
        _writingOptions = NSJSONWritingPrettyPrinted;
    }
    
    return self;
}

#pragma mark - Public Methods
- (void)requestBySerializingRequest:(NSURLRequest *)request
                         parameters:(NSDictionary *)parameters
                         completion:(DSHTTPRequestSerializerCompletion)completion
{
    if (completion)
    {
        NSError *error = _DSCheckRequest(request);
        
        if (!error)
        {
            if (_serializer)
            {
                [_serializer requestBySerializingRequest:request parameters:parameters completion:^(NSURLRequest *completeRequest, NSDictionary *completeParameters, NSError *completeError) {
                    
                    if (!completeError)
                    {
                        [self _requestBySerializingRequest:completeRequest parameters:completeParameters completion:completion];
                    }
                }];
            }
            else
            {
                [self _requestBySerializingRequest:request parameters:parameters completion:completion];
            }
        }
        else
        {
            completion(request, parameters, error);
        }
    }
}

#pragma mark - Private Methods
- (void)_requestBySerializingRequest:(NSURLRequest *)request
                          parameters:(NSDictionary *)parameters
                          completion:(DSHTTPRequestSerializerCompletion)completion
{
    NSMutableURLRequest *mutableURLRequest = [request mutableCopy];
    NSMutableDictionary *mutableParameters = [parameters mutableCopy];
    
    if (mutableParameters)
    {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:mutableParameters
                                                           options:_writingOptions
                                                             error:&error];
        
        if (!error)
        {
            [mutableURLRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            mutableURLRequest.HTTPBody = jsonData;
        }
    }
    
    completion([mutableURLRequest copy], [mutableParameters copy], nil);
}

#pragma mark - Set & Get
- (void)setSerializer:(id<DSHTTPRequestSerializer>)serializer
{
    _serializer = serializer;
}

- (id <DSHTTPRequestSerializer>)serializer
{
    return _serializer;
}

@end



































