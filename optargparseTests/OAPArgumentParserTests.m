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

- (void)testUnambiguousOptions {
    OAPArgumentParser *parser = [OAPArgumentParser argumentParserWithArguments:@[@"-foo"]];
    XCTAssertNoThrow([parser parseOptions:[NSSet setWithArray:(@[@"foo", @"--foo", @"-f", @"-o"])] error:nil handler:nil]);
    XCTAssertNoThrow([parser parseOptions:[NSSet setWithArray:(@[@"-foo", @"--foo", @"f", @"o"])] error:nil handler:nil]);
}

- (void)testNoOptions {
    NSError *error;
    OAPArgumentParser *parser = [OAPArgumentParser argumentParserWithArguments:@[@"--", @"foo"]];
    XCTAssertTrue([parser parseOptions:[NSSet set] error:&error handler:^(NSString *name, NSString *value, NSError **error) {
        XCTFail(@"Parser should not have reported any options");
    }]);
    XCTAssertNil(error, @"Unexpected error: %@", error);
    XCTAssertEqualObjects(parser.arguments[parser.argumentOffset], @"foo");
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
    NSError *error;
    __block int handlerCalls = 0;
    OAPArgumentParser *parser = [OAPArgumentParser argumentParserWithArguments:@[@"xzvf", @"foo.tar", @"bar.file"]];
    XCTAssertTrue([parser parseOptions:[NSSet setWithArray:(@[@"x", @"z", @"v", @"f:"])] error:&error handler:^(NSString *option, NSString *argument, NSError **error) {
        handlerCalls += 1;
    }]);
    XCTAssertEqual(handlerCalls, 4);
    XCTAssertNil(error, @"Unexpected error: %@", error);
    XCTAssertEqualObjects(parser.arguments[parser.argumentOffset], @"bar.file");
}

- (void)testArgumentConcatenationTarStyleManyValues {
    NSError *error;
    __block int handlerCalls = 0;
    OAPArgumentParser *parser = [OAPArgumentParser argumentParserWithArguments:@[@"-xzvf", @"foo.tar", @"bar.file", @"qux.file"]];
    XCTAssertTrue([parser parseOptions:[NSSet setWithArray:(@[@"-x:", @"-z:", @"-v", @"-f:"])] error:&error handler:^(NSString *option, NSString *argument, NSError **error) {
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
    XCTAssertNil(error, @"Unexpected error: %@", error);
    XCTAssertEqual(4, parser.argumentOffset);
}

- (void)testArgumentConcatenationLsStyle {
    NSError *error;
    __block int handlerCalls = 0;
    OAPArgumentParser *parser = [OAPArgumentParser argumentParserWithArguments:@[@"-lh1@", @"foo.tar", @"bar.file"]];
    XCTAssertTrue([parser parseOptions:[NSSet setWithArray:(@[@"-l", @"-h", @"-1", @"-@"])] error:&error handler:^(NSString *option, NSString *argument, NSError **error) {
        handlerCalls += 1;
    }]);
    XCTAssertEqual(handlerCalls, 4);
    XCTAssertNil(error, @"Unexpected error: %@", error);
    XCTAssertEqualObjects(parser.arguments[parser.argumentOffset], @"foo.tar");
}

- (void)testNoArguments {
    NSError *error = nil;
    OAPArgumentParser *parser = [OAPArgumentParser argumentParserWithArguments:@[]];
    XCTAssertTrue([parser parseOptions:[NSSet setWithArray:(@[@"--foo"])] error:&error handler:nil]);
    XCTAssertEqual(0, parser.argumentOffset);
    XCTAssertNil(error, @"Unexpected error: %@", error);
}

@end
