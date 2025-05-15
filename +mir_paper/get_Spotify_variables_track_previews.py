# -*- coding: utf-8 -*-
"""
Get audio previews from Spotify
"""


import requests
import base64
import os
import pandas as pd
import numpy as np
from IPython.core.debugger import Pdb
ipdb = Pdb()
import time
#%% Spotify authentication
with open('+mir_paper/spotify_user_authentication.txt') as f:
    credentials = f.readlines()
_id = credentials[0][0:-1]
_secret = credentials[1][0:-1]

save_loc = '+mir_paper/data/spotify_previews'
#%%
class Connection:
    """
    Class' object instantiates a connection with spotify. When the connection is alive, queries are made with the query_get
    method.
    """
    def __init__(self, client_id, secret):
        # First header and parameters needed to require an access token.
        param = {"grant_type": "client_credentials"}
        header = {"Authorization": "Basic {}".format(
            base64.b64encode("{}:{}".format(client_id, secret).encode("ascii")).decode("ascii")),
                  'Content-Type': 'application/x-www-form-urlencoded'}
        self.token = requests.post("https://accounts.spotify.com/api/token", param, headers=header).json()["access_token"]
        self.header = {"Authorization": "Bearer {}".format(self.token)}
        self.base_url = "https://api.spotify.com"

    def query_get(self, query, params=None):
        """
        
        :param query: (str) URL coming after example.com
        :param params: (dict)
        :return: (json) 
        """
        return requests.get(self.base_url + query, params, headers=self.header).json()
#%% GET SPOTIFY VARIABLES FUNCTIONS
def get_Spotify_variables(track_id):
    spotify_variables = conn.query_get('/v1/audio-features/' + track_id)
    track_obj = conn.query_get('/v1/tracks/' + track_id)
    spotify_variables['trackPopularity'] = track_obj['popularity']
    #audio_analysis_obj = conn.query_get('/v1/audio-analysis/' + track_id)
    #spotify_variables['trackSegments'] = len(audio_analysis_obj['sections'])
    album_obj = conn.query_get('/v1/albums/' + track_obj['album']['id'])
    album_vars = {'album_id':album_obj['id'],'album_name':album_obj['name'],'album_date':album_obj['release_date'], \
                  'album_genres':album_obj['genres'],'album_popularity':album_obj['popularity']}
    spotify_variables.update(album_vars)
    artist_obj = conn.query_get('/v1/artists/' + track_obj['artists'][0]['id'])
    artist_vars = {'artist_id':artist_obj['id'],'artist_popularity':artist_obj['popularity'],'artist_genres':artist_obj['genres'],\
                   'artist_followers':artist_obj['followers']['total']}
    spotify_variables.update(artist_vars)
    spotify_variables['trackName'] = track_obj['name']
    spotify_variables['artistName'] = track_obj['artists'][0]['name']
    spotify_variables['trackID'] = track_id
    keysToRemove = ('analysis_url','id','track_href','type','uri')
    for i in keysToRemove:
        if i in spotify_variables:
           del spotify_variables[i]
    return(spotify_variables)
# Search for IDs through v1/search
def find_spotify_id(track_name, artist_name,correct_retrieval):
    track_id=[]
    if isinstance(artist_name, (str)):
       query_track = dict(q = track_name + ' ' + artist_name, type = "track", limit = 50) 
    else:
       query_track = dict(q = track_name, type = "track", limit = 50)       
    search = conn.query_get('/v1/search/',query_track)
    if correct_retrieval=='1.0':
        track_id = search['tracks']['items'][0]['id']
    else:
        for i in range(len(search['tracks']['items'])):
            artist = search['tracks']['items'][i]['artists'][0]['name']
            name = search['tracks']['items'][i]['name']
            if artist_name.lower()==artist.lower() and track_name.lower()==name.lower():
               track_id = search['tracks']['items'][i]['id'] 
               break
    return track_id
#%% Extract SPOTIFY IDS from track-artist
data = pd.read_excel('+mir_paper/data/spotify retrieval corrections.xlsx')
track_info = data.loc[:,['Original Track','Original Artist','Correct_Retrieval']].astype('str')
track_info.columns = ['Track','Artist','Correct_Retrieval']
#track_artist =list(track_info.Track+track_info.Artist)
#unique_track_artist = set(track_artist)
#track_artist_indexes = [track_artist.index(x) for x in unique_track_artist] #find unique indexes
#print('Unique track_artists: {}'.format(len(track_artist_indexes)))
#track_info=track_info.iloc[track_artist_indexes,:]
track_info.spotify_id = ''
#%%Find spotify id
faulty_tracks = []
conn = Connection(_id, _secret)
counter = 0
for index,rows in track_info.iterrows():
    if counter%300==0:
       conn = Connection(_id, _secret) 
    print(counter)
    try: 
        track_id = find_spotify_id(rows.Track, rows.Artist,rows.Correct_Retrieval)
        if track_id:
            track_info.loc[index,'spotify_id'] = track_id
            print(track_id)
        else: 
            print('ID Not found. Track: {}, Artist: {}'.format(rows.Track, rows.Artist))
    except:
        print('Error')
        faulty_tracks.append(index)
    counter +=1
#%% Extract SPOTIFY features
colnames = list(pd.DataFrame(list((get_Spotify_variables('6QSeaiYpD8rXMCS0CIrIJc')).items())).loc[:,0])
colnames.extend(['AudioAvailable'])
features = pd.DataFrame(columns=colnames)
conn = Connection(_id, _secret) 
counter = 0
for index,rows in track_info.iterrows():
    if counter%300==0:
       conn = Connection(_id, _secret) 
    print(counter)
    try:
        features.loc[index,:]=get_Spotify_variables(rows.spotify_id)        
    except:
        print('Error')
    counter +=1

#features=features.reset_index()
#features.index = range(features.shape[0])     
#features.to_csv('+mir_paper/data/spotify_features.csv',encoding='UTF8',sep=';',index=1)
#track_info.to_csv('+mir_paper/data/track_info.csv',encoding='UTF8',sep=';',index=1)
#match_spot=track_info[['Track','Artist']].join(features[['trackName','artistName']],how='inner')       
#%% GET PREVIEWS FUNCTIONS
def download_track(track_id,artist,name,save_loc,url):
    os.makedirs(save_loc, exist_ok=True)
    f = os.path.join(save_loc, "{}.mp3".format(track_id))
    if not os.path.isfile(f):
           r = requests.get(url)
           print("Saving {}-{}.mp3".format(artist, name))
           #print("ID: " + track_id)
           with open(f, "wb") as f:
                        f.write(r.content)
    else:
           print("file already exists:{}-{}".format(artist, name))
#%% GET PREVIEWS
conn = Connection(_id, _secret)
counter = 0
for index,rows in features.iterrows():
    #time.sleep(1)
    if counter%300==0:
       conn = Connection(_id, _secret) 
    track = conn.query_get('/v1/tracks/' + rows.trackID)
    print(counter)
    if not 'error' in dict.keys(track):
         if 'preview_url' in track.keys():
             url = track["preview_url"]
         else: 
             url = []
         if url:
            download_track(rows.trackID,rows.artistName,rows.trackName,save_loc,url)
            features.loc[index,'AudioAvailable'] = 1
         else:
            print("track is missing")
            print("Missing url for {}-{}".format(rows.artistName, rows.trackName))
            features.loc[index,'AudioAvailable'] = 0
    else:
        print("Invalid ID")
        features.loc[index,'AudioAvailable'] = 0
    counter +=1

import math        
for i in range(features.shape[0]):
    if math.isnan(features.iloc[i,-1]):
        features.iloc[i,-1]=0
#features.to_csv('data/phase2/spotify_features/Spotify_features.csv',encoding='UTF8',sep=';',index=False)       
#%% problematic rows 
#4460, 3143        
#4348 track name = Ella's Lullaby, artist name = Enno Aare
#4421 track name = G.U.Y., artist name = Lady Gaga
#5882 ARTPOP Lady Gaga
#7873 Force Alan Walker
if np.nan:
    print('hi')
