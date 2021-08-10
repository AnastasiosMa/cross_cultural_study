classdef differences_in_reasons_betw_groups < load_data.load_data
    % exploring kruskalwallis based on mlh behavior
    % example obj = stats.differences_in_reasons_betw_groups('responses_pilot/Music Listening Habits.csv','AllResponses'); do_differences_in_reasons_betw_groups(obj);
    properties
        ReasonType = 'GeneralBehavior'% 'GeneralBehavior','SelectedTrack'
        Var = 'employmentLabels';%'employmentLabels','AgeCategory','EconomicSituation','Education','Employment','Gender','Musicianship'
    end

    methods
        function obj = differences_in_reasons_betw_groups(dataPath,filterMethod)
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
        function obj = do_differences_in_reasons_betw_groups(obj)
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
            N = 100;
            %reducedTable = stats.differences_in_reasons_betw_groups.filterMostFrequentCategories(obj.dataTable,Var,N);
            reducedTable = obj.dataTable;
            selectedGroupingVarLevels = unique(reducedTable.(obj.Var));
            if matches(obj.ReasonType,'GeneralBehavior')
            tableFunctions = reducedTable(:,contains(reducedTable.Properties.VariableNames,'Music_'));
            elseif  matches(obj.ReasonType,'SelectedTrack')
            tableFunctions = reducedTable(:,contains(reducedTable.Properties.VariableNames,'Track_'));
            end
            badData = any(isnan(table2array(tableFunctions)),2);
            tableFunctions(badData,:) = [];
            reducedTable(badData,:)=[];
            g = groupcounts(reducedTable,obj.Var);
            disp(g);
            tableFunctionsNumeric = tableFunctions;


            for k = 1:size(tableFunctions,2)
                cats = categorical(tableFunctions{:,k},[1:numel(likertPoints)],likertPoints,'Ordinal',true);
                tableFunctions.(tableFunctions.Properties.VariableNames{k}) = cats;
            end
            for k = 1:size(tableFunctions,2)
                disp(['***' upper(reasonLabels{k}) '***'])
                [p tbl] = kruskalwallis(tableFunctionsNumeric{:,k},reducedTable.(obj.Var));
                close
                snapnow
                reasonLabel = tableFunctions.Properties.VariableNames{k};
                G = groupsummary(reducedTable,{obj.Var,reasonLabel});
                nLikertPoints = numel(likertPoints);
                for j = 1:numel(selectedGroupingVarLevels)
                    if sum(matches(string(G.(obj.Var)),string(selectedGroupingVarLevels(j)))) ~= nLikertPoints
                        availablePoints = G.(reasonLabel)(matches(string(G.(obj.Var)),string(selectedGroupingVarLevels(j))));
                        expectedPoints = 1:nLikertPoints;
                        C = setdiff(expectedPoints, availablePoints);
                        C = C(:);
                        T = table(repelem(selectedGroupingVarLevels(j),numel(C))',C,repelem(0,numel(C))','VariableNames',G.Properties.VariableNames);
                        G = sortrows([G; T],{obj.Var,reasonLabel});
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
