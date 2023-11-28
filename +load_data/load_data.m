classdef load_data
    %Load data
    %example obj = load_data.load_data();obj = do_load_data(obj);
    properties
        dataPath = 'responses_pilot/Music Listening Habits.csv';
        filterMethod = 'AllResponses' % Accepted Inputs: 'AllResponses','BalancedSubgroups', 'UnbalancedSubgroups', 'BalancedSubgroups_only_natives'
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
        TIPIscalesNames = {'Extraversion','Agreeableness','Conscientiousness','Emotional_Stability','Openness_Experiences'};
        ICscalesNames = {'Horizontal_individualism','Vertical_individualism','Horizontal_collectivism','Vertical_collectivism'};
        icVars
        durationThr = 5; %Duration Threshold to exclude responses (in minutes)
        excludeShortResponses = 1; %Exclude responses below duration threshold
        excludeRepetativeResponses = 1; %Exclude responses with repetative answers
        excludeResponsesFromFile = 1;
        excludeResponsesPath = 'responses_pilot/faulty ids.xlsx';
        excludeAge = 16;
        %filterMethod %Accepted Inputs: 'AllResponses','BalancedSubgroups',
        createBalancedSubgroups = 0; % create subgroups through permutations
        groupingCategory = 'Country_childhood';
        balanceVariables = {'Gender','Age'}; %variables to be equalised across groups
        ageMetricMethod = 'groupSD'%'etaSq'
        subgroupNames %Country group names
        subgroupMinNumber = 70;
        subgroupSubSamplingSize = 70; %Group size post subsampling
        subgroupIds %ids of selected subgroup responses
        repetitions = 1E+6; %number of permutations
        exportSubgroups = 0;
        subgroupIdxsPath = []; %'subsampling/subsampling.mat'; %mat file with subgroup indexes
        createExcel = 1; %Create excel file with preprocessed data;
        showPlotsAndText = 1; %Display plots, tables, and text
    end
    methods
        function obj = load_data(obj)
        end
        function obj = do_load_data(obj)
            warning('OFF', 'MATLAB:table:ModifiedAndSavedVarnames')
            obj = get_variable_names(obj);
            obj = correct_variables(obj);
            if obj.discardMissingData ==1
                obj = discard_missing_data(obj);
            end
            if obj.excludeResponsesFromFile==1
                disp('*** Outlier Removal ***')
                disp('4 criteria: Survey duration, low variability, age, repeated entry(based on participant ID)')
                obj = find_repeated_responses(obj);
                obj = exclude_from_file(obj);
                obj = find_repeated_responses(obj);
            end
            if obj.excludeShortResponses ==1
                obj = survey_duration(obj);
            end
            if  obj.excludeRepetativeResponses
                obj = responderVariability(obj);
            end
            obj = exclude_age(obj);
            if ~strcmpi(obj.filterMethod,'AllResponses')
                obj = create_groupTable(obj);
            end
            if obj.showPlotsAndText == 1
                obj = count_participants(obj);
                obj = age_distribution(obj);
                obj = gender_distribution(obj);
                obj = country_venn_diagrams(obj);
                obj = language_consistency(obj);
            end
            if (strcmpi(obj.filterMethod,'BalancedSubgroups')|| strcmpi(obj.filterMethod,'BalancedSubgroups_only_natives'))...
                    && obj.createBalancedSubgroups == 1
                obj = get_baselines(obj);
                obj = create_balanced_subgroups(obj);
            end
            if exist(obj.subgroupIdxsPath) && (strcmpi(obj.filterMethod,'BalancedSubgroups') || strcmpi(obj.filterMethod,'BalancedSubgroups_only_natives'))
                obj = load_balanced_subgroups(obj);
            end
            if obj.showPlotsAndText==1 && (strcmpi(obj.filterMethod,'BalancedSubgroups') || strcmpi(obj.filterMethod,'BalancedSubgroups_only_natives'))
                obj = age_subgroups(obj);
                %obj = gender_subgroups(obj);
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
            %correct aggresion
            if sum(strcmpi('Agression',obj.dataTable.Properties.VariableNames))
                i = find(strcmpi('Agression',obj.dataTable.Properties.VariableNames));
                obj.dataTable.Properties.VariableNames{i} = 'Aggresion';
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


            % add TIPI scores
            tipiVars = {'Extraverted_Enthusiastic',
                'Critical_Quarrelsome',
                'Dependable_Self_disciplined',
                'Anxious_EasilyUpset',
                'OpenToNewExperiences_Complex',
                'Reserved_Quiet',
                'Sympathetic_Warm',
                'Disorganized_Careless',
                'Calm_EmotionallyStable',
                'Conventional_Uncreative'};
            tipiVarsData = obj.dataTable(:,matches(obj.dataTable.Properties.VariableNames,tipiVars));
            tipiCompleteLogical = any(~isnan(tipiVarsData{:,:}),2);
            tipiVarsDataComplete = tipiVarsData(tipiCompleteLogical,:);
            reverseScoredItemNums = 2:2:10;
            tipiVarsDataCompleteRecoded = tipiVarsDataComplete;
            recodeScheme = 7:-1:1;
            reverseScoredItemNums = 2:2:10;
            tipiVarsDataCompleteRecoded{:,reverseScoredItemNums} = recodeScheme(tipiVarsDataComplete{:,reverseScoredItemNums});
            scalesItems = reshape(1:10,[],2);
            for k = 1:numel(obj.TIPIscalesNames)
                curVar = nan(size(tipiCompleteLogical));
                scores = mean(tipiVarsDataCompleteRecoded{:,scalesItems(k,:)},2);
                TIPI(:,k) = scores;
                curVar(tipiCompleteLogical) = scores;
                obj.dataTable = addvars(obj.dataTable,curVar,'NewVariableNames',obj.TIPIscalesNames{k});
            end
            [m I] =  max(TIPI,[],2,'includenan');
            curVar = strings(size(tipiCompleteLogical));
            curVar(tipiCompleteLogical) = obj.TIPIscalesNames(I);
            obj.dataTable = addvars(obj.dataTable,categorical(curVar),'NewVariableNames','TIPICategory');

            %obj.dataTable = removevars(obj.dataTable,tipiVars);

            % add horizontal/vertical individualism collectivism scores (just based on computing
            % means on the items that loaded most for each factor
            % in Triandis and Gelfand, 1998)
            obj.icVars = {'I_dRatherDependOnMyselfThanOthers'
                'IRelyOnMyselfMostOfTheTime_IRarelyRelyOnOthers'
                'IOftenDo_myOwnThing_'
                'MyPersonalIdentity_IndependentOfOthers_IsVeryImportantToMe'
                'ItIsImportantThatIDoMyJobBetterThanOthers'
                'WinningIsEverything'
                'CompetitionIsTheLawOfNature'
                'WhenAnotherPersonDoesBetterThanIDo_IGetTenseAndAroused'
                'IfAColleagueGetsAPrize_IWouldFeelProud'
                'TheWell_beingOfMyColleaguesIsImportantToMe'
                'ToMe_PleasureIsSpendingTimeWithOthers'
                'IFeelGoodWhenICooperateWithOthers'
                'ParentsAndChildrenMustStayTogetherAsMuchAsPossible'
                'ItIsMyDutyToTakeCareOfMyFamily_EvenWhenIHaveToSacrificeWhatIWan'
                'FamilyMembersShouldStickTogether_NoMatterWhatSacrificesAreRequi'
                'ItIsImportantToMeThatIRespectTheDecisionsMadeByMyGroups'};
            icVarsData = obj.dataTable(:,matches(obj.dataTable.Properties.VariableNames,obj.icVars));
            icCompleteLogical = any(~isnan(icVarsData{:,:}),2);
            icVarsDataComplete = icVarsData(icCompleteLogical,:);
            scalesItems = reshape(1:16,[],4);
            for k = 1:numel(obj.ICscalesNames)
                curVar = nan(size(icCompleteLogical));
                scores = sum(icVarsDataComplete{:,scalesItems(:,k)},2);
                IC(:,k) = scores;
                curVar(icCompleteLogical) = scores;
                obj.dataTable = addvars(obj.dataTable,curVar,'NewVariableNames',obj.ICscalesNames{k});
            end
            [m I] =  max(IC,[],2,'includenan');
            curVar = strings(size(icCompleteLogical));
            curVar(icCompleteLogical) = obj.ICscalesNames(I);
            obj.dataTable = addvars(obj.dataTable,categorical(curVar),'NewVariableNames','IndColCategory');
            %obj.dataTable = removevars(obj.dataTable,icVars);
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


            %make pie chart of countries
            idx = find(country_counts{:,3}>3);
            country_counts = country_counts(idx,:);
            country_counts{end+1,1} = {'Other'};country_counts{end,2} = N_complete - sum(table2array(country_counts(:,2)));
            country_counts{end,3} = country_counts{end,2}/N_complete*100;

            %pie

            figure
            subplot(1,2,1)
            bs = brewermap(height(language_counts)+6,'Blues');
            bs = bs([1,3,5:height(language_counts)+2],:); %%HARDCODED
            language_full_name = {'English','Lithuanian','Spanish','French','Russian','Greek','Turkish','Finnish',...
                'Chinese','German','Portuguese'}%%HARDCODED
            for i = 1:height(language_counts)
                labels{i} =  [language_full_name{i}, '\newline',' ', num2str(round(language_counts{i,3},1)), '%'];
            end
            ax = gca();
            h = pie(language_counts{:,3},labels);
            set(findobj(h,'type','text'),'fontsize',20);
            ax.Colormap = bs;
            title('a) Language','Units', 'normalized', 'Position', [0.5, 1.1, 1],'FontSize',24)

            subplot(1,2,2)
            bs = brewermap(height(country_counts)+3,'Blues');
            bs = bs(1:height(country_counts),:);
            for i = 1:height(country_counts)
                labels{i} =  [char(country_counts{i,1}), '\newline',char(' '), char(num2str(round(country_counts{i,3},1))), char('%')];
            end
            ax = gca();
            h = pie(country_counts{:,3},labels);
            set(findobj(h,'type','text'),'fontsize',20);
            ax.Colormap = bs;
            title('b) Country of Upbringing','Units', 'normalized', 'Position', [0.5, 1.1, 1],'FontSize',24)
        end
        function obj = discard_missing_data(obj)
            N = height(obj.dataTable);
            if obj.showPlotsAndText == 1
                disp('*** Discard Incomplete Responses ***')
                disp(['---Total responses: ' num2str(N)]);
                disp('Keeping only responses with complete MLH and Demographic parts')
            end
            complete_responses = cell2mat(arrayfun(@(x) ~isempty(x{1}), ...
                obj.dataTable{:,'Country_childhood'},'Uni',false));
            obj.dataTable = obj.dataTable(complete_responses,:);
            N = height(obj.dataTable);
            if obj.showPlotsAndText == 1
                disp(['---Complete responses: ' num2str(N)]);
                disp('')
            end
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
            boxplot(obj.dataTable.Age(idx_c),obj.dataTable.Country_childhood(idx_c))
            %h = boxplot(obj.dataTable.Age(idx_c),obj.dataTable.Country_childhood(idx_c),'OutlierSize',12);
            %set(h,{'linew'},{4})
            %set(gca,'FontSize',32,'LineWidth',2)
            xlabel('Countries');ylabel('Age');xtickangle(45)
            title('Boxplots per Country');
            snapnow
        end
        function obj = gender_distribution(obj)
            disp('*** GENDER distribution ***')
            gender_N = groupcounts(obj.dataTable,'Gender');
            disp(gender_N)
            %calculate gender balance in each group
            if ~strcmpi(obj.filterMethod,'AllResponses')
                for i=1:length(obj.subgroupNames)
                    genderG = groupcounts(obj.groupTable(matches(obj.groupTable.(obj.groupingCategory),...
                        obj.subgroupNames{i}),'Gender'),'Gender');
                    f_idx = find(strcmpi(table2array(genderG(:,1)),'Female'));
                    m_idx = find(strcmpi(table2array(genderG(:,1)),'Male'));
                    genderGt(:,i) = genderG.GroupCount([f_idx m_idx]);
                    genderMetric(:,i) = genderG.GroupCount(1:2)*100/sum(genderG.GroupCount);
                end
                t = array2table([genderGt',genderMetric'],'VariableNames',[obj.genderLabels(1:2),...
                    'Female (%)','Male (%)'], 'RowNames',obj.subgroupNames);
                disp('Gender balance for each country')
                disp(t);
            end
        end
        function obj = country_venn_diagrams(obj)
            % all participants
            v1 = find(string(obj.dataTable.Country_childhood)==string(obj.dataTable.Country_adulthood));
            v2 = find(string(obj.dataTable.Country_childhood)==string(obj.dataTable.Country_identity));
            v3 = find(string(obj.dataTable.Country_identity)==string(obj.dataTable.Country_adulthood));
            v4 = intersect(v1,v2);
            N = height(obj.dataTable);
            figure
            venn([N/N,N/N,N/N],[length(v1)/N,length(v2)/N,length(v3)/N,length(v4)/N],...
                'ErrMinMode','ChowRodgers');
            legend({'Childhood','Adulthood','Identity'},'Location','best')
            set(gca,'FontSize',24,'LineWidth',2,'XTick',[],'YTick',[]);
            %title('Venn Diagram of Country overlap')
            box on
            snapnow
            if ~strcmpi(obj.filterMethod,'AllResponses')
            %for each country
            figure
            groupNum = length(obj.subgroupNames);
            tcl=tiledlayout(4,ceil(groupNum/4))
            nexttile(tcl)
            venn([N/N,N/N,N/N],[length(v1)/N,length(v2)/N,length(v3)/N,length(v4)/N],...
                'ErrMinMode','TotalError');
            set(gca,'FontSize',24,'LineWidth',2,'XTick',[],'YTick',[]);
            title('All participants')
            axis([-0.8 0.8 -0.8 0.8])
            box on
            for i = 1:length(obj.subgroupNames)
                idx_child = find(strcmpi(obj.groupTable.Country_childhood,obj.subgroupNames{i}));
                idx_adult = find(strcmpi(obj.groupTable.Country_adulthood,obj.subgroupNames{i}));
                idx_identity = find(strcmpi(obj.groupTable.Country_identity,obj.subgroupNames{i}));
                v1 = intersect(idx_child,idx_adult);
                v2 = intersect(idx_child,idx_identity);
                v3 = intersect(idx_identity,idx_adult);
                v4 = intersect(v1,v2);
                total_length = length(idx_child)+length(idx_adult)+length(idx_identity);
                nexttile(tcl)
                title(obj.subgroupNames{i})
                venn([length(idx_child)/total_length,length(idx_adult)/total_length,length(idx_identity)/total_length],...
                    [length(v1)/total_length,length(v2)/total_length,length(v3)/total_length,length(v4)/total_length],'ErrMinMode','TotalError');
                set(gca,'FontSize',24,'LineWidth',2,'XTick',[],'YTick',[]);
                axis([-0.42 0.42 -0.42 0.42])
                box on
            end
            legend({'Childhood','Adulthood','Identity'},'Location','eastoutside')
            end
        end
        function obj = survey_duration(obj)
            obj.dataTable.Duration = minutes(obj.dataTable{:,'EndDate'} - ...
                obj.dataTable{:,'StartDate'});
            %exclude responses above 30 minutes
            dur = obj.dataTable.Duration(obj.dataTable.Duration<30);
            if obj.showPlotsAndText == 1
                disp('---Removing responses with low survey duration');
                disp(['Removing responses under: ' num2str(obj.durationThr) ' minutes']);
            end
            if obj.excludeShortResponses
                if obj.showPlotsAndText == 1
                    disp(['Excluding ' num2str(sum(obj.dataTable.Duration<obj.durationThr)) ...
                        ' responses for short duration']);
                end
                obj.dataTable = obj.dataTable(~(obj.dataTable.Duration<obj.durationThr),:);
            end
            if obj.showPlotsAndText == 1
                figure
                %histogram(dur);
                histogram(dur,'LineWidth',2);
                set(gca,'FontSize',32,'LineWidth',2)
                xline(obj.durationThr,'k--','LineWidth',4)
                %xline(obj.durationThr,'k--')
                %h = text(obj.durationThr+0.5,150,'Exclusion Threshold','FontSize',10);
                h = text(obj.durationThr+0.5,120,'Exclusion Threshold','FontSize',16);
                set(h,'Rotation',90);
                xlabel('Duration in minutes'); ylabel('Number of responses')
                %title('Survey Duration')
                snapnow
            end
        end
        function obj = responderVariability(obj)
            for i=1:size(obj.dataTable)
                %HARDCODED LOCATION OF EMOTIONS
                responderVariability(i) = std(table2array(obj.dataTable(i,16:48)));
            end
            %isoutlier(responderVariability)
            MAD_limit = 1.4826*median(abs(responderVariability-...
                median(responderVariability)))*3; %Median Absolute deviation formula
            thresh = median(responderVariability)-MAD_limit;
            %find responses with LOW variability
            outliers_idx = responderVariability<thresh;
            obj.dataTable = obj.dataTable(~outliers_idx,:);
            if obj.showPlotsAndText == 1
                disp('---Removing responses based on Responder Variability')
                disp('Threshold: 3 Median Absolute Deviations below median')
                disp(['Excluding ' num2str(sum(outliers_idx)) ' responses for low variability']);
            end
            if obj.showPlotsAndText == 1
                figure
                %histogram(responderVariability)
                histogram(responderVariability,'LineWidth',2)
                set(gca,'FontSize',32,'LineWidth',2)
                xline(thresh,'k--','LineWidth',4)
                %h = text(thresh+0.03,100,'Exclusion Threshold','FontSize',10);
                h = text(thresh+0.03,100,'Exclusion Threshold','FontSize',16);
                set(h,'Rotation',90);
                xlabel('Standard deviation')
                ylabel('Number of responses')
                title('Standard Deviation of Emotion Ratings')
                snapnow
            end
        end
        function obj = exclude_age(obj)
            idx = find(obj.dataTable.Age>=obj.excludeAge);
            if obj.showPlotsAndText == 1
                disp('---Removing responses based on Age')
                disp(['Age Threshold: ' num2str(obj.excludeAge)])
                disp(['Excluding ' num2str(height(obj.dataTable)-length(idx)) ' responses'])
                figure
                %histogram(obj.dataTable.Age);
                histogram(obj.dataTable.Age,'LineWidth',2);
                set(gca,'FontSize',32,'LineWidth',2)
                %xline(obj.excludeAge,'k--')
                xline(obj.excludeAge,'k--','LineWidth',5)
                %h = text(obj.excludeAge-3,50,'Exclusion Threshold','FontSize',10);
                h = text(obj.excludeAge-3,50,'Exclusion Threshold','FontSize',16);
                set(h,'Rotation',90);
                xlabel('Age (in years)'); ylabel('Number of responders');
                %title('Age Histogram')
                snapnow
            end
            obj.dataTable = obj.dataTable(idx,:);
        end
        function obj = find_repeated_responses(obj)
            [artistCount, artist] = groupcounts(obj.dataTable.Artist);
            artistT = table(artistCount, artist,'VariableNames',{'Count','Artist'});
            artistT = sortrows(artistT,1,'descend');
            topArtist = artistT(1:10,:);
            dur = duration(0,30,0);
            if obj.showPlotsAndText ==1
                figure
                h=histogram(obj.dataTable.EndDate,'BinWidth',dur);
                title('Histogram of responses in time')
                snapnow
                [BinCounts,idx] = sort(h.BinCounts,'descend');
                timesToCheck = h.BinEdges(idx(1:20));
                BinCounts = BinCounts(1:30);
                %disp(timesToCheck')
                disp('Top Artists')
                disp(topArtist)
            end
        end
        function obj = exclude_from_file(obj)
            faultyIDs = table2array(readtable(obj.excludeResponsesPath));
            [c,idx] = setdiff(table2array(obj.dataTable(:,'RespondentID')),faultyIDs');
            obj.dataTable = obj.dataTable(idx,:);
            if obj.showPlotsAndText==1
                disp('*** Outlier Detection ***')
                disp('3 criteria: Survey duration, low variability, repeated entry(based on participant ID)')
                disp('---Removing responses based on ID')
                disp([num2str(length(faultyIDs)) ' responses removed from ID'])
            end
        end
        function obj = language_consistency(obj)
            %HARDCODED LOCATION OF EMOTIONS
            emo = obj.dataTable{:,16:48};
            emoLabels = obj.dataTable.Properties.VariableNames(16:48);% emotion terms (obj.dataTable)
            remove_diagonal = @(t)reshape(t(~diag(ones(1,size(t, 1)))), size(t)-[1 0]);
            languages = unique(obj.dataTable{:,'language'});
            for i = 1:length(languages)
                d(:,i) = rescale(pdist(emo(strcmpi(languages(i),...
                    table2array(obj.dataTable(:,'language'))),:)','euclidean'));
                sqForm{i} = squareform(d(:,i));
                sqForm{i} = remove_diagonal(sqForm{i});
            end
            t_corr = corr(d,'rows','complete');
            figure, hold on
            imagesc(t_corr), colorbar
            ax = gca;
            ax.YTick = 1:length(languages);
            ax.XTick = 1:length(languages);
            ax.YTickLabel = languages;
            ax.XTickLabel = languages;
            ax.XTickLabelRotation = 45;
            hold off
            title('Correlations between languages')
            snapnow
            for i=1:length(sqForm{1})
                dCat{i} = cell2mat(arrayfun(@(x) x{:}(:,i), sqForm, 'UniformOutput', false));
                alpha(i,1) = stats.factor_analysis.cronbach(dCat{i});
            end
            disp('*** CROSS-CULTURAL CONSISTENCY OF EMOTION TERMS ***')
            disp('Running Cronbachs Alpha on pairwise distances vector of each emotion between LANGUAGES')
            t_alpha = array2table(alpha,'VariableNames',{'CronbachAlpha'},'RowNames',emoLabels);
            t_alpha = sortrows(t_alpha,1,'ascend');
            disp(t_alpha)

            figure
            b = barh(table2array(t_alpha),'EdgeColor','k','LineWidth',1.5,'BaseValue',0);
            xlim([0.75 1])
            set(gca,'FontSize',24,'LineWidth',2)
            set(gca,'YTick',1:(height(t_alpha)),'YTickLabels',t_alpha.Properties.RowNames);
            xlabel("Cronbach's Alpha", 'FontSize',32)
            snapnow

            %mean correlations between languages
            for i = 1:length(dCat)
                temp = corr(dCat{i});
                temp = remove_diagonal(temp);
                corr_mat(:,i) = temp(:,1);
            end
            corr_mean = mean(corr_mat);
            figure
            b = barh(corr_mean,'EdgeColor','k','LineWidth',1.5,'BaseValue',0);
            set(gca,'FontSize',24,'LineWidth',2)
            set(gca,'YTick',1:(height(t_alpha)),'YTickLabels',emoLabels);
            snapnow

            %intraclass correlations
            for i = 1:length(dCat)
                iccor(i) = ICC(dCat{i},'C-1');
            end

        end
        function obj = plot_dendrogram_cronbach(obj)
            emo = obj.dataTable{:,16:48};
            emoLabels = obj.dataTable.Properties.VariableNames(16:48);% emotion terms (obj.dataTable)
            %dendrogram
            d_dendrogram = pdist(emo','euclidean');
            l = linkage(d_dendrogram,'average');

            remove_diagonal = @(t)reshape(t(~diag(ones(1,size(t, 1)))), size(t)-[1 0]);
            languages = unique(obj.dataTable{:,'language'});
            for i = 1:length(languages)
                d(:,i) = rescale(pdist(emo(strcmpi(languages(i),...
                    table2array(obj.dataTable(:,'language'))),:)','euclidean'));
                sqForm{i} = squareform(d(:,i));
                sqForm{i} = remove_diagonal(sqForm{i});
            end
            for i=1:length(sqForm{1})
                dCat{i} = cell2mat(arrayfun(@(x) x{:}(:,i), sqForm, 'UniformOutput', false));
                alpha(i,1) = stats.factor_analysis.cronbach(dCat{i});
            end
            t_alpha = array2table(alpha,'VariableNames',{'CronbachAlpha'},'RowNames',emoLabels);
            t_alpha = sortrows(t_alpha,1,'ascend');
            
            figure
            subplot(1,2,1)
            h = dendrogram(l,33,'orientation','right','labels',strrep(emoLabels,'_',' '));
            set(gca,'LineWidth',2,'FontSize',24)
            set(h,'linewidth',3)
            box on
            title('a) Euclidean distances of emotion ratings','FontSize',24)
            subplot(1,2,2)
            b = barh(table2array(t_alpha),'EdgeColor','k','LineWidth',1.5,'BaseValue',0);
            xlim([0.75 1])
            set(gca,'FontSize',24,'LineWidth',2)
            set(gca,'YTick',1:(height(t_alpha)),'YTickLabels',t_alpha.Properties.RowNames);
            title("b) Cronbach's Alpha between languages", 'FontSize',24)
        end
        function obj = create_groupTable(obj)
            if strcmpi(obj.filterMethod,'BalancedSubgroups_only_natives')
               %further remove participants that country of childhood, adulthood, identity do not match 
               natives = []; 
               for i = 1:height(obj.dataTable)
                   if [strcmpi(obj.dataTable.Country_childhood(i),obj.dataTable.Country_adulthood(i)) &&...
                      strcmpi(obj.dataTable.Country_childhood(i),obj.dataTable.Country_identity(i))]
                   natives = [natives, i];  
                   end
               end
               disp(['GroupTable PRE removal of non natives: ', num2str(height(obj.dataTable))])
               obj.groupTable = obj.dataTable(natives,:);
               disp(['GroupTable POST removal of non natives: ', num2str(height(obj.groupTable))])
            else
               obj.groupTable = obj.dataTable; 
            end
            %find groups/countries with minimum N
            g = groupcounts(obj.groupTable,obj.groupingCategory);
            obj.subgroupNames = g.(obj.groupingCategory)(g.GroupCount >= ...
                obj.subgroupMinNumber);
            obj.groupTable = obj.groupTable(matches(obj.groupTable.(obj.groupingCategory), ...
                obj.subgroupNames),:); 
        end
        function obj = create_balanced_subgroups(obj)
            %remove Other gender
            obj.groupTable = obj.groupTable(~matches(obj.groupTable.Gender, ...
                'Other'),:);
            g = groupcounts(obj.groupTable,obj.groupingCategory);
            partitionSize = obj.subgroupSubSamplingSize;
            for i=1:length(obj.subgroupNames)
                age{i} = table2array(obj.groupTable(matches(obj.groupTable.(obj.groupingCategory),...
                    obj.subgroupNames{i}),{'Age'}));
                gender{i} = table2array(obj.groupTable(matches(obj.groupTable.(obj.groupingCategory),...
                    obj.subgroupNames{i}),{'Gender'}));
                respondentID{i} = table2array(obj.groupTable(matches(obj.groupTable.(obj.groupingCategory),...
                    obj.subgroupNames{i}),{'RespondentID'}));
            end
            %Start repetitions to find optimal subgroups minimizing
            %AGE-GENDER differences
            ii = 1;
            obj.subgroupIdxsPath = ['subsampling/',obj.filterMethod, '.mat'];
            if exist(obj.subgroupIdxsPath) ==2
                load(obj.subgroupIdxsPath);
                genderMetricMin = subsampling.genderMetric;
                if strcmpi(obj.ageMetricMethod,'etaSq')
                    ageMetricMin = subsampling.etaSquare;
                elseif strcmpi(obj.ageMetricMethod,'groupSD')
                    ageMetricMin = subsampling.groupSD;
                end
                minMetricMin = subsampling.minMetric;

            else
                minMetricMin = 6; %random large value
            end
            for j = 1:obj.repetitions
                [a, curIdx] = arrayfun(@(x) datasample(age{x},partitionSize,'Replace',false),1:length(age),'un',0);
                groupSD = std(cell2mat(arrayfun(@(x) mean(cell2mat(x)),a,'un',0)));
                [~,tbl] = anova1(cell2mat(a),[],'off');
                fStat(ii) = tbl{2,5}; % anova F-statistic
                SScol = tbl{2,2}; SStotal = tbl{4,2};
                etaSquare = SScol/SStotal;
                if strcmpi(obj.ageMetricMethod,'etaSq')
                    ageMetric = etaSquare;
                elseif strcmpi(obj.ageMetricMethod,'groupSD')
                    ageMetric = groupSD;
                end
                i = 1;
                for k = 1:length(age)
                    t = tabulate(gender{k}(curIdx{i}));
                    f_idx = find(strcmpi(t(:,1),'Female'));
                    m_idx = find(strcmpi(t(:,1),'Male'));
                    i = i + 1;
                    if ~isempty(f_idx)
                        tf(k) = t{f_idx,3};
                    else
                        tf(k) = 0;
                    end
                    if ~isempty(m_idx)
                        tm(k) = t{m_idx,3};
                    else
                        tm(k) = 0;
                    end
                end
                %genderMetric(ii) = std(tf-tm); % standard deviation of the
                % partition-wise gender ratios
                genderMetric = sum(abs(tf-tm)/100)/length(obj.subgroupNames); %difference between gender ratios
                if length(obj.balanceVariables)==2
                    minMetric = genderMetric*ageMetric;
                elseif strcmpi(obj.balanceVariables,'Age')
                    minMetric = ageMetric;
                elseif strcmpi(obj.balanceVariables,'Gender')
                    minMetric = genderMetric;
                end
                if (minMetric < minMetricMin)&& minMetric ~= 0
                    idx = curIdx;
                    disp(join([string(datetime) num2str(minMetric) ...
                        num2str(genderMetric) num2str(ageMetric) num2str(j)]))
                    ageMetricMin = ageMetric;
                    genderMetricMin = genderMetric;
                    minMetricMin = minMetric;
                    ii = 2;
                    ANOVAtbl = tbl;
                elseif minMetric == 0
                    error('We went to zero')
                else
                    ii = ii+1;
                end
            end
            %convert subgroup indexes to respondent IDS
            k=1;
            for i=1:length(age)
                groupIDs{k} = respondentID{i}(idx{k});
                k=k+1;
            end
            groupIDs = cell2mat(groupIDs);
            groupIDs = groupIDs(:);
            %save all subsampling info in a structure
            subsampling.subgroupIds = groupIDs;
            subsampling.partitionSizes = partitionSize;
            subsampling.ANOVAtbl = ANOVAtbl;
            subsampling.genderMetric = genderMetricMin;
            subsampling.ageMetric = ageMetricMin;
            subsampling.minMetric = minMetricMin;
            if strcmpi(obj.ageMetricMethod,'etaSq')
                subsampling.etaSquare = ageMetricMin;
                subsampling.groupSD = NaN;
            elseif strcmpi(obj.ageMetricMethod,'groupSD')
                subsampling.groupSD = ageMetricMin;
                subsampling.etaSquare = NaN;
            end
            subsampling.countryNames = obj.subgroupNames;
            subsampling.groupingCategory = obj.groupingCategory;
            if obj.exportSubgroups
                save(obj.subgroupIdxsPath,'subsampling');
            end
        end
        function obj = load_balanced_subgroups(obj)
            load(obj.subgroupIdxsPath);
            obj.subgroupNames = subsampling.countryNames;
            obj.groupingCategory = subsampling.groupingCategory;
            obj.subgroupIds = subsampling.subgroupIds;
            if obj.showPlotsAndText == 1
                disp(['*** AGE-GENDER Subsampling Results ***'])
                disp(['Number of iterations: ' num2str(obj.repetitions)])
                %disp(['Participants per country: ' num2str(length(obj.subgroupIds{1}))])
                disp('---AGE')
                disp(['ANOVA table for age comparison between groups, ' ,...
                    'IV: Country (Childhood), DV: Age'])
                disp(subsampling.ANOVAtbl)
                disp(['Eta square: ' num2str(subsampling.etaSquare)])
                disp(['GroupSD: ' num2str(subsampling.groupSD)])
                disp('')
                disp('---GENDER')
                disp('Gender ratio: Mean Difference between gender ratios')
                disp(['Gender ratio: ' num2str(subsampling.genderMetric)]);
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
            countries_N = table2array(countries_N(table2array(countries_N(:,2))>=obj.subgroupSubSamplingSize,1));
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
            text(length(countries_N)/2,m_Age-0.3,'Grand Mean')
            ylabel('Mean age'); xlabel('Country (Childhood)');
            title('Age distribution Pre-Post subsampling')
            legend(p,'Pre','Post')
            set(gca,'XTick',1:length(countries_N),'XTickLabels',countries_N),xtickangle(45)
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
                genderMetricPost(i,:) = genderG.GroupCount(1:2)*100/sum(genderG.GroupCount);
            end
            t = array2table([genderGtPost,genderMetricPost],'VariableNames',[obj.genderLabels(1:2),...
                'Female (%)','Male (%)'], 'RowNames',obj.subgroupNames);
            disp('Gender balance for each country')
            disp(t);
            %calculate gender balance in each group PRE SUBSAMPLING
            for i=1:length(obj.subgroupNames)
                genderG = groupcounts(obj.alldataTable(matches(obj.alldataTable.(obj.groupingCategory),...
                    obj.subgroupNames{i}),'Gender'),'Gender');
                f_idx = find(strcmpi(table2array(genderG(:,1)),'Female'));
                m_idx = find(strcmpi(table2array(genderG(:,1)),'Male'));
                genderGtPre(i,:) = genderG.GroupCount([f_idx m_idx]);
                genderMetricPre(i,:) = genderG.GroupCount(1:2)*100/sum(genderG.GroupCount);
            end
            genderMetricDiffPre = genderMetricPre(:,1)-genderMetricPre(:,2);
            genderMetricDiffPost = genderMetricPost(:,1)-genderMetricPost(:,2);
            %plot PRE-POST Gender differences
            figure
            hold on
            p = plot([genderMetricDiffPre,genderMetricDiffPost]);
            yline(0, 'k--')
            text(length(obj.subgroupNames)/2,-5,'Equally balanced groups')
            ylabel('Male - Female difference (%)'); xlabel('Country (Childhood)');
            title('Gender Balance Pre-Post subsampling')
            legend(p,'Pre','Post')
            set(gca,'XTick',1:length(obj.subgroupNames),'XTickLabels',obj.subgroupNames),xtickangle(45)
            hold off
        end
        function obj = get_baselines(obj)
            obj.groupTable = obj.groupTable(~matches(obj.groupTable.Gender, ...
                'Other'),:);
            for i =1:length(obj.subgroupNames)
                gender{i} = table2array(obj.groupTable(matches(obj.groupTable.(obj.groupingCategory),...
                    obj.subgroupNames{i}),{'Gender'}));
                age{i} = table2array(obj.groupTable(matches(obj.groupTable.(obj.groupingCategory),...
                    obj.subgroupNames{i}),{'Age'}));
                t = tabulate(gender{i});
                f_idx = find(strcmpi(t(:,1),'Female'));
                m_idx = find(strcmpi(t(:,1),'Male'));
                nf = t{f_idx,2};
                nm = t{m_idx,2};
                if nf<= obj.subgroupMinNumber/2
                    tf(i) = nf/obj.subgroupMinNumber;
                    tm(i) = 1-tf(i);
                elseif nm<= obj.subgroupMinNumber/2
                    tm(i) = nm/obj.subgroupMinNumber;
                    tf(i) = 1-tm(i);
                else
                    tm(i) = 0.5;
                    tf(i) = 0.5;
                end
            end
            genderMetric = sum(abs(tf-tm))/length(obj.subgroupNames); %difference between gender ratios
            disp(['Baseline Gender ratio: ' num2str(genderMetric)]);
            mAge = cell2mat(arrayfun(@(x) median(cell2mat(x)), age,'un',0));
            globalMedian = mean(mAge);
            for i =1:length(obj.subgroupNames)
                [~,idx] = sort(abs(age{i}-globalMedian),'ascend');
                age{i} = age{i}(idx(1:obj.subgroupMinNumber));
            end
            [a,tbl] = anova1(cell2mat(age),[],'off');
            sdmeanAge = std(cell2mat(arrayfun(@(x) mean(cell2mat(x)),age,'un',0)));
            disp(['Age baseline group MAD: ' num2str(sdmeanAge)]);
            fStat = tbl{2,5}; % anova F-statistic
            SSgroup = tbl{2,2}; SStotal = tbl{4,2};
            etaSquare = SSgroup/SStotal;
            disp(['Eta Square: ' num2str(etaSquare)]);
        end
    end
end
