#!/usr/bin/python

from apiclient.discovery import build

from retrying import retry


# Set DEVELOPER_KEY to the API key value from the APIs & auth > Registered apps
# tab of
#   https://cloud.google.com/console
# Please ensure that you have enabled the YouTube Data API for your project.
# why do the keys keep becoming invalidated? F.
#DEVELOPER_KEY = "AIzaSyAvDMM2U-BgElKvejfqj3ziQkd_c9xLIxE"
# google, I'm not happy about this key replacement problem.
# like I even care.
DEVELOPER_KEY = "AIzaSyBUmtR1hNQGJugFt-Rx8ZDutOR2PUBNpO8"
YOUTUBE_API_SERVICE_NAME = "youtube"
YOUTUBE_API_VERSION = "v3"


def get_top_id(query):
    youtube = build(
        YOUTUBE_API_SERVICE_NAME,
        YOUTUBE_API_VERSION,
        developerKey=DEVELOPER_KEY
    )
<<<<<<< HEAD
    try:
        search_response = youtube.search().list(
=======

    @retry(wait_fixed=1000, stop_max_attempt_number=3)
    def retry_execute():
        return youtube.search().list(
>>>>>>> master
            q=query,
            part="id",
            maxResults=10
        ).execute()
<<<<<<< HEAD
    except:
        # you would think that google doesn't suck.
        # but, sometimes you are surprised, I guess.
        # apiclient.errors.HttpError: <HttpError 403 when requesting
        # https://www.googleapis.com/youtube/v3/search?q=...&alt=json&part=id&key=AIzaSyAt9oNWxCBs5OiCG4xHdexAdsyh1lP_AYc&maxResults=10
        # returned "Access Not Configured. Please use Google Developers Console to activate the API for your project.">
=======
    try:
        search_response = retry_execute()
    except:
        print "------------------------------------FAIL"
>>>>>>> master
        return ""
    # just return the ID for the first video
    for search_result in search_response.get("items", []):
        if search_result["id"]["kind"] == "youtube#video":
            return search_result["id"]["videoId"]
