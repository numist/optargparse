//
//  OAPArgumentParserPrefixTests.m
//  optargparseTests
//
//  Created by numist on 2017-07-20.
//  Copyright © 2017 Scott Perry. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OAPArgumentParser.h"

@interface OAPArgumentParserPrefixTests : XCTestCase

@end

@implementation OAPArgumentParserPrefixTests

- (NSSet *)gitCommands {
    // Yes, I'm shaming git's unhelpfulness on purpose.
    return [NSSet setWithArray:(@[@"add", @"bisect", @"branch", @"checkout", @"clone", @"commit", @"diff", @"fetch", @"grep", @"init", @"log", @"merge", @"mv", @"pop", @"pull", @"push", @"rebase", @"reset", @"rm", @"show", @"status", @"tag"])];
}

- (void)testOptionPrefixMatching {
    NSError *error;
    OAPArgumentParser *parser = [OAPArgumentParser parserWithArguments:@[@"st"]];
    parser.matchPrefixes = YES;
    XCTAssertTrue([parser parseOptions:[self gitCommands] error:&error handler:^(NSString *option, NSString *argument, NSError **error) {
        XCTAssertEqualObjects(option, @"status");
    }]);
    XCTAssertNil(error);
    XCTAssertEqual(1, parser.argumentOffset);
}

- (void)testOptionPrefixMatchingEqualsParameter {
    NSError *error;
    OAPArgumentParser *parser = [OAPArgumentParser parserWithArguments:@[@"--f=bar"]];
    parser.matchPrefixes = YES;
    XCTAssertTrue([parser parseOptions:[NSSet setWithArray:(@[@"--foo", @"--foo=", @"--bar"])] error:&error handler:^(NSString *option, NSString *argument, NSError **error) {
        XCTAssertEqualObjects(option, @"--foo");
        XCTAssertEqualObjects(argument, @"bar");
    }]);
    XCTAssertNil(error);
    XCTAssertEqual(1, parser.argumentOffset);
}

- (void)testOptionPrefixMatchingSpaceParameter {
    NSError *error;
    OAPArgumentParser *parser = [OAPArgumentParser parserWithArguments:@[@"--f", @"bar"]];
    parser.matchPrefixes = YES;
    XCTAssertTrue([parser parseOptions:[NSSet setWithArray:(@[@"--foo:"])] error:&error handler:^(NSString *option, NSString *argument, NSError **error) {
        XCTAssertEqualObjects(option, @"--foo");
        XCTAssertEqualObjects(argument, @"bar");
    }]);
    XCTAssertNil(error);
    XCTAssertEqual(2, parser.argumentOffset);
}

- (void)testOptionPrefixNotMatching {
    NSError *error;
    OAPArgumentParser *parser = [OAPArgumentParser parserWithArguments:@[@"statuses"]];
    parser.matchPrefixes = YES;
    XCTAssertTrue([parser parseOptions:[self gitCommands] error:&error handler:^(NSString *option, NSString *argument, NSError **error) {
        XCTFail();
    }]);
    XCTAssertNil(error);
    XCTAssertEqual(0, parser.argumentOffset);
}

@end
