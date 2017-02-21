//
//  OAPArgumentParser.h
//  optargparse
//
//  Public domain
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSErrorDomain const OAPErrorDomain;

typedef NS_ENUM(NSInteger, OAPError) {
    OAPInvalidOptionError,
    OAPUnexpectedArgumentError,
    OAPMissingArgumentError,
};


@interface OAPArgumentParser : NSObject

+ (instancetype)argumentParserWithArguments:(NSArray<NSString *> *)args;

@property (nonatomic, readonly, copy) NSArray<NSString *> *arguments;
@property (nonatomic) NSInteger argumentOffset;

// Whether options should be matched based on unambiguous prefix matching (ie: --fo matches --foo unless --fou is also a possible match)
@property (nonatomic) BOOL matchPrefixes;

- (BOOL)parseOptions:(NSSet<NSString *> *)options error:(NSError **)error handler:(nullable void(^)(NSString *option,  NSString *_Nullable argument, NSError **error))handler;

@end

NS_ASSUME_NONNULL_END
