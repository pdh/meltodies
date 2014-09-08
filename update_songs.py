#!/usr/bin/env python

import os
import json
import yaml

songs = []

for melt in os.listdir("melts/"):
    if os.path.splitext(melt)[-1] != ".melt":
        continue
    fn = "melts/%s" % melt
    with open(fn) as f:
        txt = f.read()
        meta = txt.split("===")[1]
        meta = yaml.load(meta)
        meta["file"] = fn
        songs.append(meta)

with open("songs.json", "w") as f:
    f.write(
        json.dumps(
            sorted(songs, key=lambda d: d["title"]),
            separators=(',', ':')
        )
    )
