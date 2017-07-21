//
//  OAPArgumentParser.h
//  optargparse
//
//  Public domain
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Glossary, before things get confusing:
// Option: You define the options that you are willing to accept
// Parameter: Used to provide more information to an option than a simple boolean
// Argument: Tokens from the command line. "ls" "-al" "--foo bar" "--go=far" are all arguments

extern NSErrorDomain const OAPErrorDomain;

typedef NS_ENUM(NSInteger, OAPError) {
    OAPInvalidOptionError,
    OAPUnexpectedArgumentError,
    OAPMissingArgumentError,
};


@interface OAPArgumentParser : NSObject

+ (instancetype)argumentParserWithArguments:(NSArray<NSString *> *)arguments;

- (instancetype)init; // Create an instance using [[NSProcessInfo processInfo] arguments]
- (instancetype)initWithArguments:(NSArray<NSString *> *)args; // Bring your own arguments

@property (nonatomic, readonly, copy) NSArray<NSString *> *arguments;

// Where to begin parsing on the next call to parseOptions:error:handler:
// Negative until the first invocation of parseOptions:error:handler:
@property (nonatomic) NSInteger argumentOffset;

// Whether options should be matched based on unambiguous prefix matching (ie: --fo matches --foo unless --fou is also a possible match)
@property (nonatomic) BOOL matchPrefixes;

// This method calls the handler for each matched option, or sets the error out-parameter. The boolean can be used in the absence of the error parameter to determine success.
// Upon return, the argumentOffset property is advanced to the first unmatched argument, or the count of the arguments parameter if all arguments were consumed by parsing.
- (BOOL)parseOptions:(NSSet<NSString *> *)options error:(NSError **)error handler:(nullable void(^)(NSString *option,  NSString *_Nullable argument, NSError **error))handler;

@end

NS_ASSUME_NONNULL_END
