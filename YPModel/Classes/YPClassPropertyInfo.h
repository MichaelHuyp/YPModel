//
//  YPClassPropertyInfo.h
//  YPModel
//
//  Created by 胡云鹏 on 2016/12/28.
//  Copyright © 2016年 yongche. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/message.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, YPEncodingType) {
    
    YPEncodingTypeMask       = 0xFF,
    YPEncodingTypeUnknown    = 0, ///< unknown 未知类型
    YPEncodingTypeVoid       = 1, ///< void
    YPEncodingTypeBool       = 2, ///< bool 布尔类型
    YPEncodingTypeInt8       = 3, ///< char
    YPEncodingTypeUInt8      = 4, ///< unsigned char
    YPEncodingTypeInt16      = 5, ///< short
    YPEncodingTypeUInt16     = 6, ///< unsigned short
    YPEncodingTypeInt32      = 7, ///< int
    YPEncodingTypeUInt32     = 8, ///< unsigned int
    YPEncodingTypeInt64      = 9, ///< long long 
    YPEncodingTypeUInt64     = 10, ///< unsigned long long
    YPEncodingTypeFloat      = 11, ///< float
    YPEncodingTypeDouble     = 12, ///< double
    YPEncodingTypeLongDouble = 13, ///< long double
    YPEncodingTypeObject     = 14, ///< id
    YPEncodingTypeClass      = 15, ///< Class
    YPEncodingTypeSEL        = 16, ///< SEL
    YPEncodingTypeBlock      = 17, ///< block
    YPEncodingTypePointer    = 18, ///< void*
    YPEncodingTypeStruct     = 19, ///< struct
    YPEncodingTypeUnion      = 20, ///< union
    YPEncodingTypeCString    = 21, ///< char*
    YPEncodingTypeCArray     = 22, ///< char[10] (for example)
    
    
    YPEncodingTypePropertyMask          = 0xFF0000,
    YPEncodingTypePropertyReadonly      = 1 << 16,
    YPEncodingTypePropertyCopy          = 1 << 17,
    YPEncodingTypePropertyRetain        = 1 << 18,
    YPEncodingTypePropertyNonatomic     = 1 << 19,
    YPEncodingTypePropertyWeak          = 1 << 20,
    YPEncodingTypePropertyCustomGetter  = 1 << 21,
    YPEncodingTypePropertyCustomSetter  = 1 << 22,
    YPEncodingTypePropertyDynamic       = 1 << 23,
};


// NSType
typedef NS_ENUM (NSUInteger, YPEncodingNSType) {
    YPEncodingNSTypeUnknown = 0,
    YPEncodingNSTypeNSString,
    YPEncodingNSTypeNSMutableString,
    YPEncodingNSTypeNSValue,
    YPEncodingNSTypeNSNumber,
    YPEncodingNSTypeNSDecimalNumber,
    YPEncodingNSTypeNSData,
    YPEncodingNSTypeNSMutableData,
    YPEncodingNSTypeNSDate,
    YPEncodingNSTypeNSURL,
    YPEncodingNSTypeNSArray,
    YPEncodingNSTypeNSMutableArray,
    YPEncodingNSTypeNSDictionary,
    YPEncodingNSTypeNSMutableDictionary,
    YPEncodingNSTypeNSSet,
    YPEncodingNSTypeNSMutableSet
};


@interface YPClassPropertyInfo : NSObject

/** 属性结构体 */
@property (nonatomic, assign, readonly) objc_property_t property;

/** 属性名 */
@property (nonatomic, copy, readonly) NSString *name;

/** 属性的编码类型 */
@property (nonatomic, assign, readonly) YPEncodingType type;

/** 属性的编码类型字符串 例如@"NSString" */
@property (nonatomic, copy, readonly) NSString *typeEncoding;

/** 属性的实例变量名 */
@property (nonatomic, copy, readonly) NSString *ivarName;

/** getter SEL */
@property (nonatomic, assign, readonly) SEL getter;

/** setter SEL */
@property (nonatomic, assign, readonly) SEL setter;

/** 属性所对应的类 例如 NSString类 可能为空 */
@property (nonatomic, assign, readonly, nullable) Class cls;

/** 属性所遵循的协议数组(可能为空) */
@property (nonatomic, strong, readonly, nullable) NSArray<NSString *> *protocols;

/** 是否为Number类 */
@property (nonatomic, assign, readonly) BOOL isCNumber;

/** 属性的NS类簇类型 */
@property (nonatomic, assign, readonly) YPEncodingNSType nsType;

/**
 根据一个objc_property_t结构体创建一个属性信息类
 */
- (instancetype)initWithProperty:(objc_property_t)property;

@end

NS_ASSUME_NONNULL_END










































