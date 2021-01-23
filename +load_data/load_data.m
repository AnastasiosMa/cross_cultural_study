classdef load_data
    %Load data
    %example obj = load_data.load_data('~/Desktop/ccstudy/responses_pilot/Music Listening Habits.csv')
    
    properties
        dataPath
        translationsPath = '~/Desktop/ccstudy/Translations pilot/Translations_MLH.xlsx'
        dataTable
    end
    
    methods
        function obj = load_data(dataPath)
            if nargin == 0
                dataPath = [];
            end
            obj.dataPath = dataPath;
            obj = get_variable_names(obj);
            obj = correct_country_names(obj);
            obj = count_participants(obj);
        end
        
        function obj = get_variable_names(obj)
            obj.dataTable = readtable(obj.dataPath,'HeaderLines',1);
            firstrowNames = readtable(obj.dataPath);
            firstrowNames = firstrowNames.Properties.VariableNames;
            %HARDCODED LOCATIONS OF VARIABLE NAMES from PILOT CSV OUTPUP
            reason_music = {'Music_Background','Music_Memories','Music_HaveFun',...
                'Music_MusicsEmotion','Music_ChangeMood','Music_ExpressYourself','Music_Connected'};
            reason_track = {'Track_Background','Track_Memories','Track_HaveFun',...
                'Track_MusicsEmotion','Track_ChangeMood','Track_ExpressYourself','Track_Connected'};
            track_info = {'Artist','Track','Album','Link'};
            emolabels = [obj.dataTable.Properties.VariableNames(23:56), {'LyricsImportance'}'];
            demographics = {'Age','Gender','Childhood','Adulthood','Residence',...
                'Identity','Education','OtherEducation','Musicianship',...
                'Employment','OtherEmployment','EconomicSituation','MusicWellBeing'};
            varLabels = [firstrowNames(1:11), reason_music, track_info, emolabels,...
                reason_track, {'Open-ended'}, demographics, obj.dataTable.Properties.VariableNames(79:end)];
            obj.dataTable.Properties.VariableNames = varLabels;
        end
        function obj = correct_country_names(obj)
            %HARDCODED LOCATION OF COUNTRIES
            countryIdx = obj.dataTable{:,68:71};
            language = obj.dataTable{:,'language'};
            countryCodes = readtable(obj.translationsPath, 'Sheet','Country list codes');
            language_abbr = {'en','fi','el','lt','es','tr','ru','zh-tw','pt','fr','de'};
            %replace country code with correct country name
            for k=1:size(countryIdx,1)
                l = find(strcmpi(language{k},language_abbr));
                for i=1:size(countryIdx,2)
                    if ~isnan(countryIdx(k,i))
                        countryCorrected(k,i) = table2array(countryCodes(table2array(countryCodes(countryIdx(k,i),l+1)),1));
                    end
                end
            end
            countryCorrected = array2table(countryCorrected,'VariableNames',...
                {'Country(childhood)','Country(adulthood)',...
                'Country(residence)','Country(identity)'});
            obj.dataTable = [obj.dataTable countryCorrected];
        end
        function obj = count_participants(obj)
            N = height(obj.dataTable);
            disp(['Number of responses: ' num2str(N)]);
            %language 
            language_counts = groupcounts(obj.dataTable,'language');
            language_counts.language = string(language_counts.language);
            %per_language_counts = table(round(table2array(language_counts(:,2))/N*100,2),...
             %   'VariableNames',{'%'});
            %sortrows([language_counts per_language_counts],-2)
            sortrows(language_counts,-2)
            %countries 
            complete_responses = cell2mat(arrayfun(@(x) ~isempty(x{1}), ...
                obj.dataTable{:,'Country(childhood)'},'Uni',false));
            N_complete = sum(complete_responses);%responses with country info 
            disp(['Number of complete responses: ' num2str(N_complete)]);
            country_counts = groupcounts(obj.dataTable(complete_responses,:),...
                'Country(childhood)');
            country_counts.('Country(childhood)') = string(country_counts.('Country(childhood)'));
            %per_country_counts = table(round(table2array(country_counts(:,2))/N_complete*100,2),...
             %   'VariableNames',{'%'});
            %sortrows([country_counts per_country_counts],-2)
            sortrows(country_counts,-2)
        end
        function obj = get_TIPI_INDCOL_scores(obj) 
           % 
        end
    end
end

