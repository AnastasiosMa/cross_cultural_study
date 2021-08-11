classdef explore_tipi < load_data.load_data
%example: obj = stats.explore_tipi('responses_pilot/Music Listening Habits.csv','AllResponses');do_explore_tipi(obj);exploreTIPICategory(obj);TIPICategoryANOVA(obj)

    properties
            FactorNames = {'TendernessLove','TriumphEnergy','PainSadness','PleasureHappiness'};
            countryType = 'Country_childhood';
    end
    methods
        function obj = explore_tipi(dataPath,filterMethod)
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
        function obj = exploreTIPICategory(obj)
            tipiCompleteLogical = ~any(isundefined(obj.dataTable.TIPICategory),2);
            dataTableTIPIcomplete = obj.dataTable(tipiCompleteLogical,:);
            T = dataTableTIPIcomplete(:,matches(dataTableTIPIcomplete.Properties.VariableNames,{'TIPICategory', obj.countryType}));
        % horizontal/vertical
            G = groupsummary(T,{obj.countryType,'TIPICategory'},'IncludeEmptyGroups',true);
            d = reshape(G.GroupCount,numel(categories(T.TIPICategory)),[])';
            dNorm = d./sum(d,2);
            [S I] = sort(dNorm(:,1));
            g = get(groot,'defaultfigureposition');
            g(4) = g(4)*2;
            figure('Position',g)
            b = barh(dNorm(I,:),'stacked');
            yticks(1:size(dNorm,1))
            C = unique(G.(obj.countryType));
            yticklabels(C(I))
            legend(strrep(categories(G.TIPICategory),'_',' '),'Location','NorthOutside','AutoUpdate','Off')
            title({['Frequency of TIPI category '];['per '  lower(strrep(obj.countryType,'_',' of ')) ' (normalized to sum 1)']})
            ax = gca;
            ax.FontSize = 16;
        end
        function obj = TIPICategoryANOVA(obj)
            a = stats.factor_analysis(obj.dataPath,obj.filterMethod);
            for k = 1:size(a.FAScores,2)
                FAs{k} = a.FAScores(:,k);
            end
            obj.dataTable = addvars(obj.dataTable,FAs{:},'After','Rebelliousness','NewVariableNames',obj.FactorNames);
            obj.dataTable(:,16:48) = []; % REMOVE HARDCODED EMO LOCATIONS
            obj.dataTable = removevars(obj.dataTable,{'RespondentID','Childhood','Adulthood','Residence','Identity','Duration','Employment','Gender','Extraversion','Agreeableness','Conscientiousness','Emotional_Stability','Openness_Experiences'});
            obj.dataTable(any(obj.dataTable.Education == 7:9,2),:)=[];
            % remove people from 'Other' gender
            obj.dataTable(obj.dataTable.GenderCode == 3,:) = [];
            tipiCompleteLogical = ~any(isundefined(obj.dataTable.TIPICategory),2);
            dataTableTIPIcomplete = obj.dataTable(tipiCompleteLogical,:);
            S = vartype('numeric');
            IV = dataTableTIPIcomplete.TIPICategory;
            DVs = dataTableTIPIcomplete(:,S);
            for k = 1: size(DVs,2)
                [p tbl] = anova1(DVs{:,k},IV,'off');
                if p < .05
                    disp(DVs.Properties.VariableNames{k})
                    %disp(array2table(tbl(2:end,:),'VariableNames',tbl(1,:)))
                    [g gl] = findgroups(IV);
                    t = tabulate(g);
                    N = string(t(:,2));
                    prctg = string(num2str(t(:,3),'%.f'));
                    for j = 1:numel(unique(g))
                        d{j} = DVs{:,k}(g == j);
                    end
                    figure
                    violin(d);
                    xticks(1:numel(d))
                    names = strrep(string(gl),'_',' ');
                    row2 = cellstr("(N=" +  N +", " + prctg  +  "%)")';
                    xticklabels(names);
                    lims = ylim;
                    text(1:numel(row2),repmat(.2+lims(1),1,numel(row2)),row2,'HorizontalAlignment','Center')
                    F = num2str(cell2mat(tbl(2,end-1)),'%.2f');
                    P = strrep(num2str(cell2mat(tbl(2,end)),'%.3f'),'0.','.');
		    title([strrep(DVs.Properties.VariableNames{k},'_',' ') ' - F=' F ', p=' P]);
                    %boxplot(DVs{:,k},IV,'Notch','on')
                end
            end
        end
        function obj = do_explore_tipi(obj)
            % a = stats.factor_analysis(obj.dataPath,obj.filterMethod);
            % for k = 1:size(a.FAScores,2)
            %     FAs{k} = a.FAScores(:,k);
            % end
            % obj.dataTable = addvars(obj.dataTable,FAs{:},'After','Rebelliousness','NewVariableNames',obj.FactorNames);
            tipiCompleteLogical = ~any(isnan(obj.dataTable{:,matches(obj.dataTable.Properties.VariableNames,obj.TIPIscalesNames)}),2);
            dataTableTIPIcomplete = obj.dataTable(tipiCompleteLogical,:);
            T = dataTableTIPIcomplete(:,matches(dataTableTIPIcomplete.Properties.VariableNames,[obj.TIPIscalesNames obj.countryType]));

            figure
            boxplot(T{:,2:end})
            xticklabels(T.Properties.VariableNames(2:end))
            title('TIPI ratings across all participants')

            V = varfun(@mean,T,'GroupingVariables',obj.countryType);
            V = sortrows(V,2);
            Tnorm = T;
            Tnorm{:,2:end} = T{:,2:end}./sum(T{:,2:end},2);
            Vnorm = varfun(@mean,Tnorm,'GroupingVariables',obj.countryType);
            Vnorm = sortrows(Vnorm,3);
            figure
            bar(V{:,3:end})
            xticks(1:size(V,1))
            xticklabels(V{:,1})
            legend(strrep(erase(string(V.Properties.VariableNames(3:end)),{'mean_'}),'_',' '));
            title(['Mean TIPI ratings per ' lower(strrep(obj.countryType,'_',' of '))])
            g = get(groot,'defaultfigureposition');
            g(4) = g(4)*2;
            figure('Position',g)
            b = barh(Vnorm{:,3:end},'stacked');
            yticks(1:size(Vnorm,1))
            yticklabels(Vnorm{:,1})
            legend(strrep(erase(string(Vnorm.Properties.VariableNames(3:end)),{'mean_'}),'_',' '),'Location','NorthOutside','AutoUpdate','Off');
            xline(.5,'--');
            title({['Mean TIPI per '  lower(strrep(obj.countryType,'_',' of '))];[ ' (normalized to sum 1)']})
            ax = gca;
            ax.FontSize = 16;
        end
    end
    methods (Static)
        function out = makestars(p)
        % Create a cell array with stars from p-values (* p < .05; ** p < .01; *** p <
        % .001). Input must be a matrix
            names = {'','*', '**','***'};
            stars = zeros(size(p));
            stars(find(p < .001)) = 4;
            stars(find(p >= .001 & p < .01)) = 3;
            stars(find(p >= .01 & p < .05)) = 2;
            stars(find(stars == 0)) = 1;
            out = names(stars);
        end
        function t = makeTableWithVarNamesStars(r,p,VarNames,RowNames)
        % formats into '%2.f',adds stars, makes varnames for
        % columns and optionally rowNames
            r = arrayfun(@(x) num2str(x,'%.2f'),r,'un',0);
            % here we could also add the option of remove the 0
            % before the decimal point
            p = stats.explore_tipi.makestars(p);
            d = cellfun(@(x,y) join([x,y],'') ,r,p,'un',0);
            if nargin == 3
                t = array2table(string(d),'VariableNames',VarNames);
            elseif nargin == 4
                t = array2table(string(d),'VariableNames',VarNames,'RowNames',RowNames);
            end
        end
        function tab = plotCorrMat(corrMat,pMat,ticklabels,myTitle)
            set(groot,'defaultAxesTickLabelInterpreter','none');
            corrMat(logical(triu(corrMat))) = NaN;
            corrMat(1,:) = [];
            corrMat(:,end) = [];
            pMat(logical(triu(pMat))) = NaN;
            pMat(1,:) = [];
            pMat(:,end) = [];
            [nr,nc] = size(corrMat);
            p = pcolor([corrMat nan(nr,1); nan(1,nc+1)]);
            shading faceted; % or flat
            set(gca, 'ydir', 'reverse');
            colorbar
            xticks(1:numel(ticklabels));
            yticks(1:numel(ticklabels));
            xticks(xticks+.5);
            yticks(yticks+.5);
            xt = string(ticklabels(1:end-1));
            xticklabels(xt)
            yt = string(ticklabels(2:end));
            yticklabels(yt(:))
            xtickangle(45)
            title(myTitle)
            disp(myTitle)
            tab = stats.explore_tipi.makeTableWithVarNamesStars(corrMat,pMat,xt,yt);
            disp(tab);
        end
        function savefigures(inputstring)
        % get all figures saved as png and fig files. tikz and tex
        % implementation is on its way?
            h = get(0,'children');
            for i=1:length(h)
                saveas(h(i), [h(i).Name inputstring num2str(i) '.png'], 'png');
                saveas(h(i), [h(i).Name inputstring num2str(i) '.fig'], 'fig');
            end
        end
    end
end
