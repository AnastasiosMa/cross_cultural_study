classdef load_data
    %Load data
    %example obj = load_data.load_data('~/Desktop/ccstudy/responses_pilot/Music Listening Habits.csv')

    properties
        dataPath
        translationsPath = '~/Desktop/ccstudy/Translations pilot/Translations_MLH.xlsx'
        dataTable
        discardMissingData = 1; %Discard responses with missing data
        genderLabels = {'Female','Male','Other'};
        createExcel = 1; %Create excel file with preprocessed data;
        showPlots = 0; %Display plots and tables
        durationThr = 4; %Duration Threshold to exclude responses (in minutes)
        excludeShortResponses = 1; %Exclude responses below duration threshold
        excludeRepetativeResponses = 1; %Exclude responses with repetative answers
    end
    methods
        function obj = load_data(dataPath)
            if nargin == 0
                dataPath = [];
            end
            obj.dataPath = dataPath;
            obj = get_variable_names(obj);
            obj = correct_country_age_gender(obj);
            if obj.discardMissingData ==1
                obj = discard_missing_data(obj);
            end
            obj = survey_duration(obj);
            if  obj.excludeRepetativeResponses
                obj = responderVariability(obj);
            end
            if obj.showPlots == 1
                obj = count_participants(obj);
                obj = age_distribution(obj);
                obj = gender_distribution(obj);
            end
            if obj.createExcel==1
                writetable(obj.dataTable,'ccsData.csv','Encoding','UTF-8')
                dataTable = obj.dataTable; save('ccsData','dataTable');
            end
        end
        
        function obj = get_variable_names(obj)
            obj.dataTable = readtable(obj.dataPath,'HeaderLines',1,'Encoding','UTF-8');
            firstrowNames = readtable(obj.dataPath);
            firstrowNames = firstrowNames.Properties.VariableNames;
            %HARDCODED LOCATIONS OF VARIABLE NAMES from PILOT CSV OUTPUP
            reason_music = {'Music_Background','Music_Memories','Music_HaveFun',...
                'Music_MusicsEmotion','Music_ChangeMood','Music_ExpressYourself','Music_Connected'};
            reason_track = {'Track_Background','Track_Memories','Track_HaveFun',...
                'Track_MusicsEmotion','Track_ChangeMood','Track_ExpressYourself','Track_Connected'};
            track_info = {'Artist','Track','Album','Link'};
            emolabels = [obj.dataTable.Properties.VariableNames(23:56), {'LyricsImportance'}'];
            demographics = {'Age','GenderCode','Childhood','Adulthood','Residence',...
                'Identity','Education','OtherEducation','Musicianship',...
                'Employment','OtherEmployment','EconomicSituation','MusicWellBeing'};
            varLabels = [firstrowNames(1:11), reason_music, track_info, emolabels,...
                reason_track, {'Open-ended'}, demographics, obj.dataTable.Properties.VariableNames(79:end)];
            obj.dataTable.Properties.VariableNames = varLabels;
        end
        function obj = correct_country_age_gender(obj)
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
                %change chinese and greek abbreviations
                if strcmpi(obj.dataTable{k,'language'},'zh-tw')
                    obj.dataTable{k,'language'} = {'ch'};
                elseif strcmpi(obj.dataTable{k,'language'},'el')
                    obj.dataTable{k,'language'} = {'gr'};
                end
            end
            countryCorrected = array2table(countryCorrected,'VariableNames',...
                {'Country_childhood','Country_adulthood',...
                'Country_residence','Country_identity'});
            obj.dataTable = [obj.dataTable countryCorrected];
            %correct Age
            obj.dataTable.Age = obj.dataTable.Age+9;
            %correct Gender
            for k = 1:height(obj.dataTable)
                if obj.dataTable.GenderCode(k)==1
                    obj.dataTable.Gender{k} = obj.genderLabels(1);
                elseif obj.dataTable.GenderCode(k)==2
                    obj.dataTable.Gender{k} = obj.genderLabels{2};
                elseif obj.dataTable.GenderCode(k)==3
                    obj.dataTable.Gender{k} = obj.genderLabels{3};
                end
            end
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
                obj.dataTable{:,'Country_childhood'},'Uni',false));
            N_complete = sum(complete_responses);%responses with country info
            disp(['Number of complete responses: ' num2str(N_complete)]);
            country_counts = groupcounts(obj.dataTable(complete_responses,:),...
                'Country_childhood');
            country_counts.('Country_childhood') = string(country_counts.('Country_childhood'));
            %per_country_counts = table(round(table2array(country_counts(:,2))/N_complete*100,2),...
            %   'VariableNames',{'%'});
            %sortrows([country_counts per_country_counts],-2)
            sortrows(country_counts,-2)
        end
        function obj = discard_missing_data(obj)
            complete_responses = cell2mat(arrayfun(@(x) ~isempty(x{1}), ...
                obj.dataTable{:,'Country_childhood'},'Uni',false));
            obj.dataTable = obj.dataTable(complete_responses,:);
        end
        function obj = age_distribution(obj)
            m_Age = mean(obj.dataTable.Age);
            sd_Age = std(obj.dataTable.Age);
            disp(array2table([m_Age, sd_Age],'VariableNames',{'Mean','SD'}))
            figure
            histogram(obj.dataTable.Age);
            xlabel('Age (in years)'); ylabel('Number of responders');
            title('Age Histogram')
            %Age distribution across languages
            figure
            boxplot(obj.dataTable.Age,obj.dataTable.language)
            xlabel('Languages');ylabel('Age');
            title('Boxplots per language');
            
            countries_N = groupcounts(obj.dataTable,'Country_childhood');
            %find countries with enough participants
            countries_N = table2array(countries_N(table2array(countries_N(:,2))>=20,1));
            all_idx = cellfun(@(x) find(strcmp(x, obj.dataTable.Country_childhood)),...
                countries_N, 'UniformOutput', false);
            idx_c = [];
            for i=1:length(all_idx)
                idx_c = [idx_c; all_idx{i}];
                stats_c(i,1) = mean(obj.dataTable.Age(all_idx{i}));
                stats_c(i,2) = std(obj.dataTable.Age(all_idx{i}));
                figure
                histogram(obj.dataTable.Age(all_idx{i}))
                xlabel('Age (in years)'); ylabel('Number of responders');
                title([countries_N])
            end
            disp(array2table(stats_c,'VariableNames',{'Mean','SD'},'RowNames',countries_N))
            
            figure
            boxplot(obj.dataTable.Age(idx_c),obj.dataTable.Country_childhood(idx_c))
            xlabel('Countries');ylabel('Age');
            title('Boxplots per Country');
        end
        function obj = gender_distribution(obj)
            gender_N = groupcounts(obj.dataTable,'Gender');
        end
        function obj = survey_duration(obj)
            obj.dataTable.Duration = minutes(obj.dataTable{:,'EndDate'} - ...
                obj.dataTable{:,'StartDate'});
            %exclude responses above 30 minutes
            duration = obj.dataTable.Duration(obj.dataTable.Duration<30);
            figure,histogram(duration);
            xlabel('Duration in minutes'); ylabel('Number of responses')
            title('Survey Duration')
            
            %med = median(duration);
            %MAD = 1.4826*median(abs(duration-med))*2; %Median absolute deviation threshold
            %outlier = isoutlier(obj.dataTable.Duration);
            %outlier = obj.dataTable.Duration(outlier & obj.dataTable.Duration<med);
            %obj.dataTable(~)
            if obj.excludeShortResponses
                disp(['Excluding ' num2str(sum(obj.dataTable.Duration<obj.durationThr)) ...
                    ' responses for short duration']);
                obj.dataTable = obj.dataTable(~(obj.dataTable.Duration<obj.durationThr),:);
            end
        end
        function obj = responderVariability(obj)
            for i=1:size(obj.dataTable)
                %HARDCODED LOCATION OF EMOTIONS
                responderVariability(i) = std(table2array(obj.dataTable(i,23:55)));
            end
            figure,histogram(responderVariability)
            xlabel('Standard deviation')
            ylabel('Number of responders')
            title('Standard deviation of emotion ratings for each responder')
            %isoutlier(responderVariability)
            MAD_limit = 1.4826*median(abs(responderVariability-...
                median(responderVariability)))*3; %Median Absolute deviation formula
            %find responses with LOW variability
            outliers_idx = responderVariability<median(responderVariability)-MAD_limit;
            obj.dataTable = obj.dataTable(~outliers_idx,:);
            disp(['Excluding ' num2str(sum(outliers_idx)) ' responses for low variability']);
        end
    end
end

