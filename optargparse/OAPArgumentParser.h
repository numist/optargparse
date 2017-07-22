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
    OAPUnexpectedParameterError,
    OAPMissingParameterError,
#warning add a user-defined error type
};


@interface OAPArgumentParser : NSObject

#warning rename this to be shorter
+ (instancetype)parserWithArguments:(NSArray<NSString *> *)arguments;

- (instancetype)init; // Create an instance using [[NSProcessInfo processInfo] arguments]
- (instancetype)initWithArguments:(NSArray<NSString *> *)args; // Bring your own arguments

@property (nonatomic, readonly, copy) NSArray<NSString *> *arguments;

// Where to begin parsing on the next call to parseOptions:error:handler:
// Negative until the first invocation of parseOptions:error:handler:
@property (nonatomic) NSInteger argumentOffset;

// The number of matches to process before exiting. 0 for all (default).
@property (nonatomic) NSUInteger matchLimit;

// matchPrefixes and fuzzyMatching control imprecise matching of arguments.
// These properties are disabled when the session is not interactive.

// Whether options should be matched based on unambiguous prefix matching (ie: --fo matches --foo unless --fou is also a possible match)
@property (nonatomic) BOOL matchPrefixes;
// Whether options should be matched based on levenshtein distance (ie: --comit matches --commit unless --comnit is also a possible match)
@property (nonatomic) BOOL fuzzyMatching;

// This method calls the handler for each matched option, or sets the error out-parameter. The boolean can be used in the absence of the error parameter to determine success.
// Upon return, the argumentOffset property is advanced to the first unmatched argument, or the count of the arguments parameter if all arguments were consumed by parsing.
- (BOOL)parseOptions:(NSSet<NSString *> *)options error:(NSError **)error handler:(nullable void(^)(NSString *option,  NSString *_Nullable argument, NSError **error))handler;

@end

NS_ASSUME_NONNULL_END
