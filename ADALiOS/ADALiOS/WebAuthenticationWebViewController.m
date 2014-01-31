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

#import "WebAuthenticationDelegate.h"
#import "WebAuthenticationWebViewController.h"
#import "HTTPWebRequest.h"

@implementation WebAuthenticationWebViewController
{
    __weak UIWebView *_webView;
    
    NSURL    *_startURL;
    NSString *_endURL;
    BOOL      _complete;
}

#pragma mark - Initialization

- (id)initWithWebView:(UIWebView *)webView startAtURL:(NSURL *)startURL endAtURL:(NSURL *)endURL
{
    if ( nil == startURL || nil == endURL )
        return nil;
    
    if ( nil == webView )
        return nil;
    
    if ( ( self = [super init] ) != nil )
    {
        _startURL  = [startURL copy];
        _endURL    = [[endURL absoluteString] lowercaseString];
        
        _complete  = NO;
        
        _webView          = webView;
        _webView.delegate = self;
    }
    
    return self;
}

- (void)dealloc
{
    // The WebAuthenticationWebViewController can be released before the
    // UIWebView that it is managing is released in the hosted case and
    // so it is important that to stop listening for events from the
    // UIWebView when we are released.
    _webView.delegate = nil;
    _webView          = nil;
}

#pragma mark - Public Methods

- (void)start
{
    [_webView loadRequest:[NSURLRequest requestWithURL:_startURL]];
}

- (void)stop
{
}

#pragma mark - UIWebViewDelegate Protocol

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
#pragma unused(webView)
#pragma unused(navigationType)
    
    DebugLog( @"URL: %@", request.URL.absoluteString );
    
    // TODO: We lowercase both URLs, is this the right thing to do?
    NSString *requestURL = [[request.URL absoluteString] lowercaseString];
    
    // Stop at the end URL.
    if ( [requestURL hasPrefix:_endURL] )
    {
        // iOS generates a 102, Frame load interrupted error from stopLoading, so we set a flag
        // here to note that it was this code that halted the frame load in order that we can ignore
        // the error when we are notified later.
        _complete = YES;
        
        // Schedule the finish event; we do this so that the web view gets a chance to stop
        // This event is explicitly scheduled on the main thread as it is UI related.
        NSAssert( nil != _delegate, @"Delegate object was lost" );
        dispatch_async( dispatch_get_main_queue(), ^{ [_delegate webAuthenticationDidCompleteWithURL:request.URL]; } );
        
        // Tell the web view that this URL should not be loaded.
        return NO;
    }
    
    // Remember visited URL
    [_visited addObject:request.URL];
    
    if (NO)
    {
        SecIdentityRef identity = NULL;
        SecTrustRef trust       = NULL;
        NSData *PKCS12Data      = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"TestCert" ofType:@"p12"]];
        if (!PKCS12Data)
        {
            AD_LOG_INFO(@"Failed", @"Couldn't read it!");
        }
        else
        {
            [self extractIdentity:&identity andTrust:&trust fromPKCS12Data:PKCS12Data];
        
 //       HTTPWebRequest *webRequest = [[HTTPWebRequest alloc] initWithURL:[NSURL URLWithString:requestURL]];
 //       [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
//        webRequest.method = HTTPPost;
//        [webRequest.headers setObject:@"application/json" forKey:@"Accept"];
//        [webRequest.headers setObject:@"application/x-www-form-urlencoded" forKey:@"Content-Type"];
////
////        webRequest.body = [[request_data URLFormEncode] dataUsingEncoding:NSUTF8StringEncoding];
//        
//        [webRequest send:^( NSError *error, HTTPWebResponse *webResponse ) {
//            // Request completion callback
//            //NSDictionary *response = nil;
//            AD_LOG_INFO(@"Got here", @"Yep");
//        }];
        }
    }
    
    
//    NSURL *serverUrl              = requestURL;
//    ASIHTTPRequest *firstRequest  = [ASIHTTPRequest requestWithURL:serverUrl];
//    
//    [firstRequest setValidatesSecureCertificate:NO];
//    [firstRequest setClientCertificateIdentity:identity];
//    [firstRequest startSynchronous];
    
    return YES;
}

- (BOOL)extractIdentity:(SecIdentityRef *)outIdentity andTrust:(SecTrustRef*)outTrust fromPKCS12Data:(NSData *)inPKCS12Data
{
    OSStatus securityError          = errSecSuccess;
    NSDictionary *optionsDictionary = [NSDictionary dictionaryWithObject:@"~test123" forKey:(__bridge id)kSecImportExportPassphrase];
    
    CFArrayRef items  = CFArrayCreate(NULL, 0, 0, NULL);
    securityError     = SecPKCS12Import((__bridge CFDataRef)inPKCS12Data,(__bridge CFDictionaryRef)optionsDictionary,&items);
    
    if (securityError == 0) {
        CFDictionaryRef myIdentityAndTrust  = CFArrayGetValueAtIndex (items, 0);
        const void *tempIdentity            = NULL;
        
        tempIdentity = CFDictionaryGetValue (myIdentityAndTrust, kSecImportItemIdentity);
        *outIdentity = (SecIdentityRef)tempIdentity;
        
        const void *tempTrust = NULL;
        
        tempTrust = CFDictionaryGetValue (myIdentityAndTrust, kSecImportItemTrust);
        *outTrust = (SecTrustRef)tempTrust;
        
    }
    else {
        NSLog(@"Failed with error code %d",(int)securityError);
        return NO;
    }

    return YES;
}


- (void)webViewDidStartLoad:(UIWebView *)webView
{
#pragma unused(webView)
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
#pragma unused(webView)
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
#pragma unused(webView)
    if (NSURLErrorCancelled == error.code)
    {
        //This is a common error that webview generates and could be ignored.
        //See this thread for details: https://discussions.apple.com/thread/1727260
        return;
    }

    // Ignore failures that are triggered after we have found the end URL
    if ( _complete == YES )
    {
        //We expect to get an error here, as we intentionally fail to navigate to the final redirect URL.
        AD_LOG_VERBOSE(@"Expected error", [error localizedDescription]);
        return;
    }
    
    // Tell our delegate that we are done after an error.
    if (_delegate)
    {
        AD_LOG_ERROR(@"authorization error", error.code, [error localizedDescription]);
        dispatch_async( dispatch_get_main_queue(), ^{ [_delegate webAuthenticationDidFailWithError:error]; } );
    }
    else
    {
        AD_LOG_ERROR(@"Delegate object is lost", AD_ERROR_APPLICATION, @"The delegate object was lost, potentially due to another concurrent request.");
    }
}

@end
