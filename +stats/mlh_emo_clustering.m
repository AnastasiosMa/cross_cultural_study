classdef mlh_emo_clustering < load_data.load_data
    %Cluster emotion relationship across languages
    %example obj = stats.mlh_emo_clustering('~/Desktop/ccstudy/responses_pilot/Music Listening Habits.csv')
    
    properties
        
    end
    
    methods
        function obj = mlh_emo_clustering(dataPath)
            if nargin == 0
                dataPath = [];
            end
            obj = obj@load_data.load_data(dataPath);
            
        end
    end
end

