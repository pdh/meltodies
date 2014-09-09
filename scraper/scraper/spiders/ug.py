# -*- coding: utf-8 -*-
import os
import re
import random
import codecs
import scrapy

from yt import get_top_id
#from scraper.items import ScraperItem


file_template = u"""===
title: {title}
version: {version}
author: {author}
performed_by: {performed_by}
tube_id: {tube_id}
===
{content}
"""


class UgSpider(scrapy.Spider):
    name = "ug"
    allowed_domains = [
        "tabs.ultimate-guitar.com"
    ]

    def __init__(self, artist=None, *args, **kwargs):
        super(UgSpider, self).__init__(*args, **kwargs)
        if artist is None:
            raise Exception("artist must be specified")
        self.artist = artist
        artist = artist.lower().replace(" ", "_")
        self.start_urls = [
            'http://www.ultimate-guitar.com/tabs/%s_tabs.htm?no_takeover' % artist,
        ]

    def parse(self, response):
        #/html/body/center/div/table/tr/td/table/tr/td[2]/table/tr[3]/td/table[2]/tr[6]/td[1]/a
        #/html/body/center/div/table/tr/td/table/tr/td[2]/table/tr[2]/td/table[2]/tbody/tr[2]/td[1]/a

        # we are on a start url!
        sel = response.xpath("/html/body/center/div/table/tr/td/table/tr/td[2]/table")
        anchors = sel.xpath(".//a[contains(., 'Chords') and not(contains(., 'Ukulele'))]/@href").extract()
        for a in anchors:
            yield scrapy.Request(a, callback=self.parse)
        else:
            raw = response.xpath("//pre[3]").extract()
            if raw:
                title = response.xpath("//h1/text()").extract()[0]
                insensitive_chords = re.compile(re.escape('chords'), re.IGNORECASE)
                title = str(insensitive_chords.sub('', title)).strip()
                otitle = title

                filename = title.lower().replace(" ", "_") + ".melt"
                filepath = os.path.join("..", "melts", filename)
                version = ""
                if os.path.exists(filepath):
                    version = "%x" % random.getrandbits(32)
                    title += " %s" % version
                    filename = title.lower().replace(" ", "_") + ".melt"
                    filepath = os.path.join("..", "melts", filename)

                # author/performed_by ...
                # TODO - people don't even get this right .. hrm ..
                # might have to curate this by hand for a while
                author = self.artist
                performed_by = self.artist
                content = re.sub('<[^<]+?>', '', raw[0])
                content = content.replace(r'\r\n', r'\n')
                tube_id = get_top_id("%s %s" % (self.artist, otitle))
                file_text = file_template.format(
                    title=otitle,
                    author=author,
                    performed_by=performed_by,
                    tube_id=tube_id,
                    content=content,
                    version=version,
                )

                with codecs.open(filepath, "w", encoding="utf-8") as f:
                    f.write(file_text)
                #print file_text
                #yield ScraperItem(content=content)
