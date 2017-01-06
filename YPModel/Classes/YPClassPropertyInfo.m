//
//  YPClassPropertyInfo.m
//  YPModel
//
//  Created by 胡云鹏 on 2016/12/28.
//  Copyright © 2016年 yongche. All rights reserved.
//

#import "YPClassPropertyInfo.h"

YPEncodingType YPEncodingGetType(const char *typeEncoding) {
    char *type = (char *)typeEncoding;
    if (!type) return YPEncodingTypeUnknown;
    size_t len = strlen(type);
    if (len == 0) return YPEncodingTypeUnknown;
    
    switch (*type) {
        case 'c': return YPEncodingTypeInt8;    // A char
        case 'C': return YPEncodingTypeUInt8;   // An unsigned char
        case 'i': return YPEncodingTypeInt32;   // An int
        case 'I': return YPEncodingTypeUInt32;  // An unsigned int
        case 's': return YPEncodingTypeInt16;   // A short
        case 'S': return YPEncodingTypeUInt16;  // An unsigned short
        case 'l': return YPEncodingTypeInt32;   // A long (l is treated as a 32-bit                         quantity on 64-bit programs.) 实际测试 long为'q'
        case 'L': return YPEncodingTypeUInt32;  // An unsigned long 实际测试为Q
        case 'q': return YPEncodingTypeInt64;   // A long long
        case 'Q': return YPEncodingTypeUInt64;  // An unsigned long long
        case 'D': return YPEncodingTypeLongDouble; // 手册上未说明 long double
        case 'f': return YPEncodingTypeFloat;   // A float
        case 'd': return YPEncodingTypeDouble;  // A double
        case 'B': return YPEncodingTypeBool;    // A C++ bool or a C99 _Bool
        case 'v': return YPEncodingTypeVoid;    // A void (这种情况没遇到过)
        case '*': return YPEncodingTypeCString; // A character string (char *)
        case '#': return YPEncodingTypeClass;   // A class object (Class)
        case ':': return YPEncodingTypeSEL;     // A method selector (SEL)
        case '^': return YPEncodingTypePointer; // void *
        case '[': return YPEncodingTypeCArray;  // char[10]
        case '(': return YPEncodingTypeUnion;   // A Union
        case '{': return YPEncodingTypeStruct;  // A Struct
        case '@': {
            if (len == 2 && *(type + 1) == '?') {
                return YPEncodingTypeBlock;
            } else {
                return YPEncodingTypeObject;
            }
        }
        default: return YPEncodingTypeUnknown;
    }
}



@implementation YPClassPropertyInfo


/**
 思考: 给你一个objc_property_t结构体 你能通过它获取哪些信息?
 */
- (instancetype)initWithProperty:(objc_property_t)property
{
    if (!property) return nil;
    self = [super init];
    
    // 1.objc_property_t
    _property = property;
    
    // 2.属性名
    const char *name = property_getName(property);
    if (name) {
        _name = [NSString stringWithUTF8String:name];
    }
    
    // 3.属性的属性列表
    
    // 根据属性的属性列表可以解析属性类型
    YPEncodingType type = 0;
    unsigned int attrCount = 0;
    objc_property_attribute_t *attrs = property_copyAttributeList(property, &attrCount);
    for (unsigned int i = 0; i < attrCount; i++) {
        
        objc_property_attribute_t attr = attrs[i];
        switch (attr.name[0]) {
            case 'T': {
                if (attr.value) {
                    _typeEncoding = [NSString stringWithUTF8String:attr.value];
                }
                type = YPEncodingGetType(attr.value);
                
                if ((type & YPEncodingTypeMask) == YPEncodingTypeObject && _typeEncoding.length) {
                    // 准备提取对象属性的类和遵循的协议
                    NSScanner *scanner = [NSScanner scannerWithString:_typeEncoding];
                    
                    // 扫描编码类型字符串 如果不是以"@\""开头的直接跳过本次循环
                    if (![scanner scanString:@"@\"" intoString:NULL]) continue;
                    
                    NSString *clsName = nil;
                    
                    // 因为上面已经扫描了@\"三个字符所以当前扫描位置为2 也就是从"的下一个字母开始扫描,当扫描到"或<结束扫描. 并将期间扫描过的字符拼接到clsName上.
                    NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"\"<"];
                    if([scanner scanUpToCharactersFromSet:set intoString:&clsName]) {
                        if (clsName.length) _cls = objc_getClass(clsName.UTF8String);
                    }
                    
                    // 获取该对象遵循的协议(很可能遵循了N多个协议)
                    NSMutableArray *protocols = nil;
                    while ([scanner scanString:@"<" intoString:NULL]) {
                        NSString *protocol = nil;
                        if ([scanner scanUpToString:@">" intoString:&protocol]) {
                            if (protocol.length) {
                                if (!protocols) protocols = [NSMutableArray new];
                                [protocols addObject:protocol];
                            }
                            [scanner scanString:@">" intoString:NULL];
                        }
                    }
                    _protocols = protocols;
                }
            } break;
            case 'V': { // 实例变量
                if (attr.value) {
                    _ivarName = [NSString stringWithUTF8String:attr.value];
                }
            } break;
            case 'R': { // Readonly
                type |= YPEncodingTypePropertyReadonly;
            } break;
            case 'C': { // Copy
                type |= YPEncodingTypePropertyCopy;
            } break;
            case '&': { // Retain 或 Strong
                type |= YPEncodingTypePropertyRetain;
            } break;
            case 'N': { // nonatomic
                type |= YPEncodingTypePropertyNonatomic;
            } break;
            case 'D': { // @Dynamic
                type |= YPEncodingTypePropertyDynamic;
            } break;
            case 'W': { // Weak
                type |= YPEncodingTypePropertyWeak;
            } break;
            case 'G': { // Getter
                type |= YPEncodingTypePropertyCustomGetter;
                if (attr.value) { // 有自定义的getter
                    _getter = NSSelectorFromString([NSString stringWithUTF8String:attr.value]);
                }
            } break;
            case 'S': { // Setter
                type |= YPEncodingTypePropertyCustomSetter;
                if (attr.value) { // 有自定义的setter
                    _setter = NSSelectorFromString([NSString stringWithUTF8String:attr.value]);
                }
            }
            default:
                break;
        }
        
    }
    if (attrs) { // 释放资源
        free(attrs);
        attrs = NULL;
    }
    
    // 保存编码类型
    _type = type;
    
    // 判断是否为Number类
    _isCNumber = [self YPEncodingTypeIsCNumber:type];
    
    // 检测其NS类型
    _nsType = [self YPClassGetNSType:_cls];
    
    if (_name.length) {
        if (!_getter) {
            // 能来到这里说明该属性用户没有在属性中设置getter=method,那么就可以以默认形式获取
            _getter = NSSelectorFromString(_name);
        }
        if (!_setter) {
            // 能来到这里说明该属性用户没有在属性中设置setter=method,那么就可以以默认形式获取
            _setter = NSSelectorFromString([NSString stringWithFormat:@"set%@%@:",[_name substringToIndex:1].uppercaseString,[_name substringFromIndex:1]]);
        }
    }
    
    return self;
}

/**
 判断YPEncodingType是否为Number类
 */
- (BOOL)YPEncodingTypeIsCNumber:(YPEncodingType)type {
    switch (type & YPEncodingTypeMask) {
        case YPEncodingTypeBool:
        case YPEncodingTypeInt8:
        case YPEncodingTypeUInt8:
        case YPEncodingTypeInt16:
        case YPEncodingTypeUInt16:
        case YPEncodingTypeInt32:
        case YPEncodingTypeUInt32:
        case YPEncodingTypeInt64:
        case YPEncodingTypeUInt64:
        case YPEncodingTypeFloat:
        case YPEncodingTypeDouble:
        case YPEncodingTypeLongDouble: return YES;
        default: return NO;
    }
}


/**
 根据属性的类型检测其是那种NS类型
 */
- (YPEncodingNSType)YPClassGetNSType:(Class)cls {
    if (!cls) return YPEncodingNSTypeUnknown;
    if ([cls isSubclassOfClass:[NSMutableString class]]) return YPEncodingNSTypeNSMutableString;
    if ([cls isSubclassOfClass:[NSString class]]) return YPEncodingNSTypeNSString;
    if ([cls isSubclassOfClass:[NSDecimalNumber class]]) return YPEncodingNSTypeNSDecimalNumber;
    if ([cls isSubclassOfClass:[NSNumber class]]) return YPEncodingNSTypeNSNumber;
    if ([cls isSubclassOfClass:[NSValue class]]) return YPEncodingNSTypeNSValue;
    if ([cls isSubclassOfClass:[NSMutableData class]]) return YPEncodingNSTypeNSMutableData;
    if ([cls isSubclassOfClass:[NSData class]]) return YPEncodingNSTypeNSData;
    if ([cls isSubclassOfClass:[NSDate class]]) return YPEncodingNSTypeNSDate;
    if ([cls isSubclassOfClass:[NSURL class]]) return YPEncodingNSTypeNSURL;
    if ([cls isSubclassOfClass:[NSMutableArray class]]) return YPEncodingNSTypeNSMutableArray;
    if ([cls isSubclassOfClass:[NSArray class]]) return YPEncodingNSTypeNSArray;
    if ([cls isSubclassOfClass:[NSMutableDictionary class]]) return YPEncodingNSTypeNSMutableDictionary;
    if ([cls isSubclassOfClass:[NSDictionary class]]) return YPEncodingNSTypeNSDictionary;
    if ([cls isSubclassOfClass:[NSMutableSet class]]) return YPEncodingNSTypeNSMutableSet;
    if ([cls isSubclassOfClass:[NSSet class]]) return YPEncodingNSTypeNSSet;
    return YPEncodingNSTypeUnknown;
}

@end


















































