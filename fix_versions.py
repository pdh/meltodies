import os
import yaml
import codecs
import hashlib

from collections import defaultdict


file_template = u"""===
title: {0[title]}
version: {0[version]}
author: {0[author]}
performed_by: {0[performed_by]}
tube_id: {0[tube_id]}
===
{0[content]}
"""

MELT_DIR = "./melts/"

versions = set()


for melt in os.listdir(MELT_DIR):
    if os.path.splitext(melt)[-1] != ".melt":
        continue
    fn = "melts/%s" % melt
    with codecs.open(fn, encoding="utf-8") as f:
        txt = f.read()
        meta = txt.split("===")[1]
        meta = yaml.load(meta)
        content = txt.split("===")[2]
        version = hashlib.md5(content.encode('utf-8').strip()).hexdigest()
        if version in versions:
            #print "DUPLICATE!"
            pass
        else:
            versions.add(version)
            context = defaultdict(lambda: "", meta)
            context["content"] = content
            context["version"] = version
            file_text = file_template.format(context)

            filepath = "melts/%s_%s.melt" % (
                meta["title"].lower().replace(" ", "_"),
                version
            )
            #print filepath

            with codecs.open(filepath, "w", encoding="utf-8") as f:
                f.write(file_text)

    os.remove(fn)
