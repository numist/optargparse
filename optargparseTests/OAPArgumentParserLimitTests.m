//
//  OAPArgumentParserLimitTests.m
//  optargparseTests
//
//  Created by numist on 2017-07-21.
//  Copyright © 2017 Scott Perry. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OAPArgumentParser.h"

@interface OAPArgumentParserLimitTests : XCTestCase

@end

@implementation OAPArgumentParserLimitTests

- (void)testArgumentLimitConcatenationTarStyle {
    NSError *error;
    __block int handlerCalls = 0;
    OAPArgumentParser *parser = [OAPArgumentParser argumentParserWithArguments:@[@"xzvf", @"foo.tar", @"bar.file"]];
    parser.matchLimit = 1;
    XCTAssertTrue([parser parseOptions:[NSSet setWithArray:(@[@"x", @"z", @"v", @"f:"])] error:&error handler:^(NSString *option, NSString *argument, NSError **error) {
        handlerCalls += 1;
    }]);
    XCTAssertEqual(handlerCalls, 4);
    XCTAssertNil(error, @"Unexpected error: %@", error);
    XCTAssertEqualObjects(parser.arguments[parser.argumentOffset], @"bar.file");
}

- (void)testArgumentLimitConcatenationTarStyleManyValues {
    NSError *error;
    __block int handlerCalls = 0;
    OAPArgumentParser *parser = [OAPArgumentParser argumentParserWithArguments:@[@"-xzvf", @"foo.tar", @"bar.file", @"qux.file"]];
    parser.matchLimit = 1;
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

- (void)testArgumentLimit {
    NSError *error;
    __block int handlerCalls = 0;
    OAPArgumentParser *parser = [OAPArgumentParser argumentParserWithArguments:@[@"-l", @"-h", @"-1", @"@", @"foo.tar", @"bar.file"]];
    parser.matchLimit = 1;
    XCTAssertTrue([parser parseOptions:[NSSet setWithArray:(@[@"-l", @"-h", @"-1", @"-@"])] error:&error handler:^(NSString *option, NSString *argument, NSError **error) {
        handlerCalls += 1;
    }]);
    XCTAssertEqual(handlerCalls, 1);
    XCTAssertNil(error, @"Unexpected error: %@", error);
    XCTAssertEqualObjects(parser.arguments[parser.argumentOffset], @"-h");
}

- (void)testArgumentLimitWithParameter {
    NSError *error;
    __block int handlerCalls = 0;
    OAPArgumentParser *parser = [OAPArgumentParser argumentParserWithArguments:@[@"-l", @"foo.tar", @"-h", @"-1", @"@", @"bar.file"]];
    parser.matchLimit = 1;
    XCTAssertTrue([parser parseOptions:[NSSet setWithArray:(@[@"-l:", @"-h", @"-1", @"-@"])] error:&error handler:^(NSString *option, NSString *argument, NSError **error) {
        handlerCalls += 1;
    }]);
    XCTAssertEqual(handlerCalls, 1);
    XCTAssertNil(error, @"Unexpected error: %@", error);
    XCTAssertEqualObjects(parser.arguments[parser.argumentOffset], @"-h");
}

@end
