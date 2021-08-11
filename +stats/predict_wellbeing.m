classdef predict_wellbeing < load_data.load_data
%example: obj = stats.predict_wellbeing('responses_pilot/Music Listening Habits.csv','AllResponses'); do_mean_wellbeing(obj);do_predict_wellbeing_from_emotions(obj);do_predict_wellbeing_from_reasons(obj)

    properties
    end
    methods
        function obj = predict_wellbeing(dataPath,filterMethod)
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
        function obj = do_mean_wellbeing(obj)
            close all
            filterMethod = regexprep(obj.filterMethod, '([A-Z])', ' $1');
                tableWellbeing = obj.dataTable(:,matches(obj.dataTable.Properties.VariableNames,'MusicWellBeing'));
                X = tableWellbeing{:,:};

                data = mean(X)';
                x = 1:numel(data);
                errhigh = std(X);
                errlow = errhigh;
                figure
                b = bar(x,data);
                ylim([0 6]);
                hold on

                er = errorbar(x,data,errlow,errhigh);
                er.Color = [0 0 0];
                er.LineStyle = 'none';
                myTitle = ['Mean and SD of wellbeing question, ' filterMethod ' (N=' num2str(size(X,1)) ')'];
                title(myTitle)
                stats.correlate_reasons.savefigures(['figures/correlate_reasons/mean_wellbeing_' obj.filterMethod])
                hold off
        end
        function obj = do_predict_wellbeing_from_reasons(obj)
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
                tableWellbeing = obj.dataTable(:,matches(obj.dataTable.Properties.VariableNames,'MusicWellBeing'));
                Y = tableWellbeing{:,:};
                X = tableFunctions{:,:};
                disp(['- Eliminating subjects with missing reason data (this problem applies to ''selected track'' only)'])
                X(any(isnan(tableFunctions{:,:}), 2), :) = [];% remove nan rows
                Y(any(isnan(tableFunctions{:,:}), 2), :) = [];
                FactorNames = [reasonLabels','IsMusicBeneficialForYourWellbeing'];
                mdl = fitlm(zscore(X),zscore(Y),'VarNames',FactorNames);
                disp(['- ' upper(ReasonType)]);
                disp(mdl);
            end
        end
        function obj = do_predict_wellbeing_from_emotions(obj)
        % R-squared: 0.0477
            close all
            % adding space before capital letters in variable names
            tableWellbeing = obj.dataTable(:,matches(obj.dataTable.Properties.VariableNames,'MusicWellBeing'));
            Y = tableWellbeing{:,:};
            set(0,'DefaultFigureVisible','off')
            fa = stats.factor_analysis(obj.dataPath,obj.filterMethod);
            set(0,'DefaultFigureVisible','on')
            FactorNames = {'TendernessLove','TriumphBeauty','PainSadness','PleasureHappiness','IsMusicBeneficialForYourWellbeing'};
            mdl = fitlm(zscore(fa.FAScores),zscore(Y),'VarNames',FactorNames);
            disp(mdl);
        end
    end
end
