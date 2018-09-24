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
    NSSet<NSString *> *options = [NSSet setWithArray:(@[@"-cocoa", @"-cabana"])];
    XCTAssertFalse([parser parseOptions:options error:&error handler:^(NSString *option, NSString *argument, NSError **error) {
        XCTFail();
    }]);
    XCTAssertNotNil(error);
    XCTAssertTrue([error.domain isEqualToString:OAPErrorDomain]);
    XCTAssertEqual(error.code, OAPInvalidOptionError);
    XCTAssertTrue([error.userInfo[NSLocalizedDescriptionKey] isEqualToString:@"Parsing options failed: unrecognized option: -c"]);
    XCTAssertTrue([error.userInfo[NSLocalizedFailureReasonErrorKey] isEqualToString:@"Unrecognized option: -c"]);
    if (@available(macOS 10.13, *)) {
        XCTAssertTrue([error.userInfo[NSLocalizedFailureErrorKey] isEqualToString:@"Unrecognized option"]);
    }
    XCTAssertNotNil(error.userInfo[OAPErrorFileKey]);
    XCTAssertNotNil(error.userInfo[OAPErrorLineKey]);
    XCTAssertTrue([error.userInfo[OAPErrorOptionKey] isEqualToString:@"-c"]);
    XCTAssertTrue([error.userInfo[OAPErrorPossibilitiesKey] isEqualToSet:options]);
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
    XCTAssertTrue([error.domain isEqualToString:OAPErrorDomain]);
    XCTAssertEqual(error.code, OAPInvalidOptionError);
    XCTAssertTrue([error.userInfo[NSLocalizedDescriptionKey] isEqualToString:@"Parsing options failed: unrecognized option: --foo"]);
    XCTAssertTrue([error.userInfo[NSLocalizedFailureReasonErrorKey] isEqualToString:@"Unrecognized option: --foo"]);
    if (@available(macOS 10.13, *)) {
        XCTAssertTrue([error.userInfo[NSLocalizedFailureErrorKey] isEqualToString:@"Unrecognized option"]);
    }
    XCTAssertNil(error.userInfo[NSLocalizedRecoverySuggestionErrorKey]);
    XCTAssertNotNil(error.userInfo[OAPErrorFileKey]);
    XCTAssertNotNil(error.userInfo[OAPErrorLineKey]);
    XCTAssertTrue([error.userInfo[OAPErrorOptionKey] isEqualToString:@"--foo"]);
    XCTAssertTrue([error.userInfo[OAPErrorPossibilitiesKey] isEqualToSet:[NSSet set]]);
}

- (void)testInvalidOptionWithLevenshteinMatches {
    NSError *error = nil;
    OAPArgumentParser *parser = [OAPArgumentParser parserWithArguments:@[@"-f"]];
    NSSet<NSString *> *options = [NSSet setWithArray:(@[@"-foabar", @"-fabaod"])];
    XCTAssertFalse([parser parseOptions:options error:&error handler:^(NSString *name, NSString *value, NSError **error) {
        XCTFail(@"Parser should not have reported any options");
    }]);
    XCTAssertNotNil(error);
    XCTAssertTrue([error.domain isEqualToString:OAPErrorDomain]);
    XCTAssertEqual(error.code, OAPInvalidOptionError);
    XCTAssertTrue([error.userInfo[NSLocalizedDescriptionKey] isEqualToString:@"Parsing options failed: unrecognized option: -f"]);
    XCTAssertTrue([error.userInfo[NSLocalizedFailureReasonErrorKey] isEqualToString:@"Unrecognized option: -f"]);
    if (@available(macOS 10.13, *)) {
        XCTAssertTrue([error.userInfo[NSLocalizedFailureErrorKey] isEqualToString:@"Unrecognized option"]);
    }
    XCTAssertNotNil(error.userInfo[OAPErrorFileKey]);
    XCTAssertNotNil(error.userInfo[OAPErrorLineKey]);
    XCTAssertTrue([error.userInfo[OAPErrorOptionKey] isEqualToString:@"-f"]);
    XCTAssertTrue([error.userInfo[OAPErrorPossibilitiesKey] isEqualToSet:options]);
    XCTAssertTrue([error.userInfo[NSLocalizedRecoverySuggestionErrorKey] isEqualToString:@"Valid options: -foabar, -fabaod"]);
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
