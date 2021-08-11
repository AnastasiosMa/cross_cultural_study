classdef differences_in_emotions_betw_groups < load_data.load_data
% exploring kruskalwallis based on mlh behavior
% example obj = stats.differences_in_emotions_betw_groups('responses_pilot/Music Listening Habits.csv','AllResponses'); do_differences_in_emotions_betw_groups(obj);do_differences_in_emotions_betw_groups_controlling_age(obj);
    properties
    end
    methods
        function obj = differences_in_emotions_betw_groups(dataPath,filterMethod)
            if nargin < 2
                error('ErrorTests:convertTest',...
                      'Choose a filter method: \n  AllResponses \n  BalancedSubgroups');
            end
            if nargin == 0
                dataPath = [];
                filterMethod = [];
            end
            obj = obj@load_data.load_data(dataPath, filterMethod);
        end
        function obj = do_differences_in_emotions_betw_groups(obj)

            reducedTable = obj.dataTable;
            groupVarsPretty = {'Age Group','Gender', 'Musicianship','Employment','Education','Economic Situation'};
            groupVars = {'AgeCategory','Gender','musicianshipLabels','employmentLabels','educationLabels','economicSituationLabels'};
            set(0,'DefaultFigureVisible','off')
            fa = stats.factor_analysis(obj.dataPath,obj.filterMethod);
            set(0,'DefaultFigureVisible','on')
            emotionDims = fa.FAScores;
            FactorNames = {'TendernessLove','TriumphBeauty','PainSadness','PleasureHappiness'};

            if matches(obj.filterMethod,'BalancedSubgroups')
            countryChildhood = categorical(obj.groupTable.Country_childhood);
                disp('******')
                disp(['***Country of childhood***'])
                disp('******')
                tabulate(countryChildhood)
                for k = 1:size(emotionDims,2)
                    disp(['*** ' FactorNames{k} ' dimension ***'])
                    [p tbl] = anova1(emotionDims(:,k),countryChildhood);
                    %title(['Differences in experienced ' FactorNames{k} ' while listening to track - Country of childhood' ])
                    snapnow
                end
            end


            for j = 1:numel(groupVars);
                disp('******')
                disp(['***' upper(groupVarsPretty{j}) '***'])
                disp('******')
                disp(groupcounts(reducedTable,groupVars{j}))
                selectedGroupingVarLevels = unique(reducedTable.(groupVars{j}));
                g = groupcounts(reducedTable,groupVars{j});
                disp(g);

                for k = 1:size(emotionDims,2)
                    disp(['*** ' FactorNames{k} ' dimension ***'])
                    [p tbl] = anova1(emotionDims(:,k),reducedTable.(groupVars{j}));
                    %title(['Differences in experienced ' FactorNames{k} ' while listening to track - ' groupVarsPretty{j}])
                    snapnow
                end
            end
        end
        function obj = do_differences_in_emotions_betw_groups_controlling_age(obj)
            reducedTable = obj.dataTable;
            groupVarsPretty = {'Gender', 'Musicianship','Employment','Education','Economic Situation'};
            groupVars = {'Gender','musicianshipLabels','employmentLabels','educationLabels','economicSituationLabels'};
            set(0,'DefaultFigureVisible','off')
            fa = stats.factor_analysis(obj.dataPath,obj.filterMethod);
            set(0,'DefaultFigureVisible','on')
            emotionDims = fa.FAScores;
            FactorNames = {'TendernessLove','TriumphBeauty','PainSadness','PleasureHappiness'};
            Age = reducedTable.Age;

            if matches(obj.filterMethod,'BalancedSubgroups')
            countryChildhood = categorical(obj.groupTable.Country_childhood);
                disp('******')
                disp(['***Country of childhood***'])
                disp('******')
                tabulate(countryChildhood)
                for k = 1:size(emotionDims,2)
                    disp(['*** ' FactorNames{k} ' dimension ***'])
                    [h,atab,ctab,stat] = aoctool(Age,emotionDims(:,k),countryChildhood,.05,'Age',FactorNames{k},'Country of childhood');
                    multcompare(stat,0.05,'on','','s')
                    %title(['Differences in experienced ' FactorNames{k} ' while listening to track - Country of childhood' ])
                    snapnow
                end
            end


            for j = 1:numel(groupVars);
                disp('******')
                disp(['***' upper(groupVarsPretty{j}) '***'])
                disp('******')
                disp(groupcounts(reducedTable,groupVars{j}))
                selectedGroupingVarLevels = unique(reducedTable.(groupVars{j}));
                g = groupcounts(reducedTable,groupVars{j});
                disp(g);

                for k = 1:size(emotionDims,2)
                    disp(['*** ' FactorNames{k} ' dimension ***'])
                    [h,atab,ctab,stat] = aoctool(Age,emotionDims(:,k),reducedTable.(groupVars{j}),.05,'Age',FactorNames{k});
                    multcompare(stat,0.05,'on','','s')
                    title(['Differences in experienced ' FactorNames{k} ' while listening to track - ' groupVarsPretty{j}])
                    snapnow
                end
            end
        end
    end
end
