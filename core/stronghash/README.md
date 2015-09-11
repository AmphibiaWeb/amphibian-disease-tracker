# php-stronghash

Hash function designed to securely hash sensitive data, like
passwords, in the most secure way supported by the server you are using.	

Code cleanup is forthcoming!

## Use	

Add the following code to your document before calling the function:

```php
require_once('PATH/TO/FILE/php-stronghash.php');
```

Then, simply call 

```php
h = new Stronghash();
h.hasher(YOUR_DATA[,SALT=null,ALGORITHM=null,BOOL create_salt_if_not_supplied=true,ROUNDS=100000]);
```

This means that the easiset way to call the function, and get the most
secure result, is to call `hasher(DATA);`. That's it, nothing else to
it! The function then returns an array of the form:

```php
     Array {
             [hash] => HASH_STRING, // the actual hash
             [salt] => USED_SALT, // generated salt, default 32 characters
             [algo] => ALGORITHM_USED // eg, "pbkdf2crypt" meaning pbkdf2 done with the crypt() function;
           }
```

For convenience, when using `crypt()` this algorthm strips the data
`crypt()` keeps for itself to make the hash easier to parse.  
The unadulterated hash is then stored in the key `[full_hash]`.
When rounds are used other than the default, they are stored in the
key `[rounds]`. 

The library contains a native implementation of
[PBKDF2](https://en.wikipedia.org/wiki/Pbkdf2) in case neither
`crypt()` nor `hash_pbkdf2()` is natively supported by the
server. Failing that, `hash_hmac` is tried, and if that fails, the
hardest version of SHA is used.

### Verify a hash

If you wish to verify a hash, calling:

```php
verifyHash(BASE_HASH_OR_DATA,COMPARISON_DATA,[STORED_SALT,STORED_ALGORITHM,OVERRIDE_DEFAULT_ROUNDS_NUMBER])
```

will return TRUE on a match, and FALSE on a failure. It uses a slow
match to avoid attacks on speed matching. If the function is unable to use the same algorithm, it will return
FALSE. It is highly recommended to always specify the algo. If
COMPARISON_DATA is the original array passed from `hasher()`, the
correct data is always passed automatically, filling the optional
values with the appropriate key values. This is the easiest way to
pass data into `verifyHash()`.

### Other Functions

This package includes a couple of dependency functions. Of primary
utility are:

    genUnique([LENGTH=128, RETURN_BASE_16=TRUE]) : generates a unique string. Length defaults to 128. 
                                                 This uses PHP's rand(), the current URL, computer time, 
                                                 and a true random value from random.org. If the RETURN_BASE_16 
                                                 flag is set, it will return a SHA-512 hash of the seed value. 
                                                 Otherwise, just the unique seed is returned, which may be 
                                                 shorter than the requested length.

    createSalt([LENGTH=32,ADDITIONAL_ENTROPY=NULL]) : Generate a salt of length LENGTH using PHP's rand(), 
                                                    the current URL, and the computer time. This is faster than
                                                    genUnique().


## LGPL License

Copyright (C) 2014 Philip Kahn

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 3 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
02110-1301  USA

http://opensource.org/licenses/LGPL-3.0
