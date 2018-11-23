//
//  OAPArgumentParserLimitTests.m
//  optargparseTests
//
//  Public domain
//

#import <XCTest/XCTest.h>
#import "OAPArgumentParser.h"

@interface OAPArgumentParserLimitTests : XCTestCase

@end

@implementation OAPArgumentParserLimitTests

- (void)testArgumentLimitConcatenationTarStyle {
    NSError *error;
    __block int handlerCalls = 0;
    OAPArgumentParser *parser = [OAPArgumentParser parserWithArguments:@[@"xzvf", @"foo.tar", @"bar.file"]];
    parser.matchLimit = 1;
    XCTAssertTrue([parser parseOptions:[NSSet setWithArray:(@[@"x", @"z", @"v", @"f:"])] error:&error handler:^(NSString *option, NSString *argument, NSError **outError) {
        handlerCalls += 1;
    }]);
    XCTAssertEqual(handlerCalls, 4);
    XCTAssertNil(error, @"Unexpected error: %@", error);
    XCTAssertEqualObjects(parser.arguments[(NSUInteger)parser.argumentOffset], @"bar.file");
    XCTAssertNil(error);
}

- (void)testArgumentLimitConcatenationTarStyleManyValues {
    NSError *error;
    __block int handlerCalls = 0;
    OAPArgumentParser *parser = [OAPArgumentParser parserWithArguments:@[@"-xzvf", @"foo.tar", @"bar.file", @"qux.file"]];
    parser.matchLimit = 1;
    XCTAssertTrue([parser parseOptions:[NSSet setWithArray:(@[@"-x:", @"-z:", @"-v", @"-f:"])] error:&error handler:^(NSString *option, NSString *argument, NSError **outError) {
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
    XCTAssertNil(error);
}

- (void)testArgumentLimit {
    NSError *error;
    __block int handlerCalls = 0;
    OAPArgumentParser *parser = [OAPArgumentParser parserWithArguments:@[@"-l", @"-h", @"-1", @"@", @"foo.tar", @"bar.file"]];
    parser.matchLimit = 1;
    XCTAssertTrue([parser parseOptions:[NSSet setWithArray:(@[@"-l", @"-h", @"-1", @"-@"])] error:&error handler:^(NSString *option, NSString *argument, NSError **outError) {
        handlerCalls += 1;
    }]);
    XCTAssertEqual(handlerCalls, 1);
    XCTAssertNil(error, @"Unexpected error: %@", error);
    XCTAssertEqualObjects(parser.arguments[(NSUInteger)parser.argumentOffset], @"-h");
    XCTAssertNil(error);
}

- (void)testArgumentLimitWithParameter {
    NSError *error;
    __block int handlerCalls = 0;
    OAPArgumentParser *parser = [OAPArgumentParser parserWithArguments:@[@"-l", @"foo.tar", @"-h", @"-1", @"@", @"bar.file"]];
    parser.matchLimit = 1;
    XCTAssertTrue([parser parseOptions:[NSSet setWithArray:(@[@"-l:", @"-h", @"-1", @"-@"])] error:&error handler:^(NSString *option, NSString *argument, NSError **outError) {
        handlerCalls += 1;
    }]);
    XCTAssertEqual(handlerCalls, 1);
    XCTAssertNil(error, @"Unexpected error: %@", error);
    XCTAssertEqualObjects(parser.arguments[(NSUInteger)parser.argumentOffset], @"-h");
    XCTAssertNil(error);
}

@end
