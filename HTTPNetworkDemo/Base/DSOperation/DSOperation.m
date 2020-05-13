//
//  DSOperation.m
//  HTTPNetworkDemo
//
//  Created by DelpanSun on 2020/5/12.
//  Copyright © 2020 DelpanSun. All rights reserved.
//

#import "DSOperation.h"
#import <pthread.h>

/**
 *
 * DSOperationDelegate
 *
 */
@protocol DSOperationDelegate <NSObject>

@optional

- (void)operationCompleted:(DSOperation *)operation;

@end



/**
 *
 * DSOperation
 *
 */
@interface DSOperation ()
{
    @public
    pthread_mutex_t _stateLock;
    pthread_mutex_t _identiferLock;
    pthread_mutex_t _completionLock;
    
    DSOperationState _state;
    NSString *_identifier;
    DSOperationCompletion _completion;
    
    dispatch_queue_t _completionQueue;
}

@property (nonatomic, weak) id <DSOperationDelegate> operationDelegate;

@end

@implementation DSOperation

#pragma mark - Factory
+ (instancetype)operationWithIdentifier:(NSString *)identifier
{
    DSOperation *operation = [self new];
    operation->_identifier = identifier;
    return operation;
}

#pragma mark - Life cycle
- (instancetype)init
{
    if (self = [super init])
    {
        pthread_mutex_init(&_stateLock, NULL);
        pthread_mutex_init(&_identiferLock, NULL);
        pthread_mutex_init(&_completionLock, NULL);
        
        _state = DSOperationStateReady;
        _completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    }
    
    return self;
}

- (void)dealloc
{
    pthread_mutex_destroy(&_stateLock);
    pthread_mutex_destroy(&_identiferLock);
    pthread_mutex_destroy(&_completionLock);
//    NSLog(@"%s", __func__);
}

#pragma mark - Abstraction Methods
- (void)start
{
    
}

- (void)cancel
{
    pthread_mutex_lock(&_stateLock);
    
    if (_state < DSOperationStateCanceled)
    {
        _state = DSOperationStateCanceled;
    }
    
    pthread_mutex_unlock(&_stateLock);
}

#pragma mark -在状态同步上下文中获取状态
- (void)stateLockContext:(DSOperationState (^)(DSOperationState state))lockContext
{
    if (lockContext)
    {
        pthread_mutex_lock(&_stateLock);
        _state = lockContext(_state);
        
        if (_state == DSOperationStateCompleted)
        {
            [self _operationCompleted];
        }
        
        pthread_mutex_unlock(&_stateLock);
    }
}

#pragma mark - Private Methods
#pragma mark -Operation完成
- (void)_operationCompleted
{
    pthread_mutex_lock(&_completionLock);
    DSOperationCompletion completion = _completion;
    _completion = nil;
    pthread_mutex_unlock(&_completionLock);
    
    if (completion)
    {
        dispatch_async(_completionQueue, ^{
            
            completion();
        });
    }
    
    if ([_operationDelegate respondsToSelector:@selector(operationCompleted:)])
    {
        [_operationDelegate operationCompleted:self];
    }
}

#pragma mark - Set & Get
- (void)setState:(DSOperationState)state
{
    [self stateLockContext:^DSOperationState(DSOperationState currentState) {
        
        return state;
    }];
}

- (DSOperationState)state
{
    pthread_mutex_lock(&_stateLock);
    DSOperationState state = _state;
    pthread_mutex_unlock(&_stateLock);
    return state;
}

- (void)setIdentifier:(NSString *)identifier
{
    pthread_mutex_lock(&_identiferLock);
    _identifier = [identifier copy];
    pthread_mutex_unlock(&_identiferLock);
}

- (NSString *)identifier
{
    pthread_mutex_lock(&_identiferLock);
    NSString *identifier = [_identifier copy];
    pthread_mutex_unlock(&_identiferLock);
    return identifier;
}

- (void)setCompletion:(DSOperationCompletion)completion
{
    pthread_mutex_lock(&_completionLock);
    _completion = [completion copy];
    pthread_mutex_unlock(&_completionLock);
}

- (DSOperationCompletion)completion
{
    pthread_mutex_lock(&_completionLock);
    DSOperationCompletion completion = _completion;
    pthread_mutex_unlock(&_completionLock);
    return completion;
}

@end



/**
 *
 * DSBlockOperation
 *
 */
@implementation DSBlockOperation
{
    @public
    NSMutableArray<DSBlockOperationBlock> *_blocks;
}

#pragma mark - Factory
+ (instancetype)blockOperationWithBlock:(DSBlockOperationBlock)block
{
    DSBlockOperation *operation = [DSBlockOperation new];
    [operation->_blocks addObject:block];
    return operation;
}

#pragma mark - Life cycle
- (instancetype)init
{
    if (self = [super init])
    {
        _blocks = [NSMutableArray array];
    }
    
    return self;
}

#pragma mark - Public Methods
#pragma mark -添加Block
- (void)addExecutionBlock:(DSBlockOperationBlock)block
{
    [self stateLockContext:^DSOperationState(DSOperationState state) {
        
        if (state == DSOperationStateReady)
        {
            [_blocks addObject:block];
        }
        
        return state;
    }];
}

#pragma mark - Override Methods
- (void)start
{
    @autoreleasepool
    {
        [self stateLockContext:^DSOperationState(DSOperationState state) {
            
            if (state == DSOperationStateReady)
            {
                for (DSBlockOperationBlock block in _blocks)
                {
                    block();
                }
            }
            
            return DSOperationStateCompleted;
        }];
    }
}

- (void)cancel
{
    self.state = DSOperationStateCompleted;
}

@end



/**
 *
 * _DSCoreOperationQueueDelegate
 *
 */
@class _DSCoreOperationQueue;

@protocol _DSCoreOperationQueueDelegate <NSObject>

@optional

/**
 * @brief 队列中即将开始执行的操作
 *
 * @param operationQueue 队列
 * @param operation 即将开始执行的操作
 */
- (void)operationQueue:(_DSCoreOperationQueue *)operationQueue operationWillExecute:(DSOperation *)operation;

/**
 * @brief 队列中已完成的操作
 *
 * @param operationQueue 队列
 * @param operation 已完成的操作
 */
- (void)operationQueue:(_DSCoreOperationQueue *)operationQueue operationDidCompleted:(DSOperation *)operation;

/**
 * @brief 队列中所有的操作已完成
 *
 * @param operationQueue 队列
 */
- (void)allOperationsDidCompleted:(_DSCoreOperationQueue *)operationQueue;

@end



/**
 *
 * _DSCoreOperationQueue
 *
 */
@interface _DSCoreOperationQueue : NSObject <DSOperationDelegate>
{
    NSUInteger _maxConcurrentOperationCount;
    pthread_mutex_t _maxConcurrentOperationCountLock;
    
    NSMutableDictionary *_allOperations;
    NSMutableArray *_pendingOperations;
    NSMutableArray *_executingOperations;
    
    dispatch_queue_t _operationsExecutingQueue;
    dispatch_queue_t _operationSerialQueue;
}

@property (nonatomic, weak) id <_DSCoreOperationQueueDelegate> delegate;

@end

@implementation _DSCoreOperationQueue

#pragma mark - Life cycle
- (instancetype)init
{
    return [self initWithQueue:nil delegate:nil];
}

- (instancetype)initWithQueue:(dispatch_queue_t)queue delegate:(__weak id <_DSCoreOperationQueueDelegate>)delegate
{
    if (self = [super init])
    {
        pthread_mutex_init(&_maxConcurrentOperationCountLock, NULL);
        
        _allOperations = [NSMutableDictionary dictionary];
        _pendingOperations = [NSMutableArray array];
        _executingOperations = [NSMutableArray array];
        
        _maxConcurrentOperationCount = 10;
        _delegate = delegate;
        
        _operationsExecutingQueue = queue ? queue : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        _operationSerialQueue = dispatch_queue_create("com._DSCoreOperationQueue.SerialQueue", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

- (void)dealloc
{
    pthread_mutex_destroy(&_maxConcurrentOperationCountLock);
    NSLog(@"%s", __func__);
}

#pragma mark - Public Methods
#pragma mark -通过唯一标识获取操作
- (DSOperation *)operationForIdentifier:(NSString *)identifier
{
    __block DSOperation *operation;
    __weak NSMutableDictionary *allOperations = _allOperations;
    
    if (identifier.length > 0)
    {
        dispatch_sync(_operationSerialQueue, ^{
            
            operation = [allOperations objectForKey:identifier];
        });
    }
    
    return operation;
}

#pragma mark -添加操作
- (void)addOperation:(DSOperation *)operation
{
    if (operation)
    {
        [self addOperations:@[ operation ]];
    }
}

#pragma mark -添加一组操作
- (void)addOperations:(NSArray<DSOperation *> *)operations
{
    if (operations.count > 0)
    {
        operations = [operations copy];
        __weak _DSCoreOperationQueue *operationQueue = self;
        
        dispatch_async(_operationSerialQueue, ^{
            
            [operationQueue _addOperations:operations];
        });
    }
}

#pragma mark -移除操作
- (void)removeOperation:(DSOperation *)operation
{
    if (operation)
    {
        __weak _DSCoreOperationQueue *operationQueue = self;
        
        dispatch_async(_operationSerialQueue, ^{
            
            [operationQueue _removeOperation:operation];
        });
    }
}

#pragma mark -取消所有操作
- (void)cancelAllOperations
{
    __weak NSMutableDictionary *allOperations = _allOperations;
    
    dispatch_async(_operationSerialQueue, ^{
        
        NSArray *operations = [allOperations allValues];
        
        for (DSOperation *operation in operations)
        {
            [operation cancel];
        }
    });
}

#pragma mark - Private Methods
#pragma mark -添加一组操作
- (void)_addOperations:(NSArray<DSOperation *> *)operations
{
    for (DSOperation *operation in operations)
    {
        [operation stateLockContext:^DSOperationState(DSOperationState state) {
            
            if (state == DSOperationStateReady)
            {
                NSString *identifier = operation.identifier;
                
                if (identifier.length == 0)
                {
                    operation.identifier = identifier = [NSString stringWithFormat:@"%p", operation];
                }
                
                if (![_allOperations objectForKey:identifier])
                {
                    operation.operationDelegate = self;
                    
                    [_allOperations setObject:operation forKey:identifier];
                    [_pendingOperations addObject:operation];
                    
                    [self _checkOperations];
                }
            }
            
            return state;
        }];
    }
}

#pragma mark -移除操作
- (void)_removeOperation:(DSOperation *)operation
{
    operation.operationDelegate = nil;
    
    if (operation.identifier.length > 0)
    {
        [_allOperations removeObjectForKey:operation.identifier];
    }
    
    if ([_pendingOperations containsObject:operation])
    {
        [_pendingOperations removeObject:operation];
    }
    
    if ([_executingOperations containsObject:operation])
    {
        [_executingOperations removeObject:operation];
    }
}

#pragma mark -启动Operation
- (void)_operationExecute:(DSOperation *)operation
{
    [_executingOperations addObject:operation];
    __weak _DSCoreOperationQueue *operationQueue = self;
    
    dispatch_async(_operationsExecutingQueue, ^{
        
        if ([operationQueue.delegate respondsToSelector:@selector(operationQueue:operationWillExecute:)])
        {
            [operationQueue.delegate operationQueue:operationQueue operationWillExecute:operation];
        }
        
        [operation start];
    });
}

#pragma mark -检测Operation
- (void)_checkOperations
{
    if (_allOperations.count > 0)
    {
        if ((_executingOperations.count < self.maxConcurrentOperationCount) &&
            (_pendingOperations.count > 0))
        {
            DSOperation *executeOperation = [_pendingOperations objectAtIndex:0];
            [_pendingOperations removeObjectAtIndex:0];
            [self _operationExecute:executeOperation];
        }
    }
    else
    {
        if ([_delegate respondsToSelector:@selector(allOperationsDidCompleted:)])
        {
            [_delegate allOperationsDidCompleted:self];
        }
    }
}

#pragma mark - Delegate
#pragma mark -DSOperationDelegate
- (void)operationCompleted:(DSOperation *)operation
{
    __weak _DSCoreOperationQueue *operationQueue = self;
    
    dispatch_async(_operationSerialQueue, ^{
        
        if ([operationQueue.delegate respondsToSelector:@selector(operationQueue:operationDidCompleted:)])
        {
            [operationQueue.delegate operationQueue:operationQueue operationDidCompleted:operation];
        }
        
        [operationQueue _removeOperation:operation];
        [operationQueue _checkOperations];
    });
}

#pragma mark - Set & Get
- (void)setMaxConcurrentOperationCount:(NSUInteger)maxConcurrentOperationCount
{
    pthread_mutex_lock(&_maxConcurrentOperationCountLock);
    _maxConcurrentOperationCount = maxConcurrentOperationCount;
    pthread_mutex_unlock(&_maxConcurrentOperationCountLock);
}

- (NSUInteger)maxConcurrentOperationCount
{
    pthread_mutex_lock(&_maxConcurrentOperationCountLock);
    NSUInteger maxConcurrentOperationCount = _maxConcurrentOperationCount;
    pthread_mutex_unlock(&_maxConcurrentOperationCountLock);
    return maxConcurrentOperationCount;
}

@end



/**
 *
 * DSOperationQueue
 *
 */
@implementation DSOperationQueue
{
    _DSCoreOperationQueue *_operationQueue;
}

#pragma mark - Factory
+ (instancetype)operationQueueWithQueue:(dispatch_queue_t)queue
{
    return [[self alloc] initWithQueue:queue];
}

#pragma mark - Life cycle
- (instancetype)init
{
    return [self initWithQueue:nil];
}

- (instancetype)initWithQueue:(dispatch_queue_t)queue
{
    if (self = [super init])
    {
        _operationQueue = [[_DSCoreOperationQueue alloc] initWithQueue:queue delegate:nil];
    }
    
    return self;
}

#pragma mark - Public Methods
#pragma mark -通过唯一标识获取操作
- (DSOperation *)operationForIdentifier:(NSString *)identifier
{
    return [_operationQueue operationForIdentifier:identifier];
}

#pragma mark -添加操作
- (void)addOperation:(DSOperation *)operation
{
    [_operationQueue addOperation:operation];
}

#pragma mark -添加一组操作
- (void)addOperations:(NSArray<DSOperation *> *)operations
{
    [_operationQueue addOperations:operations];
}

#pragma mark -添加操作(DSBlockOperation)
- (void)addExecutionBlock:(DSBlockOperationBlock)block
{
    if (block)
    {
       [_operationQueue addOperation:[DSBlockOperation blockOperationWithBlock:block]];
    }
}

#pragma mark -移除操作
- (void)removeOperation:(DSOperation *)operation
{
    [_operationQueue removeOperation:operation];
}

#pragma mark -取消所有操作
- (void)cancelAllOperations
{
    [_operationQueue cancelAllOperations];
}

#pragma mark - Set & Get
- (void)setMaxConcurrentOperationCount:(NSUInteger)maxConcurrentOperationCount
{
    _operationQueue.maxConcurrentOperationCount = maxConcurrentOperationCount;
}

- (NSUInteger)maxConcurrentOperationCount
{
    return _operationQueue.maxConcurrentOperationCount;
}

@end

