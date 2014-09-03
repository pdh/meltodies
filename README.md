meltodies
=========

Chords and lyrics for face melting melodies.

Get On Up
---------

install bower and run `bower install`

Run a dev server:

    python -m SimpleHTTPServer 8090  # if Python2X
    python -m http.server 8090  # if Python3

go to http://localhost:8090/ and find the songs


Contributing
------------

Add songs and then add the name/file to `songs.json`.

To work with the clientside code,
install [CoffeeScript](http://coffeescript.org/)

Then, in the `js` directory:

    coffee --watch --compile .

Now you are ready to hack on the clientside code.
We are trying to not have any serverside code here :-)
