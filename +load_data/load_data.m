classdef load_data
    %Load data
    %example obj = load_data.load_data('responses_pilot/Music Listening Habits.csv','AllResponses')
    properties
        dataPath
        translationsPath = 'Translations pilot/Translations_MLH.xlsx'
        dataTable %table to be used in the analysis
        alldataTable %table with data from all responses
        groupTable %table with responses only from selected groups
        discardMissingData = 1; %Discard responses with missing data
        genderLabels = {'Female','Male','Other'};
        musicianshipLabels = {'Nonmusician','Music-loving nonmusician','Amateur musician','Semiprofessional musician','Professional musician'};
        educationLabels = {'Elementary school','High school','Vocational training','Bachelor''s degree','Master''s degree','Doctoral degree','Other','Prefer not to say','NA'};
        employmentLabels = {'Employed full-time', 'Employed part-time / casual', 'Self-employed', 'Student', 'Homemaker / caregiver', 'Retired', 'Currently out of work', 'Other', 'Prefer not to say','NA'}
        economicSituationLabels = {'Below Average','Average','Above Average'};
        durationThr = 4; %Duration Threshold to exclude responses (in minutes)
        excludeShortResponses = 1; %Exclude responses below duration threshold
        excludeRepetativeResponses = 1; %Exclude responses with repetative answers
        excludeResponsesFromFile = 1;
        excludeResponsesPath = 'responses_pilot/faulty ids.xlsx';
        filterMethod %Accepted Inputs: 'AllResponses','BalancedSubgroups',
        %'UnbalancedSubgroups' 
        createBalancedSubgroups = 0; % create subgroups through permutations
        groupingCategory = 'Country_childhood';
        subgroupNames %Country group names
        subgroupMinNumber = 70;
        subgroupIds %ids of selected subgroup responses
        repetitions = 1E+7; %number of permutations
        exportSubgroups = 1;
        subgroupIdxsPath = 'matchGenderAge/subsampling.mat'; %mat file with subgroup indexes
        createExcel = 0; %Create excel file with preprocessed data;
        showPlots = 0; %Display plots, tables, and text
    end
    methods
        function obj = load_data(dataPath,filterMethod)
            warning('OFF', 'MATLAB:table:ModifiedAndSavedVarnames')
            if nargin == 0
                dataPath = [];
                filterMethod = [];
            end
            obj.dataPath = dataPath;
            obj.filterMethod = filterMethod;
            obj = get_variable_names(obj);
            obj = correct_variables(obj);
            if obj.discardMissingData ==1
                obj = discard_missing_data(obj);
            end
            if obj.excludeResponsesFromFile==1
                obj = exclude_from_file(obj);
            end
            if obj.excludeShortResponses ==1
            obj = survey_duration(obj);
            end
            if  obj.excludeRepetativeResponses
                obj = responderVariability(obj);
            end
            if ~strcmpi(obj.filterMethod,'AllResponses')
            obj = create_groupTable(obj);
            end
            if obj.showPlots == 1
                obj = count_participants(obj);
                %obj = age_distribution(obj);
                %obj = gender_distribution(obj);
            end
            if strcmpi(obj.filterMethod,'BalancedSubgroups')...
                    && obj.createBalancedSubgroups == 1
                obj = create_balanced_subgroups(obj);
            end
            if exist(obj.subgroupIdxsPath)
                obj = load_subgroups(obj);
            end
            if obj.showPlots==1 && strcmpi(obj.filterMethod,'BalancedSubgroups') 
                obj = age_subgroups(obj);
                obj = gender_subgroups(obj);
            end
            if obj.createExcel==1
                writetable(obj.dataTable,'ccsData.csv','Encoding','UTF-8')
                dataTable = obj.dataTable; save('ccsData','dataTable');
            end
            if ~strcmpi(obj.filterMethod,'AllResponses')
            obj.alldataTable = obj.dataTable;
            obj.dataTable = obj.groupTable;
            end
        end
        function obj = get_variable_names(obj)
            %HARDCODED LOCATION OF START AND END TIME
            opts = detectImportOptions(obj.dataPath,'HeaderLines',1,'Encoding','UTF-8');
            opts = setvaropts(opts,{'Var2','Var3'},'InputFormat','MM/dd/yyyy hh:mm:ss aa'); % Specify datetime format
            obj.dataTable = readtable(obj.dataPath,opts);
            firstrowNames = readtable(obj.dataPath);
            firstrowNames = firstrowNames.Properties.VariableNames;
            %HARDCODED LOCATIONS OF VARIABLE NAMES from PILOT CSV OUTPUP
            reason_music = {'Music_Background','Music_Memories','Music_HaveFun',...
                'Music_MusicsEmotion','Music_ChangeMood','Music_ExpressYourself','Music_Connected'};
            reason_track = {'Track_Background','Track_Memories','Track_HaveFun',...
                'Track_MusicsEmotion','Track_ChangeMood','Track_ExpressYourself','Track_Connected'};
            track_info = {'Artist','Track','Album','Link'};
            emolabels = [obj.dataTable.Properties.VariableNames(16:49), {'LyricsImportance'}'];
            demographics = {'Age','GenderCode','Childhood','Adulthood','Residence',...
                'Identity','Education','OtherEducation','Musicianship',...
                'Employment','OtherEmployment','EconomicSituation','MusicWellBeing'};
            varLabels = [firstrowNames(1:4), reason_music, track_info, emolabels,...
                reason_track, {'Open-ended'}, demographics, obj.dataTable.Properties.VariableNames(72:end)];
            obj.dataTable.Properties.VariableNames = varLabels;
        end
        function obj = correct_variables(obj)
            %HARDCODED LOCATION OF COUNTRIES
            countryIdx = obj.dataTable{:,61:64};
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
            % add categorical ordinal array for age
            obj.dataTable.AgeCategory = ordinal(obj.dataTable.Age,{'Under 20','20-29','30-39','40-49','50-59','Over 60'},[],[min(obj.dataTable.Age),20,30,40,50,60,max(obj.dataTable.Age)]);
            %correct Gender
            for k = 1:height(obj.dataTable)
                if obj.dataTable.GenderCode(k)==1
                    obj.dataTable.Gender{k} = obj.genderLabels{1};
                elseif obj.dataTable.GenderCode(k)==2
                    obj.dataTable.Gender{k} = obj.genderLabels{2};
                elseif obj.dataTable.GenderCode(k)==3
                    obj.dataTable.Gender{k} = obj.genderLabels{3};
                end
            end
            %correct Musicianship
            Musicianship = categorical(obj.dataTable.Musicianship,[1:5],obj.musicianshipLabels);
            obj.dataTable = addvars(obj.dataTable,Musicianship(:),'NewVariableNames','musicianshipLabels');
            % education
            Education = categorical(obj.dataTable.Education,[0:8],obj.educationLabels);
            obj.dataTable = addvars(obj.dataTable,Education(:),'NewVariableNames','educationLabels');
            % employment
            Employment = categorical(obj.dataTable.Employment,[0:9],obj.employmentLabels);
            obj.dataTable = addvars(obj.dataTable,Employment(:),'NewVariableNames','employmentLabels');
            % economic situation
            EconomicSituation = categorical(obj.dataTable.EconomicSituation,[1:3],obj.economicSituationLabels);
            obj.dataTable = addvars(obj.dataTable,EconomicSituation(:),'NewVariableNames','economicSituationLabels');
            
        end
        function obj = count_participants(obj)
            N = height(obj.dataTable);
            disp('*** Number of responses ***')
            disp(['---N: ' num2str(N)]);
            unique_c = length(unique(obj.dataTable{:,'Country_childhood'}));
            disp(['Number of countries: ' num2str(unique_c)]);
            %language
            language_counts = groupcounts(obj.dataTable,'language');
            language_counts.language = string(language_counts.language);
            language_counts = sortrows(language_counts,-2);
            disp(language_counts);
            %countries
            complete_responses = cell2mat(arrayfun(@(x) ~isempty(x{1}), ...
                obj.dataTable{:,'Country_childhood'},'Uni',false));
            N_complete = sum(complete_responses);%responses with country info
            %disp(['Number of complete responses: ' num2str(N_complete)]);
            country_counts = groupcounts(obj.dataTable(complete_responses,:),...
                'Country_childhood');
            country_counts.('Country_childhood') = string(country_counts.('Country_childhood'));
            country_counts = sortrows(country_counts,-2);
            thx = 10;
            disp(['Displaying countries with more than ' num2str(thx) ' participants']);
            country_counts = country_counts(find(country_counts.GroupCount>=thx),:);
            disp(country_counts);
        end
        function obj = discard_missing_data(obj)
            N = height(obj.dataTable);
            disp('*** Discard Incomplete Responses ***')
            disp(['---Total responses: ' num2str(N)]);
            disp('Keeping only responses with complete MLH and Demographic parts')
            complete_responses = cell2mat(arrayfun(@(x) ~isempty(x{1}), ...
                obj.dataTable{:,'Country_childhood'},'Uni',false));
            obj.dataTable = obj.dataTable(complete_responses,:);
            N = height(obj.dataTable);
            disp(['---Complete responses: ' num2str(N)]);
            disp('')
        end
        function obj = age_distribution(obj)
            m_Age = mean(obj.dataTable.Age);
            sd_Age = std(obj.dataTable.Age);
            disp('*** AGE distribution ***')
            disp(array2table([m_Age, sd_Age],'VariableNames',{'Mean','SD'}))
            %Age distribution across languages
            %figure
            %boxplot(obj.dataTable.Age,obj.dataTable.language)
            %xlabel('Languages');ylabel('Age');
            %title('Boxplots per language');
            %snapnow
            countries_N = groupcounts(obj.dataTable,'Country_childhood');
            %find countries with enough participants
            countries_N = table2array(countries_N(table2array(countries_N(:,2))>=30,1));
            all_idx = cellfun(@(x) find(strcmp(x, obj.dataTable.Country_childhood)),...
                countries_N, 'UniformOutput', false);
            idx_c = [];
            for i=1:length(all_idx)
                idx_c = [idx_c; all_idx{i}];
                stats_c(i,1) = mean(obj.dataTable.Age(all_idx{i}));
                stats_c(i,2) = std(obj.dataTable.Age(all_idx{i}));
                %figure
                %histogram(obj.dataTable.Age(all_idx{i}))
                %xlabel('Age (in years)'); ylabel('Number of responders');
                %title([countries_N])
            end
            disp(array2table(stats_c,'VariableNames',{'Mean','SD'},'RowNames',countries_N))
            figure
            histogram(obj.dataTable.Age);
            xlabel('Age (in years)'); ylabel('Number of responders');
            title('Age Histogram')
            snapnow
            figure
            boxplot(obj.dataTable.Age(idx_c),obj.dataTable.Country_childhood(idx_c))
            xlabel('Countries');ylabel('Age');xtickangle(45)
            title('Boxplots per Country');
            snapnow
        end
        function obj = gender_distribution(obj)
            disp('*** GENDER distribution ***')
            gender_N = groupcounts(obj.dataTable,'Gender');
            disp(gender_N)
            if strcmpi(obj.filterMethod,'BalancedSubgroups')
                %calculate gender balance in each group
                for i=1:length(obj.subgroupNames)
                    genderG = groupcounts(obj.groupTable(matches(obj.groupTable.(obj.groupingCategory),...
                        obj.subgroupNames{i}),'Gender'),'Gender');
                    f_idx = find(strcmpi(table2array(genderG(:,1)),'Female'));
                    m_idx = find(strcmpi(table2array(genderG(:,1)),'Male'));
                    genderGt(:,i) = genderG.GroupCount([f_idx m_idx]);
                    genderRatio(:,i) = genderG.GroupCount(1:2)*100/sum(genderG.GroupCount);
                end
                t = array2table([genderGt',genderRatio'],'VariableNames',[obj.genderLabels(1:2),...
                    'Female (%)','Male (%)'], 'RowNames',obj.subgroupNames);
                disp('Gender balance for each country')
                disp(t);
            end
        end
        function obj = survey_duration(obj)
            disp('---Removing responses with low survey duration');
            disp(['Removing responses under: ' num2str(obj.durationThr) ' minutes']);
            obj.dataTable.Duration = minutes(obj.dataTable{:,'EndDate'} - ...
                obj.dataTable{:,'StartDate'});
            %exclude responses above 30 minutes
            dur = obj.dataTable.Duration(obj.dataTable.Duration<30);
            if obj.excludeShortResponses
                disp(['Excluding ' num2str(sum(obj.dataTable.Duration<obj.durationThr)) ...
                    ' responses for short duration']);
                obj.dataTable = obj.dataTable(~(obj.dataTable.Duration<obj.durationThr),:);
            end
            if obj.showPlots == 1
                figure,histogram(dur);
                xline(obj.durationThr,'k--')
                h = text(obj.durationThr+0.5,200,'Exclusion Threshold','FontSize',10);
                set(h,'Rotation',90);
                xlabel('Duration in minutes'); ylabel('Number of responses')
                title('Survey Duration')
                snapnow
            end
        end
        function obj = responderVariability(obj)
            for i=1:size(obj.dataTable)
                %HARDCODED LOCATION OF EMOTIONS
                responderVariability(i) = std(table2array(obj.dataTable(i,16:48)));
            end
            disp('---Removing responses based on Responder Variability')
            disp('Threshold: 3 Median Absolute Deviations below median')
            %isoutlier(responderVariability)
            MAD_limit = 1.4826*median(abs(responderVariability-...
                median(responderVariability)))*3; %Median Absolute deviation formula
            thresh = median(responderVariability)-MAD_limit;
            %find responses with LOW variability
            outliers_idx = responderVariability<thresh;
            obj.dataTable = obj.dataTable(~outliers_idx,:);
            disp(['Excluding ' num2str(sum(outliers_idx)) ' responses for low variability']);
            if obj.showPlots == 1
                figure,histogram(responderVariability)
                xline(thresh,'k--')
                h = text(thresh+0.03,100,'Exclusion Threshold','FontSize',10);
                set(h,'Rotation',90);
                xlabel('Standard deviation')
                ylabel('Number of responders')
                title('Standard deviation of emotion ratings for each responder')
            end
            snapnow
        end
        function obj = exclude_from_file(obj)
            faultyIDs = table2array(readtable(obj.excludeResponsesPath));
            [c,idx] = setdiff(table2array(obj.dataTable(:,'RespondentID')),faultyIDs');
            obj.dataTable = obj.dataTable(idx,:);
            if obj.showPlots==1
                disp('*** Outlier Detection ***')
                disp('3 criteria: Survey duration, low variability, repeated entry(based on participant ID)')
                disp('---Removing responses based on ID')
                disp([num2str(length(faultyIDs)) ' responses removed from ID'])
            end
        end
        function obj = create_groupTable(obj)
            g = groupcounts(obj.dataTable,obj.groupingCategory);
            obj.subgroupNames = g.(obj.groupingCategory)(g.GroupCount >= ...
                obj.subgroupMinNumber);
            obj.groupTable = obj.dataTable(matches(obj.dataTable.(obj.groupingCategory), ...
                obj.subgroupNames),:);
        end
        function obj = create_balanced_subgroups(obj)
            %remove Other gender
            obj.groupTable = obj.groupTable(~matches(obj.groupTable.Gender, ...
                'Other'),:);
            g = groupcounts(obj.groupTable,obj.groupingCategory);
            partitionSizes = g.GroupCount;
            [~, smallestPartitionIdx] = min(partitionSizes);
            for i=1:length(obj.subgroupNames)
                age{i} = table2array(obj.groupTable(matches(obj.groupTable.(obj.groupingCategory),...
                    obj.subgroupNames{i}),{'Age'}));
                gender{i} = table2array(obj.groupTable(matches(obj.groupTable.(obj.groupingCategory),...
                    obj.subgroupNames{i}),{'Gender'}));
                respondentID{i} = table2array(obj.groupTable(matches(obj.groupTable.(obj.groupingCategory),...
                    obj.subgroupNames{i}),{'RespondentID'}));
            end
            ageSP = age{smallestPartitionIdx};
            otherPartitionsIdx = find(partitionSizes ~= partitionSizes(smallestPartitionIdx));
            %Start repetitions to find optimal subgroups minimizing
            %AGE-GENDER differences
            ii = 1;
            if exist(obj.subgroupIdxsPath)
                load(obj.subgroupIdxsPath);
                genderRatioMin = subsampling.genderRatio;
                etaSquareMin = subsampling.etaSquare;
            else
                genderRatioMin = 1; %Initiate repetitions with MAX parameter values
                etaSquareMin = 1;
            end
            for j = 1:obj.repetitions
                [a, curIdx] = arrayfun(@(x) datasample(age{x},numel(ageSP),'Replace',false),otherPartitionsIdx,'un',0);
                [~,tbl] = anova1(cell2mat([a' {ageSP}]),[],'off');
                fStat(ii) = tbl{2,5}; % anova F-statistic
                SScol = tbl{2,2}; SStotal = tbl{4,2};
                etaSquare = SScol/SStotal;
                i = 1;
                for k = otherPartitionsIdx'
                    t = tabulate(gender{k}(curIdx{i}));
                    f_idx = find(strcmpi(t(:,1),'Female'));
                    m_idx = find(strcmpi(t(:,1),'Male'));
                    i = i + 1;
                    tf(k) = t{f_idx,3};
                    tm(k) = t{m_idx,3};
                end
                tS = tabulate(gender{smallestPartitionIdx});
                tf(smallestPartitionIdx) = tS{1,3};
                tm(smallestPartitionIdx) = tS{2,3};
                %genderRatio(ii) = std(tf-tm); % standard deviation of the
                % partition-wise gender ratios
                genderRatio = sum(abs(tf-tm)/100)/length(obj.subgroupNames); %difference between gender ratios
                if (genderRatio*etaSquare < genderRatioMin*etaSquareMin)...
                        && genderRatio*etaSquare ~= 0
                    idx = curIdx;
                    disp(join([string(datetime) num2str(min(genderRatio))...
                        num2str(min(etaSquare)) num2str(j)]))
                    etaSquareMin = etaSquare;
                    genderRatioMin = genderRatio;
                    ii = 2;
                    ANOVAtbl = tbl;
                elseif genderRatio*etaSquare == 0
                    error('We went to zero')
                else
                    ii = ii+1;
                end
            end
            %convert subgroup indexes to respondent IDS
            k=1;
            for i=otherPartitionsIdx'
                groupIDs{k} = respondentID{i}(idx{k});
                k=k+1;
            end
            groupIDs{i} = table2array(obj.groupTable(matches(obj.groupTable.(obj.groupingCategory),...
                obj.subgroupNames{smallestPartitionIdx}),'RespondentID'));
            groupIDs = cell2mat(groupIDs);
            groupIDs = groupIDs(:);
            %save all subsampling info in a structure
            subsampling.subgroupIds = groupIDs;
            subsampling.otherPartitionsIdx = otherPartitionsIdx;
            subsampling.smallestPartitionIdx = smallestPartitionIdx;
            subsampling.partitionSizes = partitionSizes;
            subsampling.ANOVAtbl = ANOVAtbl;
            subsampling.genderRatio = genderRatioMin;
            subsampling.etaSquare = etaSquareMin;
            subsampling.countryNames = obj.subgroupNames;
            subsampling.groupingCategory = obj.groupingCategory;
            if obj.exportSubgroups
                save(obj.subgroupIdxsPath,'subsampling');
            end
        end
        function obj = load_subgroups(obj)
            load(obj.subgroupIdxsPath);
            obj.subgroupNames = subsampling.countryNames;
            obj.groupingCategory = subsampling.groupingCategory;
            obj.subgroupIds = subsampling.subgroupIds;
            if obj.showPlots == 1
                disp(['*** AGE-GENDER Subsampling Results ***'])
                disp(['Number of iterations: ' num2str(obj.repetitions)])
                %disp(['Participants per country: ' num2str(length(obj.subgroupIds{1}))])
                disp('---AGE')
                disp(['ANOVA table for age comparison between groups, ' ,...
                    'IV: Country (Childhood), DV: Age'])
                disp(subsampling.ANOVAtbl)
                disp(['Eta square: ' num2str(subsampling.etaSquare)])
                disp('')
                disp('---GENDER')
                disp('Gender ratio: Mean Difference between gender ratios')
                disp(['Gender ratio: ' num2str(subsampling.genderRatio)]);
            end
            [~,tidx]=intersect(table2array(obj.dataTable(:,'RespondentID')),obj.subgroupIds);
            obj.groupTable = obj.dataTable(tidx,:);
        end
        function obj = age_subgroups(obj)
            m_Age = mean(obj.groupTable.Age);
            sd_Age = std(obj.groupTable.Age);
            disp('*** Age distribution POST SUBSAMPLING ***')
            disp(array2table([m_Age, sd_Age],'VariableNames',{'Mean','SD'}))
            figure
            histogram(obj.groupTable.Age);
            xlabel('Age (in years)'); ylabel('Number of responders');
            title('Age Histogram POST SUBSAMPLING')
            snapnow
            countries_N = groupcounts(obj.groupTable,'Country_childhood');
            %find countries with enough participants
            countries_N = table2array(countries_N(table2array(countries_N(:,2))>=obj.subgroupMinNumber,1));
            all_idx = cellfun(@(x) find(strcmp(x, obj.groupTable.Country_childhood)),...
                countries_N, 'UniformOutput', false);
            idx_c = [];
            for i=1:length(all_idx)
                idx_c = [idx_c; all_idx{i}];
                stats_post(i,1) = mean(obj.groupTable.Age(all_idx{i}));
                stats_post(i,2) = std(obj.groupTable.Age(all_idx{i}));
            end
            disp(array2table(stats_post,'VariableNames',{'Mean','SD'},'RowNames',countries_N))
            figure
            boxplot(obj.groupTable.Age(idx_c),obj.groupTable.Country_childhood(idx_c))
            xlabel('Countries');ylabel('Age'); xtickangle(45)
            title('Boxplots per Country POST SUBSAMPLING');
            snapnow
            %Find mean age from DATATABLE PRE SUBSAMPLING
            all_idx = cellfun(@(x) find(strcmp(x, obj.dataTable.Country_childhood)),...
                countries_N, 'UniformOutput', false);
            idx_c = [];
            for i=1:length(all_idx)
                idx_c = [idx_c; all_idx{i}];
                stats_pre(i,1) = mean(obj.dataTable.Age(all_idx{i}));
                stats_pre(i,2) = std(obj.dataTable.Age(all_idx{i}));
            end
            %compare pre-post
            pre = stats_pre;
            post = stats_post;
            figure, hold on
            p=plot([pre(:,1),post(:,1)]);
            yline(m_Age, 'k--')
            text(length(obj.subgroupNames)/2,m_Age-0.3,'Grand Mean')
            ylabel('Mean age'); xlabel('Country (Childhood)');
            title('Age distribution Pre-Post subsampling')
            legend(p,'Pre','Post')
            set(gca,'XTick',1:length(obj.subgroupNames),'XTickLabels',obj.subgroupNames),xtickangle(45)
            hold off
            %plotstds
            %errorbar([pre(:,1),post(:,1)],[pre(:,2),post(:,2)]/2,'-s','markersize',7,...
            %'markeredgecolor','k','markerfacecolor','k','linewidth',1.5);
            snapnow
        end
        function obj = gender_subgroups(obj)
            genderN = groupcounts(obj.groupTable,'Gender');
            disp('*** Gender distribution POST SUBSAMPLING ***')
            disp(genderN)
            %calculate gender balance in each group POST SUBSAMPLING
            for i=1:length(obj.subgroupNames)
                genderG = groupcounts(obj.groupTable(matches(obj.groupTable.(obj.groupingCategory),...
                    obj.subgroupNames{i}),'Gender'),'Gender');
                f_idx = find(strcmpi(table2array(genderG(:,1)),'Female'));
                m_idx = find(strcmpi(table2array(genderG(:,1)),'Male'));
                genderGtPost(i,:) = genderG.GroupCount([f_idx m_idx]);
                genderRatioPost(i,:) = genderG.GroupCount(1:2)*100/sum(genderG.GroupCount);
            end
            t = array2table([genderGtPost,genderRatioPost],'VariableNames',[obj.genderLabels(1:2),...
                'Female (%)','Male (%)'], 'RowNames',obj.subgroupNames);
            disp('Gender balance for each country')
            disp(t);
            %calculate gender balance in each group PRE SUBSAMPLING
            for i=1:length(obj.subgroupNames)
                genderG = groupcounts(obj.dataTable(matches(obj.dataTable.(obj.groupingCategory),...
                    obj.subgroupNames{i}),'Gender'),'Gender');
                f_idx = find(strcmpi(table2array(genderG(:,1)),'Female'));
                m_idx = find(strcmpi(table2array(genderG(:,1)),'Male'));
                genderGtPre(i,:) = genderG.GroupCount([f_idx m_idx]);
                genderRatioPre(i,:) = genderG.GroupCount(1:2)*100/sum(genderG.GroupCount);
            end
            genderRatioDiffPre = genderRatioPre(:,1)-genderRatioPre(:,2);
            genderRatioDiffPost = genderRatioPost(:,1)-genderRatioPost(:,2);
            %plot PRE-POST Gender differences
            figure
            hold on
            p = plot([genderRatioDiffPre,genderRatioDiffPost]);
            yline(0, 'k--')
            text(length(obj.subgroupNames)/2,-5,'Equally balanced groups')
            ylabel('Male - Female difference (%)'); xlabel('Country (Childhood)');
            title('Gender Balance Pre-Post subsampling')
            legend(p,'Pre','Post')
            set(gca,'XTick',1:length(obj.subgroupNames),'XTickLabels',obj.subgroupNames),xtickangle(45)
            hold off
        end
    end
end
