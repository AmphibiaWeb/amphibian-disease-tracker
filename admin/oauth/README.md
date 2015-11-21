# PHP-MultiOAuth

This is a PHP library designed to provide a multiple-option login
process for Google, Twitter, Facebook, and OpenID.

## Use Case

Users signing on with this library through any of these services will return a standard array, containing personal information, an email address used to identify the user, and a "password" string derived from unique identifiers from the service.

````php
array (
  [password]=DERIVED_PASSWORD,
  [email]=EMAIL_FROM_SERVICE,
  [picture]=SUPPLIED_USER_IMAGE_URL,
  [full_name]=FULL_NAME,
  [first_name]=SUPPLIED_OR_GUESSED_FIRST_NAME,
  [last_name]=SUPPLIED_OR_GUESSED_LAST_NAME,
  [location]=SUPPLIED_LONG_FORM_LOCATION,
  [zip]=SUPPLIED_OR_GUESSED_ZIP_CODE,
  [handle]=SUPPLIED_OR_GUESSED_USERNAME
)
````

## Installation

### Register your app with Google
### Register your app with Twitter
### Register your app with Facebook
### Set your function calls
Within `vars.php`, you can set which functions the main handler should call upon a successful authentication to the remote server. This function will typically take the supplied data from the OAuth/OpenID server and either authenticate it against an existing user or create a new one.

If the handler recieves a `BOOLEAN false` from the authenticator function, and a function is specified to begin a new user creation flow, the handler will direct the information retrieved to the new user creation function specified in `vars.php`.

This whole process can be handled natively by your application if within `vars.php`, `$post_data_to_url` is set set to a destination URL. In that case, the parsed authentication information will be sent as a base64 encoded JSON object via POST. It can also be sent as a GET request to the URL specified in `$send_data_as_get_to_url`, but this is not recommended.

## Use

### In your code
### User landing
### Your login flow

## Contributed Code

This handler uses code from several sources. Code from those sources
use the licenses of the contributor.

This includes libraries in the `lib` directory from:

https://github.com/abraham/twitteroauth (as remote `twitteroauth`)  
https://github.com/googleplus/gplus-quickstart-php  
https://github.com/facebook/facebook-php-sdk-v4 (as remote `facebooksdk`)  
https://github.com/google/google-api-php-client (as remote `googlephp`)  

However, the remainder of the code that does not fall under the
purview of the licenses as described there fall under the GPL.


## GPL License

Velociraptor Systems Software / www.velociraptorsystems.com

Copyright (C) 2013 Philip Kahn

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public
License as published by the Free Software Foundation; either
version 3 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
02110-1301  USA

http://opensource.org/licenses/gpl-3.0
