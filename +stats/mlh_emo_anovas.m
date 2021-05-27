classdef mlh_emo_anovas < load_data.load_data
    % exploring anovas based on general mlh behavior
    % example obj = stats.mlh_emo_anovas('responses_pilot/Music Listening Habits.csv'); do_anovas(obj);
    properties

    end

    methods
        function obj = mlh_emo_anovas(dataPath, filterMethod)
            if nargin == 0
                dataPath = [];
            end
            obj = obj@load_data.load_data(dataPath, filterMethod);
        end
        function obj = do_anovas(obj)
            reasonLabels = {'for background purposes'
                            'to bring up memories'
                            'to have fun'
                            'to feel music´s emotions'
                            'to change your mood'
                            'to express yourself'
                            'to feel connected to other people'};
            likertPoints = {'Never'
                            'Rarely'
                            'Sometimes'
                            'Quite often'
                            'Very often'};
            Var = 'employmentLabels';
            N = 100;
            %reducedTable = stats.mlh_emo_anovas.filterMostFrequentCategories(obj.dataTable,Var,N);
            reducedTable = obj.dataTable;
            selectedGroupingVarLevels = unique(reducedTable.(Var));
            g = groupcounts(reducedTable,Var);
            disp(g);
            tableFunctions = reducedTable(:,contains(reducedTable.Properties.VariableNames,'Music_'));
            tableFunctionsNumeric = tableFunctions;
            for k = 1:size(tableFunctions,2)
                cats = categorical(tableFunctions{:,k},[1:numel(likertPoints)],likertPoints,'Ordinal',true);
                tableFunctions.(tableFunctions.Properties.VariableNames{k}) = cats;
            end
            for k = 1:size(tableFunctions,2)
                disp(['***' upper(reasonLabels{k}) '***'])
                [p tbl] = anova1(tableFunctionsNumeric{:,k},reducedTable.(Var));
                close
                snapnow
                reasonLabel = tableFunctions.Properties.VariableNames{k};
                G = groupsummary(reducedTable,{Var,reasonLabel});
                nLikertPoints = numel(likertPoints);
                for j = 1:numel(selectedGroupingVarLevels)
                    if sum(matches(string(G.(Var)),string(selectedGroupingVarLevels(j)))) ~= nLikertPoints
                        availablePoints = G.(reasonLabel)(matches(string(G.(Var)),string(selectedGroupingVarLevels(j))));
                        expectedPoints = 1:nLikertPoints;
                        C = setdiff(expectedPoints, availablePoints);
                        C = C(:);
                        T = table(repelem(selectedGroupingVarLevels(j),numel(C))',C,repelem(0,numel(C))','VariableNames',G.Properties.VariableNames);
                        G = sortrows([G; T],{Var,reasonLabel});
                        % here we want to put the rows back to how
                        % they were
                    end
                end
                figure
                perc = G.GroupCount./repelem(g.GroupCount,nLikertPoints)*100;
                bar(reshape(perc,nLikertPoints,[])');
                xticklabels(string(selectedGroupingVarLevels));
                title(reasonLabels{k},'Interpreter','None')
                legend(likertPoints,'Location','NorthOutside','Orientation','Horizontal')
                snapnow
            end
        end
    end
    methods(Static)
        function tableY = filterMostFrequentCategories(tableX,Var,N)
        % N = minimum sample size
            g = groupcounts(tableX,Var);
            cats = g.(Var)(g.GroupCount >= N);
            tableY = tableX(matches(tableX.(Var), cats),:);
        end
    end
end
