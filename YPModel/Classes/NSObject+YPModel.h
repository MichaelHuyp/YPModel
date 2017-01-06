//
//  NSObject+YPModel.h
//  YPModel
//
//  Created by 胡云鹏 on 2016/12/27.
//  Copyright © 2016年 yongche. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (YPModel)
/**
 json转模型
 */
+ (nullable instancetype)yp_modelWithJSON:(id)json;

/**
 字典转模型
 */
+ (nullable instancetype)yp_modelWithDict:(NSDictionary *)dict;
@end

@interface NSArray (YPModel)
/**
 数组转模型
 */
+ (nullable NSArray *)yp_modelArrayWithClass:(Class)cls json:(id)json;
@end


@protocol YPModel <NSObject>

@optional
+ (nullable NSDictionary<NSString *, NSString *> *)arrayModelPropertyKeyDict;
+ (nullable NSDictionary<NSString *, NSString *> *)customPropertyNameDict;
@end

NS_ASSUME_NONNULL_END
