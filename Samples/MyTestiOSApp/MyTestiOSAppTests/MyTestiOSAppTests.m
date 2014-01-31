// Created by Boris Vidolov on 9/13/13.
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
#import <ADALiOS/ADAuthenticationContext.h>
#import "BVTestAppDelegate.h"
#import <ADAliOS/ADAuthenticationSettings.h>
#import <ADALiOS/ADLogger.h>
#import "BVTestInstance.h"
#import "BVSettings.h"

//Timeouts in seconds. They are inflated to accumulate cloud-based
//builds on slow VMs:

//May include authority validation:
const int sWebViewDisplayTimeout    = 20;
//The time from loading the webview through multiple redirects until the login page is displayed:
const int sLoginPageDisplayTimeout  = 30;
//Calling the token endpoint and processing the response to extract the token:
const int sTokenWorkflowTimeout     = 20;

@interface MyTestiOSAppTests : XCTestCase
{
    BVSettings* mTestSettings;
}

@end

@implementation MyTestiOSAppTests

-(ADAuthenticationContext*) createContextWithInstance: (BVTestInstance*) instance
                                                 line: (int) line;
{
    XCTAssertNotNil(instance, "Test error");
    ADAuthenticationError* error;
    ADAuthenticationContext* context =
        [ADAuthenticationContext authenticationContextWithAuthority:instance.authority
                                                  validateAuthority:instance.validateAuthority
                                                              error:&error];
    if (!context || error)
    {
        [self recordFailureWithDescription:error.errorDetails inFile:@"" __FILE__ atLine:line expected:NO];
    }
    return context;
}

//Code coverage logic:
#ifdef AD_CODE_COVERAGE
    extern void __gcov_flush(void);
    -(void) flushCodeCoverage
    {
        __gcov_flush();
    }
#else
//No-op:
    -(void) flushCodeCoverage{}
#endif

//Obtains a test AAD instance and credentials:
-(BVTestInstance*) getAADInstance
{
    return mTestSettings.testAuthorities[sAADTestInstance];
}

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class:
    
    [ADLogger setLevel:ADAL_LOG_LEVEL_ERROR];//Meaningful log size
    
    //Start clean:
    [self clearCookies];
    [self clearCache];
    
    //Load test data:
    mTestSettings = [BVSettings new];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [self flushCodeCoverage];
    [super tearDown];
}

//Attempts to find an active webview among all of the application windows.
//The method is not very efficient, but is robust and should suffice for the
//relatively small test app.
-(UIWebView*) findWebView: (UIWindow*) parent
{
    NSArray* windows = (parent) ? [parent subviews] : [[UIApplication sharedApplication] windows];
    for(UIWindow* window in windows)
    {
        if ([window isKindOfClass:[UIWebView class]])
        {
            return (UIWebView*)window;
        }
        else
        {
            UIWebView* result = [self findWebView:window];
            if (result)
            {
                return result;
            }
        }
    }
    return nil;
}

//Clears all cookies:
-(void) clearCookies
{
    NSHTTPCookieStorage* cookiesStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSMutableArray* allCookies = [NSMutableArray arrayWithArray:cookiesStorage.cookies];
    for(NSHTTPCookie* cookie in allCookies)
    {
        [cookiesStorage deleteCookie:cookie];
    }
}

-(void) clearCache
{
    [[ADAuthenticationSettings sharedInstance].defaultTokenCacheStore removeAll];
}

//Runs the run loop in the current thread until the passed condition
//turns YES or timeout is reached
-(void) runLoopWithTimeOut: (int) timeOutSeconds
                 operation: (NSString*) operationDescription
                      line: (int) sourceLine
                 condition: (BOOL (^)(void)) condition
{
    BOOL succeeded = NO;
    NSDate* timeOut = [NSDate dateWithTimeIntervalSinceNow:timeOutSeconds];//In seconds
    NSRunLoop* mainLoop = [NSRunLoop mainRunLoop];
    XCTAssertNotNil(mainLoop);
    
    while ([[NSDate dateWithTimeIntervalSinceNow:0] compare:timeOut] != NSOrderedDescending)
    {
        [mainLoop runMode:NSDefaultRunLoopMode beforeDate:timeOut];//Process one event
        if (condition())
        {
            succeeded = YES;
            break;
        }
    }
    if (!succeeded)
    {
        NSString* error = [NSString stringWithFormat:@"Timeout: %@", operationDescription];
        [self recordFailureWithDescription:error inFile:@"" __FILE__ atLine:sourceLine expected:NO];
    }
}

//Calls the asynchronous acquireTokenWithResource method.
//"interactive" parameter indicates whether the call will display
//UI which user will interact with
-(ADAuthenticationResult*) callAcquireTokenWithInstance: (BVTestInstance*) instance
                                            interactive: (BOOL) interactive
                                           keepSignedIn: (BOOL) keepSignedIn
                                                   line: (int) sourceLine
{
    XCTAssertNotNil(instance, "Internal test failure.");
    
    __block ADAuthenticationResult* localResult;
    ADAuthenticationContext* context = [self createContextWithInstance:instance line:sourceLine];
    
    [context acquireTokenWithResource:instance.resource
                             clientId:instance.clientId
                          redirectUri:[NSURL URLWithString:instance.redirectUri]
                               userId:instance.userId
                      completionBlock:^(ADAuthenticationResult *result)
     {
         localResult = result;
     }];
   
    if (interactive)
    {
        //Automated the webview:
        __block UIWebView* webView;
        [self runLoopWithTimeOut:sWebViewDisplayTimeout operation:@"Wait for web view" line:sourceLine condition:^{
            webView = [self findWebView:nil];
            return (BOOL)(webView != nil);
        }];
        if (!webView)
        {
            return nil;
        }
        
        [self runLoopWithTimeOut:sLoginPageDisplayTimeout operation:@"Wait for the login page" line:sourceLine condition:^{
            if (webView.loading)
            {
                return NO;
            }
            //webview loaded, check if the credentials form is there, else we are still
            //in the initial redirect stages:
            NSString* formLoaded = [webView stringByEvaluatingJavaScriptFromString:
                                    @"document.forms['credentials'] ? '1' : '0'"];
            return [formLoaded isEqualToString:@"1"];
        }];
        
        //Check the username:
        NSString* formUserId = [webView stringByEvaluatingJavaScriptFromString:
                                @"document.getElementById('cred_userid_inputtext').value"];
        XCTAssertTrue([formUserId isEqualToString:instance.userId]);
        
        //Add the password:
        [webView stringByEvaluatingJavaScriptFromString:
                [NSString stringWithFormat:@"document.getElementById('cred_password_inputtext').value = '%@'",
                 instance.password]];
        if (keepSignedIn)
        {
            [webView stringByEvaluatingJavaScriptFromString:
                @"document.getElementById('cred_keep_me_signed_in_checkbox').checked = true"];
        }
        //Submit:
        [webView stringByEvaluatingJavaScriptFromString:
               @"document.forms['credentials'].submit()"];
    
    }
    
    [self runLoopWithTimeOut:sTokenWorkflowTimeout operation:@"Wait for the post-webview calls" line:sourceLine condition:^{
        return (BOOL)(!!localResult);
    }];

    if (AD_SUCCEEDED != localResult.status || localResult.error)
    {
        [self recordFailureWithDescription:localResult.error.errorDetails
                                    inFile:@"" __FILE__
                                    atLine:sourceLine
                                  expected:NO];
    }
    
    if ([NSString isStringNilOrBlank:localResult.tokenCacheStoreItem.accessToken])
    {
        [self recordFailureWithDescription:@"Nil or empty access token."
                                    inFile:@"" __FILE__
                                    atLine:sourceLine
                                  expected:NO];
    }
    
    return localResult;
}

- (void)testInitialAcquireToken
{
    BVTestInstance* instance = [self getAADInstance];
    [self callAcquireTokenWithInstance:instance
                           interactive:YES
                          keepSignedIn:NO
                                  line:__LINE__];
}

-(void) testCache
{
    BVTestInstance* instance = [self getAADInstance];
    [self callAcquireTokenWithInstance:instance
                           interactive:YES
                          keepSignedIn:NO
                                  line:__LINE__];
    
    //Now ensure that the cache is used:
    [self clearCookies];//No cookies, force cache use:
    ADAuthenticationResult* result = [self callAcquireTokenWithInstance:instance
                                                            interactive:NO
                                                           keepSignedIn:YES
                                                                   line:__LINE__];
    
    //Now remove the access token and ensure that the refresh token is leveraged:
    result.tokenCacheStoreItem.accessToken = nil;
    ADAuthenticationError* error;
    [[ADAuthenticationSettings sharedInstance].defaultTokenCacheStore addOrUpdateItem:result.tokenCacheStoreItem error:&error];
    XCTAssertNil(error);
    [self clearCookies];//Just in case
    [self callAcquireTokenWithInstance:instance
                           interactive:NO
                          keepSignedIn:YES
                                  line:__LINE__];
}

-(void) testCookies
{
    BVTestInstance* instance = [self getAADInstance];
    [self callAcquireTokenWithInstance:instance
                           interactive:YES
                          keepSignedIn:YES
                                  line:__LINE__];
    
    //Clear the cache, so that cookies are used:
    [self clearCache];
    [self callAcquireTokenWithInstance:instance
                           interactive:NO
                          keepSignedIn:YES
                                  line:__LINE__];
}

@end
