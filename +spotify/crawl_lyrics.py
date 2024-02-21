#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Feb 20 12:38:50 2024

@author: anmavrol
"""

import requests
import re
import pandas as pd
import numpy as np
from bs4 import BeautifulSoup
from lyricsgenius import Genius

data_dir = 'data_lyrics/ccsdata_complete_clean.xlsx'
data = pd.read_excel(data_dir)

artists = list(data['Artist'])
tracks = list(data['Track'])
#%% genius api authentication
with open('+spotify/genius_api_authentication.txt') as f:
    credentials = f.readlines()
client_id = credentials[0][0:-1]
client_secret = credentials[1][0:-1]
access_token = credentials[2]
genius = Genius(access_token)

defaults = {
    'request': {
        'token': access_token,
        'base_url': 'https://api.genius.com'
    },
    'message': {
        'search_fail': 'The lyrics for this song were not found!',
        'wrong_input': 'Wrong number of arguments.\n' \
                       'Use two parameters to perform a custom search ' \
                       'or none to get the song currently playing on Spotify.'
    }
}

def request_song_info(song_title, artist_name):
    base_url = defaults['request']['base_url']
    headers = {'Authorization': 'Bearer ' + defaults['request']['token']}
    search_url = base_url + '/search?q=' + song_title + '%' + artist_name
    response = requests.get(search_url, headers=headers)

    return response
#%% Retrieve genius SEARCH html
lyrics = []
for i in range(len(artists)):
    print(i)
    print(artists[i] + tracks[i])
    response = request_song_info(tracks[i], artists[i])
    json_response = response.json()
    remote_song_url = None
    for hit in json_response['response']['hits']:
        if artists[i].lower() in hit['result']['primary_artist']['name'].lower():
            remote_song_url = hit['result']['url']                
            break
    # Retrieve genius TRACK html
    if remote_song_url:
        print('Lyrics found')
        lyrics = ''
        search_html = requests.get(remote_song_url)
        html_soup = BeautifulSoup(search_html.text, 'html.parser')
        lyrics_html = html_soup.find_all('div', class_='Lyrics__Container-sc-1ynbvzw-1 kUgSbL')
        for part in lyrics_html:
            lyric_lines = part.find_all()
            for line_part in lyric_lines:
                if len(line_part.get_text())>0:
                    lyrics = lyrics + line_part.get_text(separator='\n') + '\n'
        lyrics = re.sub(r'\[.*\]', '\n', lyrics)
        with open('data_lyrics/lyrics/'+artists[i]+'_'+tracks[i]+'.txt', 'w') as f:
                    f.write(lyrics)
            