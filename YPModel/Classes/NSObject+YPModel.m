//
//  NSObject+YPModel.m
//  YPModel
//
//  Created by 胡云鹏 on 2016/12/27.
//  Copyright © 2016年 yongche. All rights reserved.
//

#import "NSObject+YPModel.h"
#import <objc/message.h>
#import "YPClassPropertyInfo.h"

@implementation NSObject (YPModel)

+ (instancetype)yp_modelWithJSON:(id)json
{
    if (!json || json == (id)kCFNull) return nil;
    NSDictionary *dict = nil;
    NSData *jsonData = nil;
    if ([json isKindOfClass:[NSDictionary class]]) {
        dict = json;
    } else if ([json isKindOfClass:[NSString class]]) {
        jsonData = [(NSString *)json dataUsingEncoding:NSUTF8StringEncoding];
    } else if ([json isKindOfClass:[NSData class]]) {
        jsonData = json;
    }
    if (jsonData) {
        dict = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:NULL];
        if (![dict isKindOfClass:[NSDictionary class]]) dict = nil;
    }
    return [self yp_modelWithDict:dict];
}

+ (instancetype)yp_modelWithDict:(NSDictionary *)dict
{
    if (!dict || dict == (id)kCFNull) return nil;
    if (![dict isKindOfClass:[NSDictionary class]]) return nil;
    
    // 1.获取要转化模型的类
    Class cls = [self class];
    
    // 2.遍历本类及父类中的属性
    
    // 2.1 递归取出本类及全部的父类的属性列表
    NSMutableDictionary<NSString *, YPClassPropertyInfo *> * objcPropertyList = [NSMutableDictionary dictionary];
    
    do {
        Class superCls = class_getSuperclass(cls);
        if (superCls == nil) break; // 不去遍历NSObject的属性
        
        // 2.2 拿到所遍历类的属性列表 保存到objcPropertyList中
        unsigned int propertyCount = 0;
        objc_property_t *properties = class_copyPropertyList(cls, &propertyCount);
        for (unsigned int i = 0; i < propertyCount; i++) {
            objc_property_t property = properties[i];
            YPClassPropertyInfo *propertyInfo = [[YPClassPropertyInfo alloc] initWithProperty:property];
            if (propertyInfo.name) objcPropertyList[propertyInfo.name] = propertyInfo;
        }
        free(properties);
        
        cls = superCls;
        
        
    } while (cls != nil);
    
    // 3.创建模型类对象
    NSObject *obj = [self new];
    
    // 4.根据遍历出的属性从字典中取出对应的key value赋值
    [objcPropertyList enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull propertyName, YPClassPropertyInfo * _Nonnull propertyInfo, BOOL * _Nonnull stop) {
        
        // 4.0 首先取出自定义的属性名字典
        NSDictionary *customPropertyNameDict = [(id)[obj class] customPropertyNameDict];
        NSString *customPropertyName = customPropertyNameDict[propertyName];
        
        // 4.1 根据属性名从字典中取对应的value
        id value = dict[propertyName];
        if (customPropertyName.length) {
            value = dict[customPropertyName];
        }
        
        if (!value || value == (id)kCFNull) return; // 如果value为空 结束此次循环
        
        // 4.2 拿到属性的类型
        YPEncodingType type = propertyInfo.type;
        
        if (propertyInfo.isCNumber) { // 属性可以转化为NSNumber类型
            // 先将字典中的value解析成NSNumber类型
            NSNumber *num = [self YPNSNumberCreateFromID:value];
            
            // 开始对模型的属性赋值咯
            switch (type & YPEncodingTypeMask) {
                case YPEncodingTypeBool: { // 模型属性为BOOL
                    ((void (*)(id, SEL, bool))(void *)objc_msgSend)((id)obj, propertyInfo.setter, num.boolValue);
                } break;
                case YPEncodingTypeInt8: { // 模型属性为char
                    ((void (*)(id, SEL, int8_t))(void *)objc_msgSend)((id)obj, propertyInfo.setter, (int8_t)num.charValue);
                } break;
                case YPEncodingTypeUInt8: { // 模型属性为unsignedChar
                    ((void (*)(id, SEL, uint8_t))(void *)objc_msgSend)((id)obj, propertyInfo.setter, (uint8_t)num.unsignedCharValue);
                } break;
                case YPEncodingTypeInt16: { // 模型属性为short
                    ((void (*)(id, SEL, int16_t))(void *)objc_msgSend)((id)obj, propertyInfo.setter, (int16_t)num.shortValue);
                } break;
                case YPEncodingTypeUInt16: { // 模型属性为unsignedShort
                    ((void (*)(id, SEL, uint16_t))(void *)objc_msgSend)((id)obj, propertyInfo.setter, (uint16_t)num.unsignedShortValue);
                } break;
                case YPEncodingTypeInt32: { // 模型属性为int
                    ((void (*)(id, SEL, int32_t))(void *)objc_msgSend)((id)obj, propertyInfo.setter, (int32_t)num.intValue);
                } break;
                case YPEncodingTypeUInt32: { // 模型属性为unsignedInt
                    ((void (*)(id, SEL, uint32_t))(void *)objc_msgSend)((id)obj, propertyInfo.setter, (uint32_t)num.unsignedIntValue);
                } break;
                case YPEncodingTypeInt64: { // 模型属性为long long
                    if ([num isKindOfClass:[NSDecimalNumber class]]) { // 科学计数类情况
                        ((void (*)(id, SEL, int64_t))(void *) objc_msgSend)((id)obj, propertyInfo.setter, (int64_t)num.stringValue.longLongValue);
                    } else {
                        ((void (*)(id, SEL, int64_t))(void *) objc_msgSend)((id)obj, propertyInfo.setter, (int64_t)num.longLongValue);
                    }
                } break;
                case YPEncodingTypeUInt64: { // 模型属性为unsignedLongLongValue
                    if ([num isKindOfClass:[NSDecimalNumber class]]) { // 科学计数类情况
                        ((void (*)(id, SEL, uint64_t))(void *) objc_msgSend)((id)obj, propertyInfo.setter, (uint64_t)num.stringValue.longLongValue);
                    } else {
                        ((void (*)(id, SEL, uint64_t))(void *) objc_msgSend)((id)obj, propertyInfo.setter, (uint64_t)num.unsignedLongLongValue);
                    }
                } break;
                case YPEncodingTypeFloat: { // 模型属性为float
                    float f = num.floatValue;
                    if (isnan(f) || isinf(f)) f = 0;
                    ((void (*)(id, SEL, float))(void *)objc_msgSend)((id)obj, propertyInfo.setter, f);
                } break;
                case YPEncodingTypeDouble: { // 模型属性为double
                    double d = num.doubleValue;
                    if (isnan(d) || isinf(d)) d = 0;
                    ((void (*)(id, SEL, double))(void *)objc_msgSend)((id)obj, propertyInfo.setter, d);
                } break;
                case YPEncodingTypeLongDouble: { // 模型属性为double
                    long double d = num.doubleValue;
                    if (isnan(d) || isinf(d)) d = 0;
                    ((void (*)(id, SEL, long double))(void *)objc_msgSend)((id)obj, propertyInfo.setter, (long double)d);
                } break;
                default: break;
            }
        } else if (propertyInfo.nsType) { // 属性是NS类簇
            switch (propertyInfo.nsType) {
                case YPEncodingNSTypeNSString:
                case YPEncodingNSTypeNSMutableString: { // NSString、NSMutableString类型的处理
                    if ([value isKindOfClass:[NSString class]]) {
                        // 字典的value也是NSString类簇
                        if (propertyInfo.nsType == YPEncodingNSTypeNSString) {
                            ((void(*)(id,SEL,id))(void *)objc_msgSend)((id)obj, propertyInfo.setter, value);
                        } else {
                            ((void(*)(id,SEL,id))(void *)objc_msgSend)((id)obj, propertyInfo.setter, ((NSString *)value).mutableCopy);
                        }
                    } else if ([value isKindOfClass:[NSNumber class]]) {
                        // 字典的value是NSNumber类型, 将value转化为字符串
                        id valueStr = (propertyInfo.nsType == YPEncodingNSTypeNSString) ? ((NSNumber *)value).stringValue : ((NSNumber *)value).stringValue.mutableCopy;
                        ((void(*)(id,SEL,id))(void *)objc_msgSend)((id)obj, propertyInfo.setter, valueStr);
                    } else if ([value isKindOfClass:[NSData class]]) {
                        // 字典的value是NSData类型,那么先转成字符串然后赋值
                        NSString *str = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
                        ((void(*)(id,SEL,id))(void *)objc_msgSend)((id)obj, propertyInfo.setter, str);
                    } else if ([value isKindOfClass:[NSURL class]]) {
                        // 字典的value是NSURL类型,那么取NSURL的absoluteString赋值
                        id valueStr = (propertyInfo.nsType == YPEncodingNSTypeNSString) ? ((NSURL *)value).absoluteString : ((NSURL *)value).absoluteString.mutableCopy;
                        ((void(*)(id,SEL,id))(void *)objc_msgSend)((id)obj, propertyInfo.setter, valueStr);
                    } else if ([value isKindOfClass:[NSAttributedString class]]) {
                        // 字典的value是NSAttributedString类型
                        id valueStr = (propertyInfo.nsType == YPEncodingNSTypeNSString) ? ((NSAttributedString *)value).string : ((NSAttributedString *)value).string.mutableCopy;
                        ((void(*)(id,SEL,id))(void *)objc_msgSend)((id)obj, propertyInfo.setter, valueStr);
                    }
                } break;
                case YPEncodingNSTypeNSValue:
                case YPEncodingNSTypeNSNumber:
                case YPEncodingNSTypeNSDecimalNumber: {
                    if (propertyInfo.nsType == YPEncodingNSTypeNSNumber) {
                        // 模型属性是NSNumber, 那么将字典中的value转化为NSNumber
                        id num = [self YPNSNumberCreateFromID:value];
                        ((void(*)(id,SEL,id))(void *)objc_msgSend)((id)obj, propertyInfo.setter, num);
                    } else if (propertyInfo.nsType == YPEncodingNSTypeNSDecimalNumber) {
                        // 模型属性是NSDecimalNumber
                        if ([value isKindOfClass:[NSDecimalNumber class]]) {
                            // 字典中的value也是NSDecimalNumber 直接赋值
                            ((void(*)(id,SEL,id))(void *)objc_msgSend)((id)obj, propertyInfo.setter, value);
                        } else if ([value isKindOfClass:[NSNumber class]]) {
                            // 字典中的value是NSNumber
                            NSDecimalNumber *decNum = [NSDecimalNumber decimalNumberWithDecimal:[((NSNumber *)value) decimalValue]];
                            ((void(*)(id,SEL,id))(void *)objc_msgSend)((id)obj, propertyInfo.setter, decNum);
                        } else if ([value isKindOfClass:[NSString class]]) {
                            // 字典中的value是NSString
                            NSDecimalNumber *decNum = [NSDecimalNumber decimalNumberWithString:value];
                            NSDecimal dec = decNum.decimalValue;
                            if (dec._length == 0 && dec._isNegative) {
                                decNum = nil; // NaN
                            }
                            ((void(*)(id,SEL,id))(void *)objc_msgSend)((id)obj, propertyInfo.setter, decNum);
                        }
                    } else {
                        // 模型属性是NSValue
                        if ([value isKindOfClass:[NSValue class]]) {
                            // 字典中的value也是NSValue 直接赋值
                            ((void(*)(id,SEL,id))(void *)objc_msgSend)((id)obj, propertyInfo.setter, value);
                        }
                    }
                } break;
                    
                case YPEncodingNSTypeNSData:
                case YPEncodingNSTypeNSMutableData: {
                    if ([value isKindOfClass:[NSData class]]) {
                        // 字典中的value是NSData类簇
                        if (propertyInfo.nsType == YPEncodingNSTypeNSData) {
                            // 模型的属性是NSData
                            ((void(*)(id,SEL,id))(void *)objc_msgSend)((id)obj, propertyInfo.setter, value);
                        } else {
                            // 模型属性是是NSMutableData
                            NSMutableData *data = ((NSData *)value).mutableCopy;
                            ((void(*)(id,SEL,id))(void *)objc_msgSend)((id)obj, propertyInfo.setter, data);
                        }
                    } else if ([value isKindOfClass:[NSString class]]) {
                        // 字典中的value是NSString
                        NSData *data = [(NSString *)value dataUsingEncoding:NSUTF8StringEncoding];
                        if (propertyInfo.nsType == YPEncodingNSTypeNSMutableData) {
                            data = ((NSData *)data).mutableCopy;
                        }
                        ((void(*)(id,SEL,id))(void *)objc_msgSend)((id)obj, propertyInfo.setter, data);
                    }
                } break;
                    
                case YPEncodingNSTypeNSDate: {
                    // 属性是NSDate
                    if ([value isKindOfClass:[NSDate class]]) {
                        // 字典的value也是NSDate 直接赋值
                        ((void(*)(id,SEL,id))(void *)objc_msgSend)((id)obj, propertyInfo.setter, value);
                    } else if([value isKindOfClass:[NSString class]]) {
                        // 字典的value是NSString类型 先转化为NSDate然后赋值
                        id date = [self YPNSDateFromString:value];
                        ((void(*)(id,SEL,id))(void *)objc_msgSend)((id)obj, propertyInfo.setter, date);
                    }
                    
                } break;
                    
                case YPEncodingNSTypeNSURL: {
                    // 模型属性是NSURL
                    if ([value isKindOfClass:[NSURL class]]) {
                        // 字典的value也是NSURL 直接赋值
                        ((void(*)(id,SEL,id))(void *)objc_msgSend)((id)obj, propertyInfo.setter, value);
                    } else if ([value isKindOfClass:[NSString class]]) {
                        // 字典的value是字符串
                        
                        // 先对字符串进行trim
                        NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
                        NSString *str = [value stringByTrimmingCharactersInSet:set];
                        if (str.length == 0) {
                            ((void(*)(id,SEL,id))(void *)objc_msgSend)((id)obj, propertyInfo.setter, nil);
                        } else {
                            ((void(*)(id,SEL,id))(void *)objc_msgSend)((id)obj, propertyInfo.setter, [[NSURL alloc] initWithString:str]);
                        }
                    }
                }
                    
                case YPEncodingNSTypeNSArray:
                case YPEncodingNSTypeNSMutableArray: {
                    // 模型的属性是数组类簇
                    
                    // 1.首先要知道该属性数组中装的是什么类型
                    Class arrCls = nil;
                    if ([(id)[obj class] respondsToSelector:@selector(arrayModelPropertyKeyDict)]) {
                        // 取出数组key-class映射字典
                        NSDictionary *arrayModelPropertyKeyDict = [(id)[obj class] arrayModelPropertyKeyDict];
                        NSString *arrClsName = [arrayModelPropertyKeyDict objectForKey:propertyInfo.name];
                        if (arrClsName.length) {
                            arrCls = NSClassFromString(arrClsName);
                        }
                    }
                    
                    if (arrCls) { // 数组装的是要转化模型的类
                        
                        NSArray *valueArr = nil;
                        if ([value isKindOfClass:[NSArray class]]) {
                            // 字典的value是数组类簇
                            valueArr = value;
                        } else if ([value isKindOfClass:[NSSet class]]) {
                            // 字典的value是NSSet类簇
                            valueArr = ((NSSet *)value).allObjects;
                        }
                        
                        if (valueArr) {
                            NSMutableArray *modelArr = [NSMutableArray new];
                            // 遍历字典的value数组
                            
                            for (id one in valueArr) {
                                if ([one isKindOfClass:[arrCls class]]) {
                                    // 如果已经是模型 就不用转化了直接存进去
                                    [modelArr addObject:one];
                                } else if ([one isKindOfClass:[NSDictionary class]]) {
                                    // 如果是字典 那么需要递归字典转模型
                                    id model = [arrCls yp_modelWithDict:one];
                                    if (model) [modelArr addObject:model];
                                }
                            }
                        
                            // 赋值
                            ((void(*)(id,SEL,id))(void *)objc_msgSend)((id)obj, propertyInfo.setter, modelArr);
                        }
                        
                        
                    } else { // 数组内装的就是普通的数组
                        if ([value isKindOfClass:[NSArray class]]) {
                            // 字典的value是数组类簇
                            if (propertyInfo.nsType == YPEncodingNSTypeNSArray) {
                                // 模型属性是不可变数组
                                ((void(*)(id,SEL,id))(void *)objc_msgSend)((id)obj, propertyInfo.setter, value);
                            } else {
                                // 模型属性是可变数组
                                ((void(*)(id,SEL,id))(void *)objc_msgSend)((id)obj, propertyInfo.setter, ((NSArray *)value).mutableCopy);
                            }
                        } else if ([value isKindOfClass:[NSSet class]]) {
                            // 字典的value是NSSet类簇
                            
                            // 先转化为数组
                            NSArray *array = ((NSSet *)value).allObjects;
                            if (propertyInfo.nsType == YPEncodingNSTypeNSArray) {
                                // 模型属性是不可变数组
                                ((void(*)(id,SEL,id))(void *)objc_msgSend)((id)obj, propertyInfo.setter, array);
                            } else {
                                // 模型属性是可变数组
                                ((void(*)(id,SEL,id))(void *)objc_msgSend)((id)obj, propertyInfo.setter, array.mutableCopy);
                            }
                        }
                    }
                } break;
                    
                case YPEncodingNSTypeNSDictionary:
                case YPEncodingNSTypeNSMutableDictionary: {
                    // 模型属性是字典类簇
                    if ([value isKindOfClass:[NSDictionary class]]) {
                        // 字典的value是字典类簇
                        ((void(*)(id,SEL,id))(void *)objc_msgSend)((id)obj, propertyInfo.setter, (propertyInfo.nsType == YPEncodingNSTypeNSDictionary) ? value : ((NSDictionary *)value).mutableCopy);
                    }
                } break;
                // 暂时不支持NSSet
                default: break;
            }
            
            
        } else {
            // 模型属性不是Number类簇 也不是 NSType类簇
            
            // 暂时只支持对象
            switch (propertyInfo.type & YPEncodingTypeMask) {
                case YPEncodingTypeObject: {
                    // 模型属性是对象类型
                    if ([value isKindOfClass:propertyInfo.class]) {
                        // 字典的value和属性的类型一致 直接赋值
                        ((void(*)(id,SEL,id))(void *)objc_msgSend)((id)obj, propertyInfo.setter, value);
                    } else if ([value isKindOfClass:[NSDictionary class]]) {
                        // 字典的value是字典类簇
                     
                        // 先拿到当前属性的类
                        Class modelCls = propertyInfo.cls;
                        
                        // 递归字典转模型
                        id one = [modelCls yp_modelWithDict:value];
                        
                        // 赋值
                        ((void(*)(id,SEL,id))(void *)objc_msgSend)((id)obj, propertyInfo.setter, one);
                    }
                    
                } break;
                default:
                    break;
            }
        }
        
    }];
    
    
    // 5.返回赋值好的对象
    return obj;
}



/**
 NSString -> NSDate
 */
+ (NSDate *)YPNSDateFromString:(NSString *)str
{
    typedef NSDate *(^YPNSDateParseBlock)(NSString *string);
#define kParserNum 34
    static YPNSDateParseBlock blocks[kParserNum + 1] = {0};
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter.dateFormat = @"yyyy-MM-dd";
            blocks[10] = ^(NSString *string) { return [formatter dateFromString:string]; };
        }
        {
            /*
             2014-01-20 12:24:48
             2014-01-20T12:24:48   // Google
             2014-01-20 12:24:48.000
             2014-01-20T12:24:48.000
             */
            NSDateFormatter *formatter1 = [[NSDateFormatter alloc] init];
            formatter1.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter1.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter1.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
            
            NSDateFormatter *formatter2 = [[NSDateFormatter alloc] init];
            formatter2.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter2.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter2.dateFormat = @"yyyy-MM-dd HH:mm:ss";
            
            NSDateFormatter *formatter3 = [[NSDateFormatter alloc] init];
            formatter3.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter3.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter3.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS";
            
            NSDateFormatter *formatter4 = [[NSDateFormatter alloc] init];
            formatter4.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter4.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter4.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
            
            // 19位的格式化 2014-01-20 12:24:48 或 2014-01-20T12:24:48
            blocks[19] = ^(NSString *string) {
                if ([string characterAtIndex:10] == 'T') {
                    return [formatter1 dateFromString:string];
                } else {
                    return [formatter2 dateFromString:string];
                }
            };
            
            // 23位的格式化 2014-01-20 12:24:48.000 2014-01-20T12:24:48.000
            blocks[23] = ^(NSString *string) {
                if ([string characterAtIndex:10] == 'T') {
                    return [formatter3 dateFromString:string];
                } else {
                    return [formatter4 dateFromString:string];
                }
            };
        }
        
        {
            /*
             2014-01-20T12:24:48Z        // Github, Apple
             2014-01-20T12:24:48+0800    // Facebook
             2014-01-20T12:24:48+12:00   // Google
             2014-01-20T12:24:48.000Z
             2014-01-20T12:24:48.000+0800
             2014-01-20T12:24:48.000+12:00
             */
            NSDateFormatter *formatter = [NSDateFormatter new];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
            
            NSDateFormatter *formatter2 = [NSDateFormatter new];
            formatter2.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter2.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";
            
            // 20位的格式化 2014-01-20T12:24:48Z
            blocks[20] = ^(NSString *string) { return [formatter dateFromString:string]; };
            // 24位的格式化 2014-01-20T12:24:48+0800 2014-01-20T12:24:48.000Z
            blocks[24] = ^(NSString *string) { return [formatter dateFromString:string]?: [formatter2 dateFromString:string]; };
            // 25位的格式化 2014-01-20T12:24:48+12:00
            blocks[25] = ^(NSString *string) { return [formatter dateFromString:string]; };
            // 28位的格式化 2014-01-20T12:24:48.000+0800
            blocks[28] = ^(NSString *string) { return [formatter2 dateFromString:string]; };
            // 29位的格式化 2014-01-20T12:24:48.000+12:00
            blocks[29] = ^(NSString *string) { return [formatter2 dateFromString:string]; };
        }
        
        {
            /*
             Fri Sep 04 00:12:21 +0800 2015 // Weibo, Twitter
             Fri Sep 04 00:12:21.000 +0800 2015
             */
            NSDateFormatter *formatter = [NSDateFormatter new];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter.dateFormat = @"EEE MMM dd HH:mm:ss Z yyyy";
            
            NSDateFormatter *formatter2 = [NSDateFormatter new];
            formatter2.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter2.dateFormat = @"EEE MMM dd HH:mm:ss.SSS Z yyyy";
            
            // 30位的格式化 Fri Sep 04 00:12:21 +0800 2015
            blocks[30] = ^(NSString *string) { return [formatter dateFromString:string]; };
            // 34位的格式化 Fri Sep 04 00:12:21.000 +0800 2015
            blocks[34] = ^(NSString *string) { return [formatter2 dateFromString:string]; };
        }
    });
    if (!str) return nil;
    if (str.length > kParserNum) return nil;
    YPNSDateParseBlock parser = blocks[str.length];
    if (!parser) return nil;
    return parser(str);
#undef kParserNum
}

/**
 id类型 -> NSNumber
 */
+ (NSNumber *)YPNSNumberCreateFromID:(id)value {
    
    static NSCharacterSet *dot;
    static NSDictionary *dict;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dot = [NSCharacterSet characterSetWithRange:NSMakeRange('.', 1)];
        dict = @{@"TRUE" :   @(YES),
                @"True" :   @(YES),
                @"true" :   @(YES),
                @"FALSE" :  @(NO),
                @"False" :  @(NO),
                @"false" :  @(NO),
                @"YES" :    @(YES),
                @"Yes" :    @(YES),
                @"yes" :    @(YES),
                @"NO" :     @(NO),
                @"No" :     @(NO),
                @"no" :     @(NO),
                @"NIL" :    (id)kCFNull,
                @"Nil" :    (id)kCFNull,
                @"nil" :    (id)kCFNull,
                @"NULL" :   (id)kCFNull,
                @"Null" :   (id)kCFNull,
                @"null" :   (id)kCFNull,
                @"(NULL)" : (id)kCFNull,
                @"(Null)" : (id)kCFNull,
                @"(null)" : (id)kCFNull,
                @"<NULL>" : (id)kCFNull,
                @"<Null>" : (id)kCFNull,
                @"<null>" : (id)kCFNull};
    });
    
    
    if ([value isKindOfClass:[NSNumber class]]) return value;
    if ([value isKindOfClass:[NSString class]]) {
        // 如果是字符串类型
        
        // 硬编码解析
        NSNumber *number = dict[value];
        if (number) {
            if (number == (id)kCFNull) return nil;
            return number;
        }
        if ([(NSString *)value rangeOfCharacterFromSet:dot].location != NSNotFound) {
            // 包含小数点
            const char *cstring = ((NSString *)value).UTF8String;
            if (!cstring) return nil;
            // 将字符串转化为double类型
            double num = atof(cstring);
            if (isnan(num) || isinf(num)) return nil;
            return @(num);
        } else {
            // 不包含小数点
            const char *cstring = ((NSString *)value).UTF8String;
            if (!cstring) return nil;
            // 将字符串转化为long long类型
            return @(atoll(cstring));
        }
    }
    
    return nil;
}

@end

@implementation NSArray (YPModel)

+ (NSArray *)yp_modelArrayWithClass:(Class)cls json:(id)json
{
    if (!json || !cls) return nil;
    NSArray *arr = nil;
    NSData *jsonData = nil;
    if ([json isKindOfClass:[NSArray class]]) {
        arr = json;
    } else if ([json isKindOfClass:[NSString class]]) {
        jsonData = [(NSString *)json dataUsingEncoding:NSUTF8StringEncoding];
    } else if ([json isKindOfClass:[NSData class]]) {
        jsonData = json;
    }
    if (jsonData) {
        arr = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:NULL];
        if (![arr isKindOfClass:[NSArray class]]) arr = nil;
    }
    if (!arr) return nil;
    NSMutableArray *modelArr = [NSMutableArray new];
    for (NSDictionary *dict in modelArr) {
        if (![dict isKindOfClass:[NSDictionary class]]) continue;
        
        id obj = [cls yp_modelWithDict:dict];
        
        if (obj) [modelArr addObject:obj];
    }
    return modelArr;
}

@end




































