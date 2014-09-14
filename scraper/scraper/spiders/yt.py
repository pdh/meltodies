#!/usr/bin/python

from apiclient.discovery import build
from apiclient.errors import HttpError
from oauth2client.tools import argparser


# Set DEVELOPER_KEY to the API key value from the APIs & auth > Registered apps
# tab of
#   https://cloud.google.com/console
# Please ensure that you have enabled the YouTube Data API for your project.
DEVELOPER_KEY = "AIzaSyAt9oNWxCBs5OiCG4xHdexAdsyh1lP_AYc"
YOUTUBE_API_SERVICE_NAME = "youtube"
YOUTUBE_API_VERSION = "v3"


def get_top_id(query):
    youtube = build(
        YOUTUBE_API_SERVICE_NAME,
        YOUTUBE_API_VERSION,
        developerKey=DEVELOPER_KEY
    )
    try:
        search_response = youtube.search().list(
            q=query,
            part="id",
            maxResults=10
        ).execute()
    except:
        # you would think that google doesn't suck.
        # but, sometimes you are surprised, I guess.
        # apiclient.errors.HttpError: <HttpError 403 when requesting
        # https://www.googleapis.com/youtube/v3/search?q=...&alt=json&part=id&key=AIzaSyAt9oNWxCBs5OiCG4xHdexAdsyh1lP_AYc&maxResults=10
        # returned "Access Not Configured. Please use Google Developers Console to activate the API for your project.">
        return ""
    # just return the ID for the first video
    for search_result in search_response.get("items", []):
        if search_result["id"]["kind"] == "youtube#video":
            return search_result["id"]["videoId"]
