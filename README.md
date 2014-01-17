Active Directory Authentication Library (ADAL)
=====================================

[![Build Status](https://travis-ci.org/MSOpenTech/azure-activedirectory-library-for-ios.png)](https://travis-ci.org/MSOpenTech/azure-activedirectory-library-for-ios)
[![Coverage Status](https://coveralls.io/repos/MSOpenTech/azure-activedirectory-library-for-ios/badge.png)](https://coveralls.io/r/MSOpenTech/azure-activedirectory-library-for-ios) 

The library wraps OAuth2 protocols implementation, needed for a native iOS app to authenticate with the Azure Active Directory. 



Integrate library to your application:

1. Clone the repository to your machine
2. Build the library
3. Add the ADALiOS library to your project
4. Add ADALiOSFramework to “Target Dependences” build phase of your application
5. Add ADALiOSBundle.bundle to “Copy Bundle Resources” build phase of your application
6. Add libADALiOS to “Link With Libraries” phase.

Where to start:

1. Check the ADAuthenticationContext.h header. ADAuthenticationContext is the main class, used for obtaining, caching and supplying access tokens.
2. See the http://www.cloudidentity.com blog to get familiar with the ADAL library.
