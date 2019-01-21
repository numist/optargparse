//
//  OAPArgumentParserThrowingTests.m
//  optargparseTests
//
//  Public domain
//

#import <XCTest/XCTest.h>
#import "OAPArgumentParser.h"

@interface OAPArgumentParserThrowingTests : XCTestCase

@end

@implementation OAPArgumentParserThrowingTests

- (void)testInvalidOptionTrailingHyphen {
    OAPArgumentParser *parser = [OAPArgumentParser parserWithArguments:@[@"--", @"foo"]];
    XCTAssertThrows([parser parseOptions:[NSSet setWithObject:@"foo-"] error:nil handler:^(NSString *name, NSString *value, NSError **error) {
        XCTFail(@"Parser should not have reported any options");
    }]);
}

- (void)testInvalidOptionArgAndNonArgIntroducingAmbiguity {
    OAPArgumentParser *parser = [OAPArgumentParser parserWithArguments:@[@"--", @"foo"]];

    XCTAssertThrows([parser parseOptions:[NSSet setWithArray:(@[@"--foo", @"--foo:"])] error:nil handler:^(NSString *name, NSString *value, NSError **error) {
        XCTFail(@"Parser should not have reported any options");
        if (error) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:nil];
        }
    }]);
}

- (void)testInvalidOptionSnowman {
    OAPArgumentParser *parser = [OAPArgumentParser parserWithArguments:@[@"--", @"foo"]];

    XCTAssertThrows([parser parseOptions:[NSSet setWithObject:@"☃"] error:nil handler:^(NSString *name, NSString *value, NSError **error) {
        XCTFail(@"Parser should not have reported any options");
    }]);
}

- (void)testInvalidOptionEmptyString {
    OAPArgumentParser *parser = [OAPArgumentParser parserWithArguments:@[@"--", @"foo"]];

    XCTAssertThrows([parser parseOptions:[NSSet setWithObject:@""] error:nil handler:^(NSString *name, NSString *value, NSError **error) {
        XCTFail(@"Parser should not have reported any options");
    }]);
}

- (void)testInvalidOptionThreeHyphens {
    NSError *error;
    OAPArgumentParser *parser = [OAPArgumentParser parserWithArguments:@[@"-foo", @"asdf"]];
    XCTAssertThrows([parser parseOptions:[NSSet setWithArray:(@[@"---f:"])] error:&error handler:nil]);
}

- (void)testAmbiguousOptions {
    OAPArgumentParser *parser = [OAPArgumentParser parserWithArguments:@[@"--", @"foo"]];
    XCTAssertThrows([parser parseOptions:[NSSet setWithArray:(@[@"foo", @"f", @"o"])] error:nil handler:nil]);
}

- (void)testAmbiguousHyphenOptions {
    OAPArgumentParser *parser = [OAPArgumentParser parserWithArguments:@[@"--", @"foo"]];
    XCTAssertThrows([parser parseOptions:[NSSet setWithArray:(@[@"-foo", @"-f", @"-o"])] error:nil handler:nil]);
}

- (void)testSingleCharacterOptionWithTwoHyphens {
    OAPArgumentParser *parser = [OAPArgumentParser parserWithArguments:@[@"--", @"foo"]];
    XCTAssertThrows([parser parseOptions:[NSSet setWithArray:(@[@"foo", @"-foo", @"--f", @"--o"])] error:nil handler:nil]);
}

@end
