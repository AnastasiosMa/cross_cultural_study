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
def find_spotify_id(track_name, artist_name):
    modified=0
    track_id=[]
    if isinstance(artist_name, (str)):
       query_track = dict(q = track_name + ' ' + artist_name, type = "track", limit = 50) 
    else:
       query_track = dict(q = track_name, type = "track", limit = 50)       
    search = conn.query_get('/v1/search/',query_track)
    for i in range(len(search['tracks']['items'])):
        artist = search['tracks']['items'][i]['artists'][0]['name']
        name = search['tracks']['items'][i]['name']
        if artist_name.lower()==artist.lower() and track_name.lower()==name.lower():
           track_id = search['tracks']['items'][i]['id'] 
           break
    if not track_id:
        track_id = search['tracks']['items'][0]['id']
        modified = 1
    return track_id,modified
#%% Extract SPOTIFY IDS from track-artist
data = pd.read_csv('ccsData.csv')
track_info = data.loc[:,['Track','Artist']].dropna()
track_artist =list(track_info.Track+track_info.Artist)
unique_track_artist = set(track_artist)
track_artist_indexes = [track_artist.index(x) for x in unique_track_artist] #find unique indexes
print('Unique track_artists: {}'.format(len(track_artist_indexes)))
track_info=track_info.iloc[track_artist_indexes,:]
track_info.spotify_id = ''
track_info.modified = 0
#%%Find spotify id
faulty_tracks = []
conn = Connection(_id, _secret)
counter = 0
for index,rows in track_info.iterrows():
    if counter%300==0:
       conn = Connection(_id, _secret) 
    print(counter)
    try: 
        track_id, modified = find_spotify_id(rows.Track, rows.Artist)
        if track_id:
            track_info.loc[index,'spotify_id'] = track_id
            track_info.loc[index,'modified'] = modified
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
for i in range(len(track_info.shape[0])):
    if i%300==0:
       conn = Connection(_id, _secret) 
    print(i)
    try:
        features.loc[i,:]=get_Spotify_variables(track_info.spotify_id[i])        
    except:
        print('Error')
        faulty_ids.append(i)

#combine existing and newly extracted features
if pathExists:
   features = pd.concat([existing_features,features]) 

features=features.reset_index()
features.index = range(features.shape[0])     
#features.to_csv('data/phase2/spotify_features/Spotify_features.csv',encoding='UTF8',sep=';',index=0)       
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
# Search for preview through v1/search
def missing_preview(track_name, artist_name,original_track_id,save_loc):
    """
    If preview is missing try to find other versions of the track that might have preview
    """
    if artist_name:
       query_track = dict(q = track_name + ' ' + artist_name, type = "track", limit = 50) 
    else:
       query_track = dict(q = track_name, type = "track", limit = 50)
       
    found_preview = 0
    search = conn.query_get('/v1/search/',query_track)
    for i in range(len(search['tracks']['items'])):
        track_id = search['tracks']['items'][i]['id']
        artist = search['tracks']['items'][i]['artists'][0]['name']
        name = search['tracks']['items'][i]['name']
        if search['tracks']['items'][i]["preview_url"] in track.keys(): #check if key exists
            url = search['tracks']['items'][i]["preview_url"]
        else: 
            url = []
        if url and artist_name.lower()==artist.lower() and track_name.lower()==name.lower():
           download_track(track_id,artist,name,save_loc,url)
           found_preview = 1
           original_track_id = track_id
           break
         
    return[found_preview,original_track_id]
#%% GET PREVIEWS
conn = Connection(_id, _secret)
#track_ids = list(set(track_ids)) #store unique ID's
replaced_audio = 0

#for i in features.index:
    # get track preview_urls
for i in range(29584,len(spotify_ids)):
    #time.sleep(1)
    if i%150==0:
       conn = Connection(_id, _secret) 
    track = conn.query_get('/v1/tracks/' + features.loc[i,'trackID'])
    print(i)
    if not 'error' in dict.keys(track):
         track_name = track["name"]
         #name = re.sub("\W", "_", name)
         artist_name = track["artists"][0]["name"]
         #artist = re.sub("\W", "_", artist)
         if 'preview_url' in track.keys():
             url = track["preview_url"]
             found = 0
         else: 
             url = []
             #print("Searching url for {}-{}".format(artist_name, track_name))
         if url:
            download_track(features['trackID'][i],artist_name,track_name,save_loc,url)
            found = 1
         else:
              print("could not find url with id. Searching with trackname_artist")
              res = missing_preview(track_name,artist_name,features['trackID'][i],save_loc)  
              found = res[0]
              if found:
                  features.loc[i,'trackID'] = res[1]
                  features.loc[i,'danceability':'trackID']=get_Spotify_variables(features.loc[i,'trackID'])            
                  replaced_audio = replaced_audio + 1
         if found:              
            features.loc[i,'AudioAvailable'] = 1
         else:
           print("track is missing")
           features.loc[i,'AudioAvailable'] = 0
    else:
        print("Invalid ID")

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
