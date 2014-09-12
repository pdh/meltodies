#!/bin/bash

git checkout master
git pull
git checkout gh-pages
git merge --no-edit master
bower install
./update_songs.py
git checkout master
bower install
./update_songs.py

