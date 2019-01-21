//
//  OAPArgumentParser.m
//  optargparse
//
//  Public domain
//

#import "OAPArgumentParser.h"
#import <Foundation/Foundation.h>

NSErrorDomain const OAPErrorDomain = @"OAPErrorDomain";
NSString * const OAPErrorOptionKey = @"option";
NSString * const OAPErrorPossibilitiesKey = @"possibilities";
NSString * const OAPErrorParameterKey = @"parameter";
NSString * const OAPErrorFileKey = @"file";
NSString * const OAPErrorLineKey = @"line";

@interface __OAPCallbackList : NSObject
- (NSUInteger)count;
- (void)addCallbackWithName:(NSString *)name value:(NSString *)value;
- (NSError *)deliverCallbacksToHandler:(void(^)(NSString *option,  NSString *_Nullable argument, NSError **error))handler;
@end
NSString * const __OAPCallbackListOptionNameKey = @"__OAPCallbackListOptionNameKey";
NSString * const __OAPCallbackListOptionValueKey = @"__OAPCallbackListOptionValueKey";
@interface __OAPCallbackList () {
    NSMutableArray<NSDictionary<NSString *, NSString *> *> *_callbacks;
}
@end
@implementation __OAPCallbackList
- (instancetype)init {
    if (!(self = [super init])) { return nil; }
    self->_callbacks = [NSMutableArray new];
    return self;
}
- (NSUInteger)count {
    return self->_callbacks.count;
}
- (void)addCallbackWithName:(NSString *)name value:(NSString *)value {
    if (value) {
        [self->_callbacks addObject:@{__OAPCallbackListOptionNameKey: name, __OAPCallbackListOptionValueKey: value}];
    } else {
        [self->_callbacks addObject:@{__OAPCallbackListOptionNameKey: name}];
    }
}
- (NSError *)deliverCallbacksToHandler:(void(^)(NSString *option,  NSString *_Nullable argument, NSError **error))handler {
    if (handler == nil) { return nil; }
    for (NSDictionary<const NSString *, NSString *> *dict in self->_callbacks) {
        NSError *error = nil;
        handler(dict[__OAPCallbackListOptionNameKey], dict[__OAPCallbackListOptionValueKey], &error);
        if (error != nil) {
            return error;
        }
    }
    return nil;
}
@end


@interface OAPArgumentParser ()
@property (nonatomic, assign) BOOL usesProcessArguments;
@end

@implementation OAPArgumentParser
@synthesize matchLimit = _matchLimit;

+ (NSInteger) compare:(NSString *)stringA withString:(NSString *) stringB /*matchGain:(NSInteger)gain missingCost:(NSInteger)cost*/ {
    NSInteger gain = 0;
    NSInteger cost = 1;
    NSInteger k, i, j, change, *d, distance;
    NSInteger n = (NSInteger)[stringA length] + 1;
    NSInteger m = (NSInteger)[stringB length] + 1;
    
    assert(n > 1 && m > 1);

    d = malloc(sizeof(NSInteger) * (unsigned long)m * (unsigned long)n);
    
    for( k = 0; k < n; k++)
        d[k] = k;
    
    for( k = 0; k < m; k++)
        d[ k * n ] = k;
    
    for (i = 1; i < n; i++) {
        for (j = 1; j < m; j++) {
            if ([stringA characterAtIndex:((NSUInteger)i - 1)] == [stringB characterAtIndex:((NSUInteger)j - 1)]) {
                change = -gain;
            } else {
                change = cost;
            }
            
            d[j * n + i] = MIN(d[(j - 1) * n + i] + 1, MIN(d[j * n + i - 1] + 1, d[(j - 1) * n + i - 1] + change));
        }
    }
    
    distance = d[n * m - 1];
    free(d);
    return distance;
}

+ (NSSet<NSString *> *)matchesForParsedOptionName:(NSString *)parsedOptionName withOptions:(NSSet<NSString *> *)options heuristic:(BOOL(^)(NSString *token, NSString *option))heuristic {
    NSMutableSet *result = [NSMutableSet set];
    for (__strong NSString *option in options) {
        option = sanitizedNameForOption(option);
        if (heuristic(parsedOptionName, option)) {
            [result addObject:option];
        }
    }
    return result;
}

#if MAC_OS_X_VERSION_10_13 > 0
+ (NSError *)errorWithDomain:(NSErrorDomain)domain code:(NSInteger)code file:(char *)file line:(int)line userInfo:(nullable NSDictionary<NSErrorUserInfoKey, id> *)dict {
#else
+ (NSError *)errorWithDomain:(NSErrorDomain)domain code:(NSInteger)code file:(char *)file line:(int)line userInfo:(nullable NSDictionary<NSString *, id> *)dict {
#endif //#if MAC_OS_X_VERSION_10_13 > 0
    NSMutableDictionary *userDict = [(dict ? dict : @{}) mutableCopy];

    assert(domain == OAPErrorDomain);

//    NSLocalizedFailureErrorKey               Unrecognized option
//    NSLocalizedFailureReasonErrorKey         Unrecognized option: --option
//    NSLocalizedDescriptionKey                Parsing options failed: unrecognized option: --option
//    NSLocalizedRecoverySuggestionErrorKey    Did you mean --option, --option, or --option?

    NSString *failureError;                  // NSLocalizedFailureErrorKey
    NSString *failureReasonError;            // NSLocalizedFailureReasonErrorKey
    NSString *description;                   // NSLocalizedDescriptionKey
    NSString *recoverySuggestionError = nil; // NSLocalizedRecoverySuggestionErrorKey

    switch (code) {
        case OAPInvalidOptionError:
            failureError = @"Unrecognized option";
            assert(userDict[OAPErrorOptionKey]);
            failureReasonError = [NSString stringWithFormat:@"%@: %@", failureError, userDict[OAPErrorOptionKey]];
            description = [NSString stringWithFormat:@"Parsing options failed: %@",
                           [failureReasonError stringByReplacingCharactersInRange:NSMakeRange(0,1)
                                                                       withString:[[failureReasonError substringToIndex:1] lowercaseString]] ];
            if ([userDict[OAPErrorPossibilitiesKey] count] > 0) {
                recoverySuggestionError = [NSString stringWithFormat:@"Valid options: %@", [[(NSSet *)userDict[OAPErrorPossibilitiesKey] allObjects] componentsJoinedByString:@", "]];
            }
            break;

        case OAPUnexpectedParameterError:
            failureError = @"Unexpected parameter for option";
            assert(userDict[OAPErrorOptionKey]);
            failureReasonError = [NSString stringWithFormat:@"%@: %@", failureError, userDict[OAPErrorOptionKey]];
            description = [NSString stringWithFormat:@"Parsing options failed: %@",
                           [failureReasonError stringByReplacingCharactersInRange:NSMakeRange(0,1)
                                                                       withString:[[failureReasonError substringToIndex:1] lowercaseString]] ];
            break;

        case OAPMissingParameterError:
            failureError = @"Option requires an parameter";
            assert(userDict[OAPErrorOptionKey]);
            failureReasonError = [NSString stringWithFormat:@"%@: %@", failureError, userDict[OAPErrorOptionKey]];
            description = [NSString stringWithFormat:@"Parsing options failed: %@",
                           [failureReasonError stringByReplacingCharactersInRange:NSMakeRange(0,1)
                                                                       withString:[[failureReasonError substringToIndex:1] lowercaseString]] ];
            break;
    }

#if MAC_OS_X_VERSION_10_13 > 0
    if (@available(macOS 10.13, *)) {
        if (!userDict[NSLocalizedFailureErrorKey] && failureError) {
            userDict[NSLocalizedFailureErrorKey] = failureError;
        }
    }
#endif //#if MAC_OS_X_VERSION_10_13 > 0
    if (!userDict[NSLocalizedFailureReasonErrorKey] && failureReasonError) {
        userDict[NSLocalizedFailureReasonErrorKey] = failureReasonError;
    }
    if (!userDict[NSLocalizedDescriptionKey] && description) {
        userDict[NSLocalizedDescriptionKey] = description;
    }
    if (!userDict[NSLocalizedRecoverySuggestionErrorKey] && recoverySuggestionError) {
        userDict[NSLocalizedRecoverySuggestionErrorKey] = recoverySuggestionError;
    }

#ifndef NDEBUG
    assert(file);
    assert(line);
    userDict[OAPErrorFileKey] = @(file);
    userDict[OAPErrorLineKey] = @(line);
#endif

    return [NSError errorWithDomain:domain code:code userInfo:userDict];
}

#pragma mark - Object creation

+ (instancetype)parserWithArguments:(NSArray<NSString *> *)args {
    return [[self alloc] initWithArguments:args];
}

- (instancetype)init {
    if (!(self = [self initWithArguments:[[NSProcessInfo processInfo] arguments]])) { return nil; }
    // [[NSProcessInfo processInfo] arguments] includes the name of the executable as the 0th argument, thus option parsing begins at index 1 by default.
    self.usesProcessArguments = YES;
    return self;
}

- (instancetype)initWithArguments:(NSArray<NSString *> *)args {
    if (!(self = [super init])) { return nil; }
    
    self->_arguments = [args copy];
    self->_argumentOffset = NSUIntegerMax;
    
    return self;
}

#pragma mark - Property definitions

// @property (readonly, copy) NSArray<NSString *> *arguments;
@synthesize arguments = _arguments;
- (NSArray<NSString *> *)arguments {
    return self->_arguments;
}

// @property NSInteger argumentOffset;
@synthesize argumentOffset = _argumentOffset;
@synthesize usesProcessArguments = _usesProcessArguments;

//
// IMPRECISE OPTION MATCHING IS FOR INTERACTIVE SESSIONS ONLY!
//
// Prefix and fuzzy matching is great for human users, but non-interactive
// sessions are forced to precisely match option names. The compatibility risks
// of adding new options when scripts have been allowed to rely on imprecise
// matching boggle the mind.
//

// @property BOOL matchPrefixes;
@synthesize matchPrefixes = _matchPrefixes;
- (void)setMatchPrefixes:(BOOL)matchPrefixes {
    if (matchPrefixes && !isatty(fileno(stdin))) {
        matchPrefixes = NO;
    }
    self->_matchPrefixes = matchPrefixes;
}

// @property BOOL fuzzyMatching;
@synthesize fuzzyMatching = _fuzzyMatching;
- (void)setFuzzyMatching:(BOOL)fuzzyMatching {
    if (fuzzyMatching && !isatty(fileno(stdin))) {
        fuzzyMatching = NO;
    }
    self->_fuzzyMatching = fuzzyMatching;
}

#pragma mark - Parser

static NSString *sanitizedNameForOption(NSString *option) {
    NSString *sanitizedName;
    // @":" and @"=" denote whether a parameter is expected and are not part of the option's name
    if ([option hasSuffix:@":"]) {
        sanitizedName = [option substringToIndex:(option.length - 1)];
    } else if ([option hasSuffix:@"="]) {
        sanitizedName = [option substringToIndex:(option.length - 1)];
    } else {
        sanitizedName = option;
    }
    return sanitizedName;
}

static void optionValidator(OAPArgumentParser *self, NSSet<NSString *> *options) {
    __attribute__((unused)) SEL _cmd = (SEL)"optionValidator:";

    if ([options containsObject:@""]) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Empty string is not a valid option name" userInfo:nil];
    }

    // Input sanity checking
    NSCharacterSet *argSet = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz0123456789-@"];
    NSCharacterSet *hyphenSet = [NSCharacterSet characterSetWithCharactersInString:@"-"];
    NSMutableCharacterSet *singleCharOptionSet = [NSMutableCharacterSet new];
    NSMutableCharacterSet *hyphenSingleCharOptionSet = [NSMutableCharacterSet new];

    for (NSString *name in options) {
        NSString *sanitizedName = sanitizedNameForOption(name);
        // @":" and @"=" denote whether a parameter is expected and are not part of the option's name
        if ([name hasSuffix:@":"] && [options containsObject:sanitizedName]) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Option combination introduces parsing ambiguity" userInfo:@{@"names" : @[name, sanitizedName]}];
        }
        
        if ([sanitizedName hasPrefix:@"--"] && sanitizedName.length == 3) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Single-character options with two leading hyphens are not supported" userInfo:@{@"name" : name}];
        }
        
        if (![[sanitizedName stringByTrimmingCharactersInSet:argSet] isEqualToString:@""]) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Invalid characters in option name" userInfo:@{@"name" : name, @"invalid" : [name stringByTrimmingCharactersInSet:argSet]}];
        }
        
        if ([sanitizedName hasPrefix:@"---"]) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Options with more than two leading hyphens are not supported" userInfo:@{@"name" : name}];
        }
        if ([sanitizedName hasSuffix:@"-"]) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Options with trailing hyphens are not supported" userInfo:@{@"name" : name}];
        }
        
        // Populate the character sets used to detect parsing ambiguity between short and long options
        NSString *bareName = [sanitizedName stringByTrimmingCharactersInSet:hyphenSet];
        if (bareName.length == 1) {
            if ([sanitizedName hasPrefix:@"-"]) {
                [hyphenSingleCharOptionSet addCharactersInString:bareName];
            } else {
                [singleCharOptionSet addCharactersInString:bareName];
            }
        }
    }
    for (__strong NSString *name in options) {
        if ([name hasPrefix:@"-"]) {
            name = [name substringFromIndex:1];
            if (name.length == 1) { continue; }
            if ([[name stringByTrimmingCharactersInSet:hyphenSingleCharOptionSet] isEqualToString:@""]) {
                @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Parsing ambiguity possible with options; long option names can be composed using short option names" userInfo:nil];
            }
        } else {
            if (name.length == 1) { continue; }
            if ([[name stringByTrimmingCharactersInSet:singleCharOptionSet] isEqualToString:@""]) {
                @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Parsing ambiguity possible with options; long option names can be composed using short option names" userInfo:nil];
            }
        }
    }
}

- (BOOL)parseOptions:(NSSet<NSString *> *)options error:(NSError * _Nullable __autoreleasing * _Nullable)pError handler:(void(^)(NSString *option,  NSString * _Nullable parameter, NSError * _Nullable __autoreleasing * _Nullable error))handler {
    __block NSError *error = nil;
    __OAPCallbackList *callbacks = [__OAPCallbackList new];
    
    if (self->_arguments.count == 0) {
        self->_argumentOffset = 0;
        return YES;
    }
    
    if (self->_argumentOffset == NSUIntegerMax) {
        self->_argumentOffset = self->_usesProcessArguments ? 1 : 0;
    }
    
    optionValidator(self, options);
    
    __block NSUInteger argumentOffset = self->_argumentOffset;
    __block NSArray<NSString *> *arguments = self->_arguments;

    //
    // Token parser
    //
    _Bool (^parseToken)(NSString *) = ^(NSString *token) {
        // Parse token into name and value strings
        NSString *parsedOptionName = token;
        NSString *value = nil;
        if ([token containsString:@"="]) {
            NSArray *split = [token componentsSeparatedByString:@"="];
            parsedOptionName = split[0];
            value = [token substringFromIndex:(parsedOptionName.length + 1)];
        }
        
        // @":" is a valid flag for option definitions, but is not a valid character in the option name.
        if ([token hasSuffix:@":"]) {
            error = [[self class] errorWithDomain:OAPErrorDomain
                                             code:OAPInvalidOptionError
                                             file:__FILE__
                                             line:__LINE__
                                         userInfo:@{ OAPErrorOptionKey: token }];
            return (_Bool)false;
        }
        
        NSString *equalSuffixedOptionName = [parsedOptionName stringByAppendingString:@"="];
        NSString *colonSuffixedOptionName = [parsedOptionName stringByAppendingString:@":"];
        
        // name=
        if ([options containsObject:equalSuffixedOptionName]) {
            if (value == nil) {
                error = [[self class] errorWithDomain:OAPErrorDomain
                                                 code:OAPMissingParameterError
                                                 file:__FILE__
                                                 line:__LINE__
                                             userInfo:@{ OAPErrorOptionKey: parsedOptionName }];
                return (_Bool)false;
            }
            
            [callbacks addCallbackWithName:parsedOptionName value:value];
            argumentOffset += 1;
            return (_Bool)true;
        }
        
        // name
        if ([options containsObject:parsedOptionName]) {
            if (value != nil) {
                error = [[self class] errorWithDomain:OAPErrorDomain
                                                 code:OAPUnexpectedParameterError
                                                 file:__FILE__
                                                 line:__LINE__
                                             userInfo:@{ OAPErrorOptionKey: parsedOptionName }];
                return (_Bool)false;
            }
            
            [callbacks addCallbackWithName:parsedOptionName value:nil];
            argumentOffset += 1;
            return (_Bool)true;
        }
        
        // name:
        if ([options containsObject:colonSuffixedOptionName]) {
            if (value != nil) {
                error = [[self class] errorWithDomain:OAPErrorDomain
                                                 code:OAPUnexpectedParameterError
                                                 file:__FILE__
                                                 line:__LINE__
                                             userInfo:@{ OAPErrorOptionKey: parsedOptionName }];
                return (_Bool)false;
            }
            
            if (argumentOffset + 1 >= arguments.count) {
                error = [[self class] errorWithDomain:OAPErrorDomain
                                                 code:OAPMissingParameterError
                                                 file:__FILE__
                                                 line:__LINE__
                                             userInfo:@{ OAPErrorOptionKey: parsedOptionName }];
                return (_Bool)false;
            }
            
            argumentOffset += 1; // account for the consumed token used as this option's argument.
            [callbacks addCallbackWithName:parsedOptionName value:arguments[argumentOffset]];
            argumentOffset += 1;
            return (_Bool)true;
        }
        
        return (_Bool)false;
    };

    while (argumentOffset < arguments.count && error == nil) {
        if (self->_matchLimit > 0 && callbacks.count >= self->_matchLimit) {
            break;
        }

        NSString *token = arguments[argumentOffset];
        
        //
        // Parsing arguments always ends on a loose @"--" token
        //
        if ([token isEqual:@"--"]) {
            argumentOffset += 1;
            break;
        }

        if (parseToken(token)) {
            continue;
        } else if (error != nil) {
            break;
        }
        
        //
        // Concatenated single-char options
        //
        const NSUInteger prevArgumentOffset = argumentOffset;
        _Bool hasHyphen = false;
        NSUInteger i;
        for (i = 0; i < token.length; i++) {
            NSString *c = [NSString stringWithFormat:@"%c", [token characterAtIndex:i]];
            if ([c isEqualToString:@"-"]) {
                if (i == 0) {
                    hasHyphen = true;
                    continue;
                } else {
                    break;
                }
            }
            
            if (!parseToken(hasHyphen ? [NSString stringWithFormat:@"-%@", c] : c)) {
                argumentOffset = prevArgumentOffset;
                break;
            }
            argumentOffset -= 1;
        }
        if (i == token.length) {
            NSAssert(error == nil, @"Unexpected error during single-char processing of token");
            argumentOffset += 1;
            continue;
        }
        if (error) {
            break;
        }
        
        //
        // Prefix matching
        //


        // Duped code from parseToken:
        NSString *parsedOptionName = token;
        NSString *value = nil;
        if ([token containsString:@"="]) {
            NSArray *split = [token componentsSeparatedByString:@"="];
            parsedOptionName = split[0];
            value = [token substringFromIndex:(parsedOptionName.length + 1)];
        }
        // End of duped code

        //
        // Fuzzy matching!
        //
        NSString *fuzzyMatch = nil;

        //
        // Prefix matching
        //
        NSSet<NSString *> *prefixMatches = [[self class] matchesForParsedOptionName:parsedOptionName withOptions:options heuristic:^BOOL(NSString *aToken, NSString *option) {
            return [option hasPrefix:aToken];
        }];
        if (self->_matchPrefixes && prefixMatches.count == 1) {
            fuzzyMatch = sanitizedNameForOption([prefixMatches anyObject]);
            if (value != nil) {
                // Expand the prefix using the complete option name
                fuzzyMatch = [fuzzyMatch stringByAppendingFormat:@"=%@", value];
            }
        }

        //
        // Levenshtein matching
        //
        NSSet<NSString *> *levenshteinMatches = [[self class] matchesForParsedOptionName:parsedOptionName withOptions:options heuristic:^BOOL(NSString *aToken, NSString *option) {
            return [[self class] compare:parsedOptionName withString:option] <= (NSInteger)(option.length / 3);
        }];
        if (self->_fuzzyMatching && levenshteinMatches.count == 1) {
            fuzzyMatch = sanitizedNameForOption([levenshteinMatches anyObject]);
            if (value != nil) {
                fuzzyMatch = [fuzzyMatch stringByAppendingFormat:@"=%@", value];
            }
        }

        if (fuzzyMatch) {
            _Bool success = parseToken(fuzzyMatch);
            NSAssert(success == true, @"How?");
            if (error) {
                // Should not be possible
                break;
            }
            if (success) {
                continue;
            }
        }

        //
        // Unrecognized option. Error or break depending on hyphen-prefix
        //
        if ([token hasPrefix:@"-"]) {
            error = [[self class] errorWithDomain:OAPErrorDomain
                                             code:OAPInvalidOptionError
                                             file:__FILE__
                                             line:__LINE__
                                         userInfo:@{
                                                    OAPErrorOptionKey: token,
                                                    OAPErrorPossibilitiesKey: [prefixMatches setByAddingObjectsFromSet:levenshteinMatches]
                                                  }];
        }
        break;
    }
    
    if (error == nil) {
        error = [callbacks deliverCallbacksToHandler:handler];
    }
    
    if (error != nil) {
        if (pError) {
            *pError = error;
        }
        return NO;
    }

    self.argumentOffset = argumentOffset;
    return YES;
}

@end
