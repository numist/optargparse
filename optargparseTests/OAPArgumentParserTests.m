//
//  OAPArgumentParserTests.m
//  optargparse
//
//  Created by Scott Perry on 2/21/17.
//  Copyright © 2017 Scott Perry. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OAPArgumentParser.h"

@interface OAPArgumentParserTests : XCTestCase

@end

@implementation OAPArgumentParserTests

- (void)testNoOptions {
    OAPArgumentParser *parser = [OAPArgumentParser argumentParserWithArguments:@[@"--", @"foo"]];
    XCTAssertTrue([parser parseOptions:[NSSet set] error:nil handler:^(NSString *name, NSString *value, NSError **error) {
        XCTFail(@"Parser should not have reported any options");
        *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:nil];
    }]);
    XCTAssertEqualObjects(parser.arguments[parser.argumentOffset], @"foo");
}

- (void)testInvalidOptionTrailingHyphen {
    OAPArgumentParser *parser = [OAPArgumentParser argumentParserWithArguments:@[@"--", @"foo"]];
    XCTAssertThrows([parser parseOptions:[NSSet setWithObject:@"foo-"] error:nil handler:^(NSString *name, NSString *value, NSError **error) {
        XCTFail(@"Parser should not have reported any options");
    }]);
}

- (void)testInvalidOptionArgAndNonArgIntroducingAmbiguity {
    OAPArgumentParser *parser = [OAPArgumentParser argumentParserWithArguments:@[@"--", @"foo"]];
    
    XCTAssertThrows([parser parseOptions:[NSSet setWithArray:(@[@"--foo", @"--foo:"])] error:nil handler:^(NSString *name, NSString *value, NSError **error) {
        XCTFail(@"Parser should not have reported any options");
        *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:nil];
    }]);
}

- (void)testInvalidOptionSnowman {
    OAPArgumentParser *parser = [OAPArgumentParser argumentParserWithArguments:@[@"--", @"foo"]];
    
    XCTAssertThrows([parser parseOptions:[NSSet setWithObject:@"☃"] error:nil handler:^(NSString *name, NSString *value, NSError **error) {
        XCTFail(@"Parser should not have reported any options");
    }]);
}

- (void)testInvalidOptionEmptyString {
    OAPArgumentParser *parser = [OAPArgumentParser argumentParserWithArguments:@[@"--", @"foo"]];
    
    XCTAssertThrows([parser parseOptions:[NSSet setWithObject:@""] error:nil handler:^(NSString *name, NSString *value, NSError **error) {
        XCTFail(@"Parser should not have reported any options");
    }]);
}

- (void)testInvalidOption {
    OAPArgumentParser *parser = [OAPArgumentParser argumentParserWithArguments:@[@"--foo"]];
    XCTAssertFalse([parser parseOptions:[NSSet set] error:nil handler:^(NSString *name, NSString *value, NSError **error) {
        XCTFail(@"Parser should not have reported any options");
    }]);
}

- (void)testUserErrorGetsPropagated {
    NSError *myError = [NSError errorWithDomain:@"" code:-4 userInfo:nil];
    NSError *theirError = nil;
    NSString *myOptionName = @"--foo";
    
    OAPArgumentParser *parser = [OAPArgumentParser argumentParserWithArguments:@[myOptionName]];
    XCTAssertFalse([parser parseOptions:[NSSet setWithObject:myOptionName] error:&theirError handler:^(NSString *optionName, NSString *value, NSError **error) {
        XCTAssertEqualObjects(myOptionName, optionName);
        XCTAssertNil(value);
        *error = myError;
    }]);
    XCTAssertEqualObjects(myError, theirError);
}

- (void)testArgumentConcatenationTarStyle {
    __block int handlerCalls = 0;
    OAPArgumentParser *parser = [OAPArgumentParser argumentParserWithArguments:@[@"xzvf", @"foo.tar", @"bar.file"]];
    XCTAssertTrue([parser parseOptions:[NSSet setWithArray:(@[@"x", @"z", @"v", @"f:"])] error:nil handler:^(NSString * _Nonnull option, NSString * _Nullable argument, NSError * _Nullable __autoreleasing * _Nullable error) {
        handlerCalls += 1;
    }]);
    XCTAssertEqual(handlerCalls, 4);
}

- (void)testArgumentConcatenationTooFewArguments {
    __block _Bool once = true;
    OAPArgumentParser *parser = [OAPArgumentParser argumentParserWithArguments:@[@"xzfff", @"foo.tar", @"bar.file"]];
    XCTAssertFalse([parser parseOptions:[NSSet setWithArray:(@[@"x", @"z", @"v", @"f:"])] error:nil handler:^(NSString * _Nonnull option, NSString * _Nullable argument, NSError * _Nullable __autoreleasing * _Nullable error) {
        if (once) {
            XCTFail(@"There should not be any callbacks when the parser fails");
            once = false;
        }
    }]);
}

- (void)testArgumentConcatenationTarStyleManyValues {
    __block int handlerCalls = 0;
    OAPArgumentParser *parser = [OAPArgumentParser argumentParserWithArguments:@[@"-xzvf", @"foo.tar", @"bar.file", @"qux.file"]];
    XCTAssertTrue([parser parseOptions:[NSSet setWithArray:(@[@"-x:", @"-z:", @"-v", @"-f:"])] error:nil handler:^(NSString * _Nonnull option, NSString * _Nullable argument, NSError * _Nullable __autoreleasing * _Nullable error) {
        handlerCalls += 1;
        if ([option isEqualToString:@"-x"]) {
            XCTAssertEqualObjects(argument, @"foo.tar");
        } else if ([option isEqualToString:@"-z"]) {
            XCTAssertEqualObjects(argument, @"bar.file");
        } else if ([option isEqualToString:@"-v"]) {
            
        } else if ([option isEqualToString:@"-f"]) {
            XCTAssertEqualObjects(argument, @"qux.file");
        } else {
            XCTFail(@"Unrecognized option/argument pair: %@ = %@", option, argument);
        }
    }]);
    XCTAssertEqual(handlerCalls, 4);
}

- (void)testArgumentConcatenationLsStyle {
    __block int handlerCalls = 0;
    OAPArgumentParser *parser = [OAPArgumentParser argumentParserWithArguments:@[@"-lh1@", @"foo.tar", @"bar.file"]];
    XCTAssertTrue([parser parseOptions:[NSSet setWithArray:(@[@"-l", @"-h", @"-1", @"-@"])] error:nil handler:^(NSString * _Nonnull option, NSString * _Nullable argument, NSError * _Nullable __autoreleasing * _Nullable error) {
        handlerCalls += 1;
    }]);
    XCTAssertEqual(handlerCalls, 4);
}

- (void)testNoCallbacksOnFailure {
    __block _Bool once = true;
    OAPArgumentParser *parser = [OAPArgumentParser argumentParserWithArguments:@[@"--foo", @"--bar"]];
    XCTAssertFalse([parser parseOptions:[NSSet setWithArray:(@[@"--foo"])] error:nil handler:^(NSString * _Nonnull option, NSString * _Nullable argument, NSError * _Nullable __autoreleasing * _Nullable error) {
        if (once) {
            XCTFail(@"There should not be any callbacks when the parser fails");
            once = false;
        }
    }]);
}

- (void)testCorrectFailure {
    NSError *error;
    OAPArgumentParser *parser = [OAPArgumentParser argumentParserWithArguments:@[@"-foo", @"asdf"]];
    XCTAssertFalse([parser parseOptions:[NSSet setWithArray:(@[@"-f:"])] error:&error handler:nil]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, OAPInvalidOptionError);
}

- (void)testOptionPrefixMatching {
    NSError *error;
    OAPArgumentParser *parser = [OAPArgumentParser argumentParserWithArguments:@[@"st"]];
    parser.matchPrefixes = YES;
    // Yes, I'm shaming git's unhelpfulness on purpose.
    XCTAssertTrue([parser parseOptions:[NSSet setWithArray:(@[@"clone", @"init", @"add", @"mv", @"reset", @"rm", @"bisect", @"grep", @"log", @"show", @"status", @"branch", @"checkout", @"commit", @"diff", @"merge", @"rebase", @"tag", @"fetch", @"pull", @"push"])] error:&error handler:^(NSString * _Nonnull option, NSString * _Nullable argument, NSError * _Nullable __autoreleasing * _Nullable error) {
        XCTAssertEqualObjects(option, @"status");
    }]);
}

- (void)testOptionPrefixMatchingParameter {
    NSError *error;
    OAPArgumentParser *parser = [OAPArgumentParser argumentParserWithArguments:@[@"--f=bar"]];
    parser.matchPrefixes = YES;
    XCTAssertThrows([parser parseOptions:[NSSet setWithArray:(@[@"--foo", @"--foo:"])] error:nil handler:nil]);
    XCTAssertTrue([parser parseOptions:[NSSet setWithArray:(@[@"--foo", @"--foo=", @"--bar"])] error:&error handler:^(NSString * _Nonnull option, NSString * _Nullable argument, NSError * _Nullable __autoreleasing * _Nullable error) {
        XCTAssertEqualObjects(option, @"--foo");
        XCTAssertEqualObjects(argument, @"bar");
    }]);
    if (error) {
        NSLog(@"%@", error);
    }
}

- (void)testOptionPrefixMatchingCollision {
    NSError *error;
    OAPArgumentParser *parser = [OAPArgumentParser argumentParserWithArguments:@[@"c"]];
    parser.matchPrefixes = YES;
    // Yes, I'm shaming git's unhelpfulness on purpose.
    XCTAssertFalse([parser parseOptions:[NSSet setWithArray:(@[@"clone", @"init", @"add", @"mv", @"reset", @"rm", @"bisect", @"grep", @"log", @"show", @"status", @"branch", @"checkout", @"commit", @"diff", @"merge", @"rebase", @"tag", @"fetch", @"pull", @"push"])] error:&error handler:nil]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, OAPInvalidOptionError);
}

- (void)testAmbiguousOptions {
    OAPArgumentParser *parser = [OAPArgumentParser argumentParserWithArguments:@[@"--", @"foo"]];
    XCTAssertThrows([parser parseOptions:[NSSet setWithArray:(@[@"-foo", @"-f", @"-o"])] error:nil handler:nil]);
}

- (void)testUnambiguousOptions {
    OAPArgumentParser *parser = [OAPArgumentParser argumentParserWithArguments:@[@"-foo"]];
    XCTAssertNoThrow([parser parseOptions:[NSSet setWithArray:(@[@"foo", @"--foo", @"-f", @"-o"])] error:nil handler:nil]);
    XCTAssertThrows([parser parseOptions:[NSSet setWithArray:(@[@"foo", @"-foo", @"--f", @"--o"])] error:nil handler:nil]);
    XCTAssertNoThrow([parser parseOptions:[NSSet setWithArray:(@[@"-foo", @"--foo", @"f", @"o"])] error:nil handler:nil]);
}

@end
