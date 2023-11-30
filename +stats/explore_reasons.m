classdef explore_reasons < load_data.load_data & stats.factor_analysis
%obj = stats.explore_reasons(); obj.filterMethod='AllResponses';obj=do_load_data(obj);obj = do_explore_reasons(obj)

    properties
        reasonLabels = {'for background purposes'
                            'to bring up memories'
                            'to have fun'
                            'to feel music´s emotions'
                            'to change your mood'
                            'to express yourself'
                            'to feel connected to other people'};
        reasonTypes = {'General Reason','Selected Track Reason'};
        reasonTypesKey = {'Music_','Track_'};
    end
    methods
        function obj = explore_reasons(obj)
            obj=do_load_data(obj);
        end
        function obj = do_explore_reasons(obj)
            obj = do_factor_analysis_reasons(obj);
            obj = reasons_plot_means(obj);
            obj = predict_reasons_from_emotions(obj)
        end
        function obj = do_factor_analysis_reasons(obj)
            obj.dataTable(any(ismissing(obj.dataTable{:,find(contains(obj.dataTable.Properties.VariableNames, obj.reasonTypesKey))}),2),:) = [];
            %figure('units','normalized','outerposition',[0 0 1 1])
            for j = 1:numel(obj.reasonTypesKey)
                a = obj;
                a.dataTableInd = find(contains(obj.dataTable.Properties.VariableNames, obj.reasonTypesKey{j}));
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
        function obj = reasons_plot_means(obj)
            musicReasonInd = find(contains(obj.dataTable.Properties.VariableNames, obj.reasonTypesKey{1}));
            trackReasonInd = find(contains(obj.dataTable.Properties.VariableNames, obj.reasonTypesKey{2}));
            reasons_data = obj.dataTable{:,[musicReasonInd,trackReasonInd]};
            reasons_data = (reasons_data - 1)./(5-1);
            mean_reasons = reshape(nanmean(reasons_data),2,7)';
            table_reasons = table(mean_reasons(:,1),mean_reasons(:,2),abs(mean_reasons(:,2)-mean_reasons(:,1)),...
                obj.reasonLabels,'VariableNames',{'Reason_music','Reason_track','Difference','Reason'});
            table_reasons = sortrows(table_reasons,3,'descend');
            for i = 1:7
                [H,P,CI,STATS] = ttest(obj.dataTable{:,musicReasonInd(i)},obj.dataTable{:,trackReasonInd(i)});
                disp(P);disp(STATS);
            end    
            
            figure
            barh(1:7,[table_reasons{:,1},table_reasons{:,2}])
            set(gca,'FontSize',24,'LineWidth',2)
            set(gca,'YTick',1:7,'YTickLabel',table_reasons{:,4})
            legend(obj.reasonTypes,'Location','best')
            box on
            grid on
            title('Reasons for listening (Mean Frequency)')
        end
        function obj = predict_reasons_from_emotions(obj)
            close all
            % adding space before capital letters in variable names
            filterMethod = regexprep(obj.filterMethod, '([A-Z])', ' $1');
            for k = 1:numel(obj.reasonTypes)
                ReasonType = obj.reasonTypes{k};
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
                for j = 1:numel(obj.reasonLabels)
                    varnames = [fa.factorNames, obj.reasonLabels{j}]
                                    mdl{j} = fitlm(zscore(fa.FAScores),zscore(Y(:,j)),'VarNames',varnames);
                                    disp(['- ' upper(ReasonType)])
                                    disp(mdl{j});
                end
            end
        end
    end
end
