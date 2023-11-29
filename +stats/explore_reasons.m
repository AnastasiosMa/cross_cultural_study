classdef explore_reasons < load_data.load_data & stats.factor_analysis
%example: obj = stats.explore_reasons(); obj.filterMethod='AllResponses';obj=do_load_data(obj);predict_reasons_from_emotions(obj);
%obj = stats.explore_reasons(); obj.filterMethod='AllResponses';obj=do_load_data(obj);do_factor_analysis_reasons(obj)

    properties
    end
    methods
        function obj = explore_reasons(obj)
            obj=do_load_data(obj);
        end
        function obj = do_factor_analysis_reasons(obj)
            reasonLabels = {'for background purposes'
                            'to bring up memories'
                            'to have fun'
                            'to feel music´s emotions'
                            'to change your mood'
                            'to express yourself'
                            'to feel connected to other people'};
            reasonTypes = {'General Behavior','Selected Track'};
            reasonTypesKey = {'Music_','Track_'};
            obj.dataTable(any(ismissing(obj.dataTable{:,find(contains(obj.dataTable.Properties.VariableNames, reasonTypesKey))}),2),:) = [];
            %figure('units','normalized','outerposition',[0 0 1 1])
            for j = 1:numel(reasonTypesKey)
                a = obj;
                a.dataTableInd = find(contains(obj.dataTable.Properties.VariableNames, reasonTypesKey{j}));
                a.dataTable.Properties.VariableNames(obj.dataTableInd) = strrep(obj.dataTable.Properties.VariableNames(obj.dataTableInd),'_',' ');
                a.showPlotsAndText = 0;
                a.showPlotsAndTextFA = 1;
                a.removeLeastRatedTerms = 0;
                a.rotateMethod = 'varimax';
                a.PCNum =2;%number of factors
                a.scale_range = [1,5];
                f(j) = do_factor_analysis(a);
            end
        end
        function obj = predict_reasons_from_emotions(obj)
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
                %set(0,'DefaultFigureVisible','off')
                fa = do_factor_analysis(obj);
                %set(0,'DefaultFigureVisible','on')
                fa.FAScores(any(isnan(tableFunctions{:,:}), 2), :) = [];
                for j = 1:numel(reasonLabels)
                    varnames = [fa.factorNames, reasonLabels{j}]
                                    mdl{j} = fitlm(zscore(fa.FAScores),zscore(Y(:,j)),'VarNames',varnames);
                                    disp(['- ' upper(ReasonType)])
                                    disp(mdl{j});
                end
            end
        end
    end
end
