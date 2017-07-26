//
//  OAPArguentParserErrorTests.m
//  optargparseTests
//
//  Public domain
//

#import <XCTest/XCTest.h>
#import "OAPArgumentParser.h"

@interface OAPArguentParserErrorTests : XCTestCase

@end

@implementation OAPArguentParserErrorTests

- (void)testCorrectFailure {
    NSError *error;
    OAPArgumentParser *parser = [OAPArgumentParser parserWithArguments:@[@"-foo", @"asdf"]];
    XCTAssertFalse([parser parseOptions:[NSSet setWithArray:(@[@"-f:"])] error:&error handler:nil]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, OAPInvalidOptionError);
}

- (void)testOptionPrefixMatchingCollision {
    NSError *error;
    OAPArgumentParser *parser = [OAPArgumentParser parserWithArguments:@[@"-c"]];
    parser.matchPrefixes = YES;
    XCTAssertFalse([parser parseOptions:[NSSet setWithArray:(@[@"-cocoa", @"-cabana"])] error:&error handler:^(NSString *option, NSString *argument, NSError **error) {
        XCTFail();
    }]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, OAPInvalidOptionError);
}

- (void)testInvalidColonSuffixArgument {
    NSError *error = nil;
    OAPArgumentParser *parser = [OAPArgumentParser parserWithArguments:@[@"--foo:"]];
    XCTAssertFalse([parser parseOptions:[NSSet setWithArray:(@[@"--foo"])] error:&error handler:^(NSString *option, NSString *argument, NSError **error) {
        XCTFail();
    }]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, OAPInvalidOptionError);
}

- (void)testInvalidOption {
    NSError *error = nil;
    OAPArgumentParser *parser = [OAPArgumentParser parserWithArguments:@[@"--foo"]];
    XCTAssertFalse([parser parseOptions:[NSSet set] error:&error handler:^(NSString *name, NSString *value, NSError **error) {
        XCTFail(@"Parser should not have reported any options");
    }]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, OAPInvalidOptionError);
}

- (void)testArgumentConcatenationTooFewArguments {
    NSError *error;
    OAPArgumentParser *parser = [OAPArgumentParser parserWithArguments:@[@"xzfff", @"foo.tar", @"bar.file"]];
    XCTAssertFalse([parser parseOptions:[NSSet setWithArray:(@[@"x", @"z", @"v", @"f:"])] error:&error handler:^(NSString *option, NSString *argument, NSError **error) {
        XCTFail(@"There should not be any callbacks when the parser fails");
    }]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, OAPMissingParameterError);
}

- (void)testNoCallbacksOnFailure {
    NSError *error;
    OAPArgumentParser *parser = [OAPArgumentParser parserWithArguments:@[@"--foo", @"--bar"]];
    XCTAssertFalse([parser parseOptions:[NSSet setWithArray:(@[@"--foo"])] error:&error handler:^(NSString *option, NSString *argument, NSError **error) {
        XCTFail(@"There should not be any callbacks when the parser fails");
    }]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, OAPInvalidOptionError);
}

- (void)testNoParamOptionFailsWithEquals {
    NSError *error;
    OAPArgumentParser *parser = [OAPArgumentParser parserWithArguments:@[@"--foo=bar"]];
    XCTAssertFalse([parser parseOptions:[NSSet setWithArray:(@[@"--foo"])] error:&error handler:^(NSString *option, NSString *argument, NSError **error) {
        XCTFail(@"There should not be any callbacks when the parser fails");
    }]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, OAPUnexpectedParameterError);
}

- (void)testSpaceParamOptionFailsWithEquals {
    NSError *error;
    OAPArgumentParser *parser = [OAPArgumentParser parserWithArguments:@[@"--foo=bar"]];
    XCTAssertFalse([parser parseOptions:[NSSet setWithArray:(@[@"--foo:"])] error:&error handler:^(NSString *option, NSString *argument, NSError **error) {
        XCTFail(@"There should not be any callbacks when the parser fails");
    }]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, OAPUnexpectedParameterError);
}

@end
