classdef ancova_examples < load_data.load_data
%example: obj = stats.ancova_examples('responses_pilot/Music Listening Habits.csv','AllResponses'); do_ancova_examples(obj);

    properties
    end
    methods
        function obj = ancova_examples(dataPath,filterMethod)
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
        function obj = do_ancova_examples(obj)
            close all
            reasonLabels = {'for background purposes'
                            'to bring up memories'
                            'to have fun'
                            'to feel music´s emotions'
                            'to change your mood'
                            'to express yourself'
                            'to feel connected to other people'};
            reasonTypes = {'General Behavior','Selected Track'};
            % adding space before capital letters in variable names
            filterMethod = regexprep(obj.filterMethod, '([A-Z])', ' $1');
            for k = 1:numel(reasonTypes)
                ReasonType = reasonTypes{k};
                if matches(ReasonType,'General Behavior')
                    tableFunctions = obj.dataTable(:,contains(obj.dataTable.Properties.VariableNames,'Music_'));
                elseif  matches(ReasonType,'Selected Track')
                    tableFunctions = obj.dataTable(:,contains(obj.dataTable.Properties.VariableNames,'Track_'));
                end

                Y = tableFunctions{:,:};
                disp(['- Eliminating subjects with missing reason data (this problem applies to ''selected track'' only)'])
                Y(any(isnan(tableFunctions{:,:}), 2), :) = [];% remove nan rows
                set(0,'DefaultFigureVisible','off')
                fa = stats.factor_analysis(obj.dataPath,obj.filterMethod);
                set(0,'DefaultFigureVisible','on')
                fa.FAScores(any(isnan(tableFunctions{:,:}), 2), :) = [];
                Age = obj.dataTable.AgeCategory;
                Age(any(isnan(tableFunctions{:,:}), 2), :) = [];

                for j = 1:numel(reasonLabels)
                    FactorNames = {'TendernessLove','TriumphBeauty','PainSadness','PleasureHappiness'};
                    for i = 1:numel(FactorNames)
                        disp(['- ' upper(ReasonType)])

                        if matches(FactorNames{i},'TriumphBeauty')
                            if matches(reasonLabels{j},'to have fun')
                                if matches(ReasonType,'General Behavior')
                                    [h,atab,ctab,stat] = aoctool(fa.FAScores(:,i),Y(:,j),Age,.05,FactorNames{i},reasonLabels{j},'Age');
                                    multcompare(stat,0.05,'on','','s')
                                end
                            end
                        end
                        % to change your mood, tenderless/love also gives interesting results here
                    end
                end
            end
        end
    end
end
