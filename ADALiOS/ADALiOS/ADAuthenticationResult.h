// Created by Boris Vidolov on 10/10/13.
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

#import <Foundation/Foundation.h>
#import <ADAliOS/ADAuthenticationError.h>
#import <ADALiOS/ADUserInformation.h>

@class ADTokenCacheStoreItem;

typedef enum
{
    /*! Everything went ok. The result object can be used directly. */
    AD_SUCCEEDED,
    
    /*! User cancelled the action to supply credentials. */
    AD_USER_CANCELLED,
    
    /*! Some error occurred. See the "error" field for details.*/
    AD_FAILED,
    
} ADAuthenticationResultStatus;

/*!
 Represent the authentication result pass to the asynchronous handlers of any operation.
 */
@interface ADAuthenticationResult : NSObject
{
@protected
    //See the corresponding properties for details.
    ADTokenCacheStoreItem*          _tokenCacheStoreItem;
    ADAuthenticationResultStatus    _status;
    ADAuthenticationError*          _error;
    BOOL                            _multiResourceRefreshToken;
    NSUUID*                         _correlationId;
}

/*! See the ADAuthenticationResultStatus details */
@property (readonly) ADAuthenticationResultStatus status;

@property (readonly) ADTokenCacheStoreItem* tokenCacheStoreItem;

/*! The error that occurred or nil, if the operation was successful */
@property (readonly) ADAuthenticationError* error;

/*! Set to YES, if part of the result contains a refresh token, which is a multi-resource
 refresh token. */
@property (readonly) BOOL multiResourceRefreshToken;

/*! The correlation id, returned by the server. Used for diagnostic purposes. Can be nil, if
 the server did not return one, or the item was extracted from the cache. */
@property (readonly) NSUUID* correlationId;

@end

