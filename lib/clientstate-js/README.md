ClientState JS Client
====================

Launch a clientstate-redis App from a clienstate-master instance,
then you can use this library to talk to Redis from a static webpage.

Installation
------------

    # TODO?
    bower install clientstate-js


Usage
-----

    csr = new ClientState("uuid", "clientstate.local");
    csr.auth_popup("github", "client-id", function(err, provider_data) {
        // csr.access_token is now set to provider_data.access_token
    });

Once the auth_popup has comeback, csr.access_token will exist.
You can then make calls to the get and post methods to read and write data,
respectively.

    // get the value of the string, foobar
    csr.get("GET", "foobar", function(err, req) {
        console.log(req.responseText);
    })

    // write the value of the string, foobar, to "baz"
    csr.post("SET", "foobar", "baz", function(err, req) {
        console.log(req.responseText);
    })


Developing
----------

Install dependencies
____________________

    npm install
    bower install

Run the test suite
__________________

    grunt test
