//
//  DSHTTPOperation.m
//  HTTPNetworkDemo
//
//  Created by DelpanSun on 2020/5/12.
//  Copyright © 2020 DelpanSun. All rights reserved
//

#import "DSHTTPOperation.h"
#import "DSHTTPSession.h"
#import <pthread.h>

/**
 *
 * DSHTTPOperation
 *
 */
@interface DSHTTPOperation () <DSHTTPSessionHandler>

@end

@implementation DSHTTPOperation
{
    NSMutableData *_receiveData;
}

#pragma mark - Life cycle
- (instancetype)init
{
    if (self = [super init])
    {
        _receiveData = [NSMutableData data];
    }
    
    return self;
}

#pragma mark - Override Methods
- (void)start
{
    @autoreleasepool
    {
        [self stateLockContext:^DSOperationState(DSOperationState state) {
            
            __block DSOperationState currentState = state;
            
            if (currentState == DSOperationStateReady)
            {
                if (_requestSerializer)
                {
                    [_requestSerializer requestBySerializingRequest:_request parameters:_parameters completion:^(NSURLRequest *completeRequest, NSDictionary *completeParameters, NSError *completeError) {
                        
                        if (completeError)
                        {
                            currentState = DSOperationStateCompleted;
                            [self _completionWithError:completeError];
                        }
                        else
                        {
                            currentState = DSOperationStateExecuting;
                            [self _startRequest:[completeRequest copy]];
                        }
                    }];
                }
                else
                {
                    currentState = DSOperationStateExecuting;
                    [self _startRequest:_request];
                }
            }
            
            return currentState;
        }];
    }
}

#pragma mark - Private Methods
- (void)_startRequest:(NSURLRequest *)request
{
    [_httpSession taskWithRequest:request handler:self];
}

- (void)_completionWithError:(NSError *)error
{
    if (error)
    {
        !_httpCompletion ?: _httpCompletion(_request, nil, error);
    }
    else
    {
        id response;
        __block NSError *completeError;
        
        if (_responseSerializer)
        {
            response = [_responseSerializer serializeWithHTTPResponse:nil httpBody:[_receiveData copy] error:&completeError];
        }
        
        !_httpCompletion ?: _httpCompletion(_request, response, completeError);
    }
}

#pragma mark - Delegate
- (BOOL)httpSession:(DSHTTPSession *)session didReceiveHTTPResponse:(NSHTTPURLResponse *)httpResponse
{
    return YES;
}

- (void)httpSession:(DSHTTPSession *)session didReceiveData:(NSData *)data
{
    [_receiveData appendData:data];
}

- (void)httpSession:(DSHTTPSession *)session httpResponse:(NSHTTPURLResponse *)httpResponse didCompleteWithError:(NSError *)error
{
    [self _completionWithError:error];
}

@end



/**
 *
 * DSHTTPOperationManager
 *
 */
@implementation DSHTTPOperationManager
{
@public
    DSOperationQueue *_operationQueue;
    
    DSHTTPSession *_httpSession;
    id <DSHTTPRequestSerializer> _requestSerializer;
    id <DSHTTPResponseSerializer> _responseSerializer;
    dispatch_queue_t _completionQueue;
    
    NSURL *_baseURL;
    
    pthread_mutex_t _configurationLock;
    pthread_mutex_t _baseURLLock;
}

#pragma mark - Singleton
+ (instancetype)sharedManager
{
    static DSHTTPOperationManager *operationManager;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        operationManager = [DSHTTPOperationManager managerWithHTTPSession:nil
                                                        requestSerializer:nil
                                                       responseSerializer:nil
                                                          completionQueue:nil];
    });
    
    return operationManager;
}

#pragma mark - Factory
+ (instancetype)managerWithHTTPSession:(DSHTTPSession *)httpSession
                     requestSerializer:(id <DSHTTPRequestSerializer>)requestSerializer
                    responseSerializer:(id <DSHTTPResponseSerializer>)responseSerializer
                       completionQueue:(dispatch_queue_t)completionQueue
{
    httpSession = httpSession ? httpSession : [DSHTTPSession session];
    
    if (!requestSerializer)
    {
        DSHTTPRequestBodyJSONSerializer *bodySerializer = [DSHTTPRequestBodyJSONSerializer new];
        bodySerializer.serializer = [DSHTTPRequestSerializer new];
        requestSerializer = bodySerializer;
    }
    
    if (!responseSerializer)
    {
        responseSerializer = [DSHTTPResponseJSONSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
    }
    
    completionQueue = completionQueue ? completionQueue : dispatch_get_main_queue();
    
    return [[self alloc] initWithHTTPSession:httpSession
                           requestSerializer:requestSerializer
                          responseSerializer:responseSerializer
                             completionQueue:completionQueue];
}

#pragma mark - Life cycle
- (instancetype)init
{
    return [self initWithHTTPSession:[DSHTTPSession session]
                   requestSerializer:nil
                  responseSerializer:nil
                     completionQueue:nil];
}

- (instancetype)initWithHTTPSession:(DSHTTPSession *)httpSession
                  requestSerializer:(id <DSHTTPRequestSerializer>)requestSerializer
                 responseSerializer:(id <DSHTTPResponseSerializer>)responseSerializer
                    completionQueue:(dispatch_queue_t)completionQueue
{
    if (self = [super init])
    {
        _operationQueue = [DSOperationQueue operationQueueWithQueue:dispatch_get_global_queue(0, 0)];
        _httpSession = httpSession;
        _requestSerializer = requestSerializer;
        _responseSerializer = responseSerializer;
        _completionQueue = completionQueue;
        
        pthread_mutex_init(&_configurationLock, NULL);
        pthread_mutex_init(&_baseURLLock, NULL);
    }
    
    return self;
}

- (void)dealloc
{
    pthread_mutex_destroy(&_configurationLock);
    pthread_mutex_destroy(&_baseURLLock);
}

#pragma mark - Public Methods
#pragma mark -创建HTTP交互操作
- (DSHTTPOperation *)operationWithURLString:(NSString *)urlString
                                     method:(DSHTTPRequestMethod)method
                                 parameters:(NSDictionary *)parameters
                                 completion:(DSHTTPCompletion)completion
{
    NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString relativeToURL:self.baseURL]];
    mutableRequest.HTTPMethod = method;
    return [self operationWithRequest:mutableRequest parameters:parameters completion:completion];
}

- (DSHTTPOperation *)operationWithRequest:(NSURLRequest *)request
                               parameters:(NSDictionary *)parameters
                               completion:(DSHTTPCompletion)completion
{
    DSHTTPOperation *operation = [DSHTTPOperation new];
    operation.request = request;
    operation.parameters = parameters;
    operation.httpCompletion = completion;
    
    pthread_mutex_lock(&_configurationLock);
    operation.httpSession = _httpSession;
    operation.requestSerializer = _requestSerializer;
    operation.responseSerializer = _responseSerializer;
    operation.completionQueue = _completionQueue;
    pthread_mutex_unlock(&_configurationLock);
    return operation;
}

- (DSHTTPOperation *)scheduledWithURLString:(NSString *)urlString
                                     method:(DSHTTPRequestMethod)method
                                 parameters:(NSDictionary *)parameters
                                 completion:(DSHTTPCompletion)completion
{
    NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString relativeToURL:self.baseURL]];
    mutableRequest.HTTPMethod = method;
    return [self scheduledWithRequest:mutableRequest parameters:parameters completion:completion];
}

- (DSHTTPOperation *)scheduledWithRequest:(NSURLRequest *)request
                               parameters:(NSDictionary *)parameters
                               completion:(DSHTTPCompletion)completion
{
    DSHTTPOperation *operation = [self operationWithRequest:request parameters:parameters completion:completion];
    
    if (operation)
    {
        [self addOperation:operation];
    }
    
    return operation;
}

#pragma mark -添加HTTP交互操作
- (void)addOperation:(DSHTTPOperation *)operation
{
    if (operation)
    {
        [_operationQueue addOperation:operation];
    }
}

#pragma mark - Set & Get
- (void)setHttpSession:(DSHTTPSession *)httpSession
{
    pthread_mutex_lock(&_configurationLock);
    _httpSession = httpSession;
    pthread_mutex_unlock(&_configurationLock);
}

- (DSHTTPSession *)httpSession
{
    pthread_mutex_lock(&_configurationLock);
    DSHTTPSession *httpSession = _httpSession;
    pthread_mutex_unlock(&_configurationLock);
    return httpSession;
}

- (void)setRequestSerializer:(id <DSHTTPRequestSerializer>)requestSerializer
{
    pthread_mutex_lock(&_configurationLock);
    _requestSerializer = requestSerializer;
    pthread_mutex_unlock(&_configurationLock);
}

- (id <DSHTTPRequestSerializer>)requestSerializer
{
    pthread_mutex_lock(&_configurationLock);
    id <DSHTTPRequestSerializer> requestSerializer = _requestSerializer;
    pthread_mutex_unlock(&_configurationLock);
    return requestSerializer;
}

- (void)setResponseSerializer:(id <DSHTTPResponseSerializer>)responseSerializer
{
    pthread_mutex_lock(&_configurationLock);
    _responseSerializer = responseSerializer;
    pthread_mutex_unlock(&_configurationLock);
}

- (id <DSHTTPResponseSerializer>)responseSerializer
{
    pthread_mutex_lock(&_configurationLock);
    id <DSHTTPResponseSerializer> responseSerializer = _responseSerializer;
    pthread_mutex_unlock(&_configurationLock);
    return responseSerializer;
}

- (void)setCompletionQueue:(dispatch_queue_t)completionQueue
{
    pthread_mutex_lock(&_configurationLock);
    _completionQueue = completionQueue;
    pthread_mutex_unlock(&_configurationLock);
}

- (dispatch_queue_t)completionQueue
{
    pthread_mutex_lock(&_configurationLock);
    dispatch_queue_t completionQueue = _completionQueue;
    pthread_mutex_unlock(&_configurationLock);
    return completionQueue;;
}

- (void)setMaxConcurrentOperationCount:(NSUInteger)maxConcurrentOperationCount
{
    _operationQueue.maxConcurrentOperationCount = maxConcurrentOperationCount;
}

- (NSUInteger)maxConcurrentOperationCount
{
    return _operationQueue.maxConcurrentOperationCount;
}

- (void)setBaseURL:(NSURL *)baseURL
{
    pthread_mutex_lock(&_baseURLLock);
    _baseURL = [baseURL copy];
    pthread_mutex_unlock(&_baseURLLock);
}

- (NSURL *)baseURL
{
    pthread_mutex_lock(&_baseURLLock);
    NSURL *baseURL = _baseURL;
    pthread_mutex_unlock(&_baseURLLock);
    return baseURL;
}

@end



































