//
//  DSOperation.h
//  HTTPNetworkDemo
//
//  Created by DelpanSun on 2020/5/12.
//  Copyright © 2020 DelpanSun. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * @brief 操作状态
 */
typedef NS_ENUM(u_int8_t, DSOperationState)
{
    /** 准备好 */
    DSOperationStateReady = 0,
    /** 处理中 */
    DSOperationStateExecuting,
    /** 已取消 */
    DSOperationStateCanceled,
    /** 完成 */
    DSOperationStateCompleted
};

/**
 * @brief 操作完成回调
 */
typedef void (^DSOperationCompletion)(void);

/**
 *
 * DSOperation(Abstraction Class)
 *
 */
@interface DSOperation : NSObject

/**
 * @brief 创建操作
 *
 * @param identifier 操作唯一标识
 *
 * @return 操作
 */
+ (instancetype)operationWithIdentifier:(NSString *)identifier;

/**
 * @brief 状态
 */
@property (assign) DSOperationState state;

/**
 * @brief 唯一标识
 */
@property (copy) NSString *identifier;

/**
 * @brief 完成回调
 */
@property (copy) DSOperationCompletion completion;

/**
 * @brief 操作开始
 */
- (void)start;

/**
 * @brief 操作取消
 */
- (void)cancel;

/**
 * @brief 在状态同步上下文中获取状态
 *
 * @param lockContext 同步上下文
 */
- (void)stateLockContext:(DSOperationState (^)(DSOperationState state))lockContext;

@end



/**
 *
 * DSBlockOperation
 *
 */
typedef void (^DSBlockOperationBlock)(void);

@interface DSBlockOperation : DSOperation

/**
 * @brief 创建Block操作
 *
 * @param block 待执行的Block
 *
 * @return 操作
 */
+ (instancetype)blockOperationWithBlock:(DSBlockOperationBlock)block;

/**
 * @brief 执行的Block
 */
@property (readonly) NSArray<DSBlockOperationBlock> *executionBlocks;

/**
 * @brief 添加Block
 *
 * @param block 待执行的Block
 */
- (void)addExecutionBlock:(DSBlockOperationBlock)block;

@end



/**
 *
 * DSOperationQueue
 *
 */
@interface DSOperationQueue : NSObject

/**
 * @brief 创建操作队列
 *
 * @param queue GCD Queue
 *
 * @return 操作队列
 */
+ (instancetype)operationQueueWithQueue:(dispatch_queue_t)queue;

/**
 * @brief 队列最大并发数
 */
@property (assign) NSUInteger maxConcurrentOperationCount;

/**
 * @brief 通过唯一标识获取操作
 *
 * @param identifier 操作唯一标识
 *
 * @return 操作
 */
- (DSOperation *)operationForIdentifier:(NSString *)identifier;

/**
 * @brief 添加操作
 *
 * @param operation 操作
 */
- (void)addOperation:(DSOperation *)operation;

/**
 * @brief 添加一组操作
 *
 * @param operations 一组操作
 */
- (void)addOperations:(NSArray<DSOperation *> *)operations;

/**
 * @brief 添加操作(DSBlockOperation)
 *
 * @param block DSBlockOperation block
 */
- (void)addExecutionBlock:(DSBlockOperationBlock)block;

/**
 * @brief 移除操作
 *
 * @param operation 操作
 */
- (void)removeOperation:(DSOperation *)operation;

/**
 * @brief 取消所有操作
 */
- (void)cancelAllOperations;

@end























