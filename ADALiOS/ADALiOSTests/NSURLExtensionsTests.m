// Created by Boris Vidolov on 1/27/14.
// Copyright © Microsoft Open Technologies, Inc.
//
// All Rights Reserved
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// THIS CODE IS PROVIDED *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS
// OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
// ANY IMPLIED WARRANTIES OR CONDITIONS OF TITLE, FITNESS FOR A
// PARTICULAR PURPOSE, MERCHANTABILITY OR NON-INFRINGEMENT.
//
// See the Apache License, Version 2.0 for the specific language
// governing permissions and limitations under the License.
#import <XCTest/XCTest.h>
#import "../ADALiOS/NSURLExtensions.h"

@interface NSURLExtensionsTests : XCTestCase

@end

@implementation NSURLExtensionsTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

//tests the fragment extraction. Does not test any other URL logic,
//which should have been handled by the NSURL class
-(void) testFragmentParameters
{
    //Missing or invalid fragment:
    XCTAssertNil(((NSURL*)[NSURL URLWithString:@"https://stuff.com"]).fragmentParameters);
    XCTAssertNil(((NSURL*)[NSURL URLWithString:@"https://stuff.com?foo=bar"]).fragmentParameters);
    XCTAssertNil(((NSURL*)[NSURL URLWithString:@"https://stuff.com#bar=foo#"]).fragmentParameters);
    XCTAssertNil(((NSURL*)[NSURL URLWithString:@"https://stuff.com?foo=bar#bar=foo#foo=bar"]).fragmentParameters);
    XCTAssertNil(((NSURL*)[NSURL URLWithString:@"https://stuff.com?foo=bar#bar=foo#foo=bar#"]).fragmentParameters);
    XCTAssertNil(((NSURL*)[NSURL URLWithString:@"https://stuff.com?foo=bar#        "]).fragmentParameters);
    
    //Valid fragment, but missing/invalid parameters:
    NSDictionary* empty = [NSDictionary new];
    XCTAssertEqualObjects(empty, ((NSURL*)[NSURL URLWithString:@"https://stuff.com#bar"]).fragmentParameters);
    XCTAssertEqualObjects(empty, ((NSURL*)[NSURL URLWithString:@"https://stuff.com?foo=bar#bar"]).fragmentParameters);
    XCTAssertEqualObjects(empty, ((NSURL*)[NSURL URLWithString:@"https://stuff.com?foo=bar#bar=foo=bar"]).fragmentParameters);
    
    //At least some of the parameters are valid:
    NSDictionary* simple = @{@"foo1":@"bar1", @"foo2":@"bar2"};
    XCTAssertEqualObjects(simple, ((NSURL*)[NSURL URLWithString:@"https://stuff.com?foo=bar#foo1=bar1&foo2=bar2"]).fragmentParameters);
    XCTAssertEqualObjects(simple, ((NSURL*)[NSURL URLWithString:@"https://stuff.com?foo=bar#foo1=bar1&foo2=bar2&foo2=bar2"]).fragmentParameters);
    XCTAssertEqualObjects(simple, ((NSURL*)[NSURL URLWithString:@"https://stuff.com?foo=bar#foo1=bar1&foo2=bar2&&&"]).fragmentParameters);
    XCTAssertEqualObjects(simple, ((NSURL*)[NSURL URLWithString:@"https://stuff.com?foo=bar#foo1=bar1&foo2=bar2&foo3=bar3=foo3"]).fragmentParameters);
}

//As both fragment and query parameters are extracted
//with the same helper method, for query parameters we have only basic tests:
-(void) testQueryParameters
{
    //Negative:
    XCTAssertNil(((NSURL*)[NSURL URLWithString:@"https://stuff.com"]).queryParameters);
    
    //Positive:
    NSDictionary* simple = @{@"foo1":@"bar1", @"foo2":@"bar2"};
    XCTAssertEqualObjects(simple, ((NSURL*)[NSURL URLWithString:@"https://stuff.com?foo1=bar1&foo2=bar2"]).queryParameters);
    
    //Mixed query and fragment parameters:
    XCTAssertEqualObjects(simple, ((NSURL*)[NSURL URLWithString:@"https://stuff.com?foo1=bar1&foo2=bar2#foo3=bar3"]).queryParameters);
}

@end
