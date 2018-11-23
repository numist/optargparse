//
//  OAPArgumentParserLevenshteinTests.m
//  optargparseTests
//
//  Public domain
//

#import <XCTest/XCTest.h>
#import "OAPArgumentParser.h"

@interface OAPArgumentParserLevenshteinTests : XCTestCase

@end

@implementation OAPArgumentParserLevenshteinTests

- (NSSet *)gitCommands {
    // Yes, I'm shaming git's unhelpfulness on purpose.
    return [NSSet setWithArray:(@[@"add", @"bisect", @"branch", @"checkout", @"clone", @"commit", @"diff", @"fetch", @"grep", @"init", @"log", @"merge", @"mv", @"pop", @"pull", @"push", @"rebase", @"reset", @"rm", @"show", @"status", @"tag"])];
}

- (void)levenshteinShouldMatch:(NSString *)argument with:(NSString *)option {
    NSError *error;
    __block BOOL didMatch = NO;

    OAPArgumentParser *parser = [OAPArgumentParser parserWithArguments:@[argument]];
    parser.fuzzyMatching = YES;
    XCTAssertEqual(-1, parser.argumentOffset);
    XCTAssertTrue([parser parseOptions:[self gitCommands] error:&error handler:^(NSString *optionName, NSString *value, NSError **outError) {
        XCTAssertEqualObjects(optionName, option);
        XCTAssertNil(*outError);
        XCTAssertNil(value);
        didMatch = YES;
    }]);
    XCTAssertTrue(didMatch);
    XCTAssertEqual(1, parser.argumentOffset);
    XCTAssertNil(error);
}

- (void)levenshteinShouldNotMatch:(NSString *)argument {
    NSError *error;

    OAPArgumentParser *parser = [OAPArgumentParser parserWithArguments:@[argument]];
    parser.fuzzyMatching = YES;
    XCTAssertEqual(-1, parser.argumentOffset);
    XCTAssertTrue([parser parseOptions:[[self gitCommands] setByAddingObject:@"checkoot"] error:&error handler:^(NSString *optionName, NSString *value, NSError **outError) {
        XCTFail();
    }]);
    XCTAssertEqual(0, parser.argumentOffset);
    XCTAssertNil(error);
}

- (void)testLevenshteinMatchWithParameter {
    NSError *error;
    __block BOOL didMatch = NO;
    OAPArgumentParser *parser = [OAPArgumentParser parserWithArguments:@[@"--something=flop"]];
    parser.fuzzyMatching = YES;
    XCTAssertTrue([parser parseOptions:[NSSet setWithObject:@"--somethang="] error:&error handler:^(NSString *option, NSString *argument, NSError **outError) {
        XCTAssertEqualObjects(@"--somethang", option);
        XCTAssertEqualObjects(@"flop", argument);
        XCTAssertNotEqual(NULL, outError);
        XCTAssertNil(*outError);
        didMatch = YES;
    }]);
    XCTAssertTrue(didMatch);
    XCTAssertNil(error, @"Unexpected error: %@", error);
    XCTAssertEqual(1, parser.argumentOffset);
    XCTAssertNil(error);
}

- (void)testLevenshteinMatchComit {
    [self levenshteinShouldMatch:@"comit" with:@"commit"];
}

- (void)testLevenshteinMatchCheck {
    [self levenshteinShouldMatch:@"checko" with:@"checkout"];
}

- (void)testLevenshteinMatchDoff {
    [self levenshteinShouldMatch:@"doff" with:@"diff"];
}

- (void)testLevenshteinMatchPoop {
    [self levenshteinShouldMatch:@"poop" with:@"pop"];
}

- (void)testLevenshteinNoMatchCheckoit {
    [self levenshteinShouldNotMatch:@"checkoit"];
}

- (void)testLevenshteinNoMatchLs {
    [self levenshteinShouldNotMatch:@"ls"];
}

@end
