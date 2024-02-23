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
import time

data_dir = 'data_lyrics/ccsdata_complete_clean.xlsx'
data = pd.read_excel(data_dir)

artists = data['Artist']
tracks = data['Track']

track_artist =list(tracks+artists)
unique_track_artist = set(track_artist)
track_artist_indexes = [track_artist.index(x) for x in unique_track_artist] #find unique indexes
print('Unique track_artists: {}'.format(len(track_artist_indexes)))

tracks = list(tracks.iloc[track_artist_indexes])
artists = list(artists.iloc[track_artist_indexes])
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

def scrap_song_url(song_id):
    headers = {'Authorization': 'Bearer ' + defaults['request']['token']}
    page = requests.get('https://api.genius.com/songs/' + str(song_id), headers=headers)
    #page = requests.get(url, headers=headers)
    html_soup = BeautifulSoup(page.text, 'html.parser')
    while html_soup.find('div', class_='lyrics')is None:
            headers = {'Authorization': 'Bearer ' + defaults['request']['token']}
     #       page = requests.get(url, headers=headers)
            page = requests.get('https://api.genius.com/songs/' + str(song_id), headers=headers)
            html_soup = BeautifulSoup(page.text, 'html.parser')
    #[h.extract() for h in html('script')]
    lyrics_temp = html_soup.find('div', class_='lyrics').get_text()

    return lyrics_temp
#%% Retrieve genius SEARCH html
retrieved_tracks = []
retrieved_artists = []
mismatch = []
instrumental = []
#%%
for i in range(633,len(artists)):
    if i%20==0:
       genius = Genius(access_token)  
    print(i)
    print(artists[i] + tracks[i])
    pausing=0
    while pausing ==1:
        try:
            song = genius.search_song(tracks[i], artists[i])
            pausing=1
        except:
            time.sleep(10)
            print('pausing time')
    if song:
        print('Lyrics found')
        if artists[i].lower() in song.artist.lower() and \
            tracks[i].lower() in song.title.lower():
                mismatch.append(0)
        else:
            mismatch.append(1)
        retrieved_artists.append(song.artist)
        retrieved_tracks.append(song.title)
        instrumental.append(0)
        lyrics = song.lyrics
        lyrics = re.sub(r'\[.*\]', '\n', lyrics)
        with open('data_lyrics/lyrics/'+artists[i]+'_'+tracks[i]+'.txt', 'w') as f:
                    f.write(lyrics)
    else:
        retrieved_tracks.append('')
        retrieved_artists.append('')
        instrumental.append(1)
        mismatch.append(0)
    time.sleep(2)        