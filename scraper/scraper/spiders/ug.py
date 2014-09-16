# -*- coding: utf-8 -*-
import os
import re
import random
import codecs
import hashlib
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
        # Dylan has 14 pages. Does anyone have more on UG?
        self.start_urls = [
            'http://www.ultimate-guitar.com/tabs/%s_tabs%s.htm?no_takeover' % (artist, page)
            for page in range(1, 2)
        ]

    def parse(self, response):
        if response.status == 404:
            print "EXITING", response
            raise scrapy.exceptions.CloseSpider("Artist Exhausted.")
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
                # remove the word chords from title
                title = str(insensitive_chords.sub('', title)).strip()
                # remove tags, convert line endings
                content = re.sub('<[^<]+?>', '', raw[0])
                content = content.replace('\r\n', '\n')
                version = hashlib.md5(content.strip().encode('utf-8')).hexdigest()

                filename = "{title}_{version}.melt".format(
                    title=title.lower().replace(" ", "_"),
                    version=version
                )
                filepath = os.path.join("..", "melts", filename)
                if os.path.exists(filepath):
                    # we rely that the hash in the filepath is correct
                    # to prevent duplicates.
                    yield

                author = self.artist
                performed_by = self.artist

                tube_id = get_top_id("%s %s" % (self.artist, title))
                file_text = file_template.format(
                    title=title,
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
