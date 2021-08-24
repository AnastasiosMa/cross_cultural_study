classdef explore_indiv_collect < load_data.load_data & stats.factor_analysis
%example: obj = stats.explore_indiv_collect();do_explore_indiv_collect(obj);exploreIndColCategory(obj);indColCategoryANOVA(obj);exploreICfactorAnalysis(obj);
%obj = stats.explore_indiv_collect();obj.filterMethod='BalancedSubgroups';obj=do_load_data(obj);obj=exploreICfactorAnalysis(obj);plot2Dksdensity_2factorSolution(obj)
% obj = stats.explore_indiv_collect();obj.filterMethod='BalancedSubgroups';obj=do_load_data(obj);obj = exploreICpca(obj);plot2Dksdensity_2PCs(obj)
%obj = stats.explore_indiv_collect();obj.filterMethod='AllResponses';obj=do_load_data(obj);obj = exploreICmds(obj)
%obj = stats.explore_indiv_collect();obj.filterMethod='AllResponses';obj=do_load_data(obj);obj = exploreICpca(obj);spider_ICcat_reasons(obj)
%obj = stats.explore_indiv_collect();obj.filterMethod='AllResponses';obj=do_load_data(obj);obj = exploreICpca(obj);spider_ICcat_emoFunctions(obj)
%obj = stats.explore_indiv_collect();obj.filterMethod='BalancedSubgroups';obj=do_load_data(obj);obj=exploreICfactorAnalysis(obj);correlate4FacWithSum(obj)
%obj = stats.explore_indiv_collect();obj.filterMethod='BalancedSubgroups';obj=do_load_data(obj);obj=indColAgeDensity(obj);
%obj = stats.explore_indiv_collect();obj.filterMethod='AllResponses';obj=do_load_data(obj);obj = exploreICpca(obj);obj=indColPCAAgeDensity(obj);
    properties
        FactorNames = {'TendernessLove','TriumphEnergy','PainSadness','PleasureHappiness'};
            countryType = 'Country_childhood';
    end
    methods
        function obj = explore_indiv_collect(obj)
            obj=do_load_data(obj);
        end
        function obj = correlate4FacWithSum(obj)
        % correlate four factor solution with summing the question
        % items corresponding to each factor
            imagesc(corr(obj.dataTable{:,matches(obj.dataTable.Properties.VariableNames,obj.ICscalesNames)},obj.FAScores(:,[2 1 3 4])))
            xticks(1:4)
            yticks(1:4)
            colorbar
            xticklabels(wrev(strrep(obj.ICscalesNames,'_',' ')))
            yticklabels(strrep(obj.ICscalesNames,'_',' '))
            xlabel('4 factor solution')
            ylabel('Triandis')
        end
        function obj = exploreICmds(obj)
            obj.dataTableInd = find(matches(obj.dataTable.Properties.VariableNames, obj.icVars));
            obj.dataTable(any(isnan(obj.dataTable{:,obj.dataTableInd}),2),:) = [];
            obj.dataTable.Properties.VariableNames(obj.dataTableInd) = strrep(obj.dataTable.Properties.VariableNames(obj.dataTableInd),'_',' ');
            icZ = zscore(obj.dataTable{:,obj.dataTableInd});
            metric = 'euclidean';
            method = 'mdscale';
            mdScalingMethod = str2func(['@(x,y) ' method '(x,y)']);

            p = pdist(icZ,metric);
            g = get(groot,'defaultfigureposition');
            g(3) = g(3)*2;
            figure('Position',g)
            tiledlayout(1,3)
            for k = 2:4
                Y = mdScalingMethod(p,k);
                nexttile
                barh((corr(Y,obj.dataTable{:,obj.dataTableInd})'))
                yticks(1:numel(obj.dataTable.Properties.VariableNames(obj.dataTableInd)))
                if k == 2
                    yticklabels((obj.dataTable.Properties.VariableNames(obj.dataTableInd)))
                else
                    yticklabels('')
                end
                title([num2str(k) ' dimensions'])
                set(gca, 'YDir','Reverse')
            end
            legend('Dim1','Dim2','Dim3','Dim4')
            sgtitle([ method ' - ' metric ]);
            %figure,scatter(Y(:,1),Y(:,2));
        end
        function obj = exploreICpca(obj)
            emo = do_factor_analysis(obj);
            for k = 1:size(emo.FAScores,2)
                FAs{k} = emo.FAScores(:,k);
            end
            obj.dataTable = addvars(obj.dataTable,FAs{:},'After','Rebelliousness','NewVariableNames',obj.FactorNames);
            obj.dataTableInd = find(matches(obj.dataTable.Properties.VariableNames, obj.icVars));
            obj.dataTable(any(isnan(obj.dataTable{:,obj.dataTableInd}),2),:) = [];
            obj.dataTable.Properties.VariableNames(obj.dataTableInd) = strrep(obj.dataTable.Properties.VariableNames(obj.dataTableInd),'_',' ');
            [coeff, score, ~, ~, explained] = pca(obj.dataTable{:,obj.dataTableInd},'NumComponents',3);
            figure
            imagesc(coeff)
            yticks(1:size(coeff,1))
            yticklabels(obj.dataTable.Properties.VariableNames(obj.dataTableInd))
            colorbar
            PCnames = {'IndCol','HorzVert'};
            obj.dataTable = addvars(obj.dataTable,score(:,2),score(:,3),'NewVariableNames',PCnames);
        end
        function obj = exploreICfactorAnalysis(obj)
        %a = stats.factor_analysis(obj);
            emo = do_factor_analysis(obj);
            for k = 1:size(emo.FAScores,2)
                FAs{k} = emo.FAScores(:,k);
            end
        obj.dataTable = addvars(obj.dataTable,FAs{:},'After','Rebelliousness','NewVariableNames',obj.FactorNames);
            obj.dataTableInd = find(matches(obj.dataTable.Properties.VariableNames, obj.icVars));
            obj.dataTable(any(isnan(obj.dataTable{:,obj.dataTableInd}),2),:) = [];
            obj.dataTable.Properties.VariableNames(obj.dataTableInd) = strrep(obj.dataTable.Properties.VariableNames(obj.dataTableInd),'_',' ');
            obj.showPlotsAndTextFA = 0;
            obj.removeLeastRatedTerms = 0;
            obj.rotateMethod = 'varimax';
            obj.PCNum =4;%number of factors
            obj = do_factor_analysis(obj); % this should be done on the
                                  % original variables (which we
                                  % removed at some point)
        end
        function obj = spider_ICcat_reasons(obj)
            addpath('~/Documents/MATLAB/spider_plot')
            addpath('~/Documents/MATLAB/brewermap')
            reasonLabels = {'for background purposes'
                            'to bring up memories'
                            'to have fun'
                            'to feel music´s emotions'
                            'to change your mood'
                            'to express yourself'
                            'to feel connected to other people'};
            reasonTypes = {'General Behavior','Selected Track'};
            cats = string(unique(obj.dataTable.IndColCategory));
            % br = brewermap(12,'Set3');
            % b = distinguishable_colors(numel(countries)-12);
            % b = [br; b];
            b = brewermap(numel(cats),'Dark2');
            reasonTypesKey = {'Music_','Track_'};
            figure('units','normalized','outerposition',[0 0 1 1])
            for j = 1:numel(reasonTypesKey)
                for k = 1:numel(cats)
                    logCat = matches(string(obj.dataTable.IndColCategory), cats{k});
                    reasonData = obj.dataTable(:,contains(obj.dataTable.Properties.VariableNames,reasonTypesKey{j}));
                    reasonDataCat(j,k,:) = nanmean(reasonData{logCat,:});
                end
                subplot(2,1,j)
                spider_plot(squeeze(reasonDataCat(j,:,:)),'AxesLabels',reasonLabels,'Color',b,'LineWidth',3,'LabelFontSize',12)
                if j == 1
                    l = legend(strrep(cats,'_',' '),'Location','EastOutside','Orientation','Vertical');
                end
            end
            l.Position(1) = 0;
            keyboard(2) = 0;
        end
        function obj = spider_ICcat_emoFunctions(obj)
            addpath('~/Documents/MATLAB/spider_plot')
            addpath('~/Documents/MATLAB/brewermap')
            cats = string(unique(obj.dataTable.IndColCategory));
            % br = brewermap(12,'Set3');
            % b = distinguishable_colors(numel(countries)-12);
            % b = [br; b];
            b = brewermap(numel(cats),'Dark2');
            figure('units','normalized','outerposition',[0 0 1 1])
            for k = 1:numel(cats)
                logCat = matches(string(obj.dataTable.IndColCategory), cats{k});
                emoData = obj.dataTable(:,matches(obj.dataTable.Properties.VariableNames,obj.FactorNames));
                emoDataCat(k,:) = nanmean(emoData{logCat,:});
            end
            spider_plot((emoDataCat),'AxesLabels',obj.FactorNames,'Color',b,'LineWidth',3,'LabelFontSize',12)
            l = legend(strrep(cats,'_',' '),'Location','EastOutside','Orientation','Vertical');
            l.Position(1) = 0;
            keyboard(2) = 0;
        end
        function obj = plot2Dksdensity_2PCs(obj)
        %obj.dataTable = obj.dataTable(obj.dataTable.GenderCode == 1,:)% select a gender
            S = vartype('numeric');
            dataTableNum = obj.dataTable(:,S);
            obj.dataTable(any(isnan(dataTableNum{:,:}),2),:) = [];
            averagingFCnIC = @mean;
            averagingFCn = @mean;
            addpath('~/Documents/MATLAB/dscatter')
            addpath('~/Documents/MATLAB/distinguishable_colors')
            addpath('~/Documents/MATLAB/brewermap')
            factorNames = {'IndCol','HorzVert'};
            PCscores = obj.dataTable{:,matches(obj.dataTable.Properties.VariableNames,factorNames)};
            countries = unique(obj.dataTable.(obj.countryType));
            countriesm = strrep(countries,'United Kingdom','UK');
            countriesm = strrep(countriesm,'United States','US');
            countriesm = cellfun(@(x) upper(x(1:2)),countriesm,'un',0);
            br = brewermap(12,'Set3');
            b = distinguishable_colors(numel(countries)-12);
            b = [br; b];
            M = max(PCscores);
            m = min(PCscores);
            %xlim([m(1),M(1)]);ylim([m(2),M(2)]);
            sizeFeatures = {'Track_MusicsEmotion','MusicWellBeing','PainSadness','TriumphEnergy','TendernessLove','Fear','Agression','Anger'};
            for j = 1:numel(sizeFeatures)
                figure
                t = tiledlayout(1,1);
                nexttile
                xline(0)
                yline(0)
                hold on
                for k = 1:numel(countries)
                    %disp(countries(k))
                    logCountry = matches(obj.dataTable.(obj.countryType), countries(k));
                    dataCountry = PCscores(logCountry,:);
                    dataSize=obj.dataTable.(sizeFeatures{j})(logCountry,:);

                    x(k) = averagingFCnIC(dataCountry(:,1));
                    y(k) = averagingFCnIC(dataCountry(:,2));
                    dz(k) = averagingFCnIC(dataSize);


                    % disp(averagingFCn(dataSize))

                    %axs = axis;
                    if all(sign(dataSize) == 1)
                        %s = scatter((dataCountry(:,1)),(dataCountry(:,2)),dataSize,b(k,:),'filled');
                    else
                        %s = scatter((dataCountry(:,1)),(dataCountry(:,2)),[],b(k,:),'filled');
                    end
                    % bubblechart(averagingFCn(dataCountry(:,1)),averagingFCn(dataCountry(:,2)),sum(iqr(dataCountry)),b(k,:),'MarkerFaceAlpha',0.20)
                    % bubblelegend('IQR','Location','northeastoutside')
                    %d = dscatter(dataCountry(:,1),dataCountry(:,2),'PlotType','Contour');

                    % [x,y,idx] = getDataForColorRange(d,[0.7 0.9]);
                    % c = d.Children
                    % c.CData(~idx) = NaN;
                    %d = scatter(dataCountry(:,1),dataCountry(:,2));
                    %d.MarkerFaceColor = b(k,:);
                    %d.MarkerEdgeColor = 'None';
                    %text(averagingFCn(dataCountry(:,1)),averagingFCn(dataCountry(:,2)),countriesm{k},'Color',b(k,:));

                    %axis(axs);
                end
                bubblechart(x,y,dz,b,'MarkerFaceAlpha',0.20,'MarkerEdgeColor','None');
                figure
                bubblechart(x,y,dz,b,'MarkerFaceAlpha',0.20);
                axs = axis;
                close
                axis(axs)
                text(x,y,countriesm,'HorizontalAlignment','Center');
                bubblelegend(sizeFeatures{j},'Location','northeastoutside')
                xlabel('<--Collectivism - Individualism-->')
                ylabel('<--Vertical - Horizontal-->')
                title(func2str(averagingFCn))
            end
        end
        function obj = plot2Dksdensity_2factorSolution(obj)
            addpath('~/Documents/MATLAB/dscatter')
            addpath('~/Documents/MATLAB/brewermap')
        %dscatter(obj.FAScores(:,1),obj.FAScores(:,2)),xlabel('Collectivism'),ylabel('Individualism')
            countries = unique(obj.dataTable.(obj.countryType));
            countriesm = strrep(countries,'United Kingdom','UK');
            countriesm = strrep(countriesm,'United States','US');
            countriesm = cellfun(@(x) upper(x(1:2)),countriesm,'un',0);
            b = brewermap(numel(countries),'Set3');
            M = max(obj.FAScores);
            m = min(obj.FAScores);
            %xlim([m(1),M(1)]);ylim([m(2),M(2)]);
            figure
            xline(0)
            yline(0)
            hold on
            for k = 1:numel(countries)
                logCountry = matches(obj.dataTable.(obj.countryType), countries(k));
                dataCountry = obj.FAScores(logCountry,:);
                %dataPain=obj.dataTable.PainSadness(logCountry,:);
                %bubblechart(median(dataCountry(:,1)),median(dataCountry(:,2)),median(dataPain),b(k,:),'MarkerFaceAlpha',0.20);
                %bubblelegend('PainSadness','Location','northeastoutside')
                bubblechart(median(dataCountry(:,1)),median(dataCountry(:,2)),sum(iqr(dataCountry)),b(k,:),'MarkerFaceAlpha',0.20)
                bubblelegend('IQR','Location','northeastoutside')
                %d = dscatter(dataCountry(:,1),dataCountry(:,2),'PlotType','Contour');

                % [x,y,idx] = getDataForColorRange(d,[0.7 0.9]);
                % c = d.Children
                % c.CData(~idx) = NaN;
                hold on
                %d = scatter(dataCountry(:,1),dataCountry(:,2));
                %d.MarkerFaceColor = b(k,:);
                %d.MarkerEdgeColor = 'None';
                %text(mean(dataCountry(:,1)),mean(dataCountry(:,2)),countriesm{k},'Color',b(k,:));
                text(median(dataCountry(:,1)),median(dataCountry(:,2)),countriesm{k},'HorizontalAlignment','Center');
                title([obj.rotateMethod ' rotation'])
            end
                xlabel('Collectivism')
                ylabel('Individualism')
        end
        function obj = indColAgeDensity(obj)
            for k = 1:numel(obj.ICscalesNames)
            [f(:,k),xi(:,k)] = ksdensity(obj.dataTable.Age,'Weights',obj.dataTable.(obj.ICscalesNames{k}));
            end
            area(xi,f)
            %area(xi,f./sum(f,2))
            legend(strrep(obj.ICscalesNames,'_',' '))
            hold on
            stem(obj.dataTable.Age,zeros(size(obj.dataTable.Age))+.001,'k')

        end
        function obj = indColPCAAgeDensity(obj)
            factorNames = {'IndCol','HorzVert'};
            c = brewermap(numel(factorNames),'Set2');
            icData = obj.dataTable(:,matches(obj.dataTable.Properties.VariableNames,factorNames));
            figure
            %icData{:,:} = rescale(icData{:,:}',-1,1)';% do not rescale factors!
            for k = 1:numel(factorNames)
                [f(:,k),xi(:,k)] = ksdensity(obj.dataTable.Age,'Weights',icData{:,k});
            end
            plot(xi,f,'LineWidth',2)
            for k = 1:numel(factorNames)
                p(k).Color = c(k,:);
            end
            axis tight
            l = legend(strrep(factorNames,'_',' '),'Location','NorthOutside','AutoUpdate','off');
            %area(xi,f./sum(f,2))
            hold on
            stem(obj.dataTable.Age,zeros(size(obj.dataTable.Age))+.001,'k')
            xlim([17 87])
            ylabel({'<--Collectivism - Individualism-->'; '<--Vertical - Horizontal-->'});
            title('Kernel density for age, weighted by IC/HV factors (PCs 2 and 3)')
            xlabel('Age')
        end
        function obj = exploreIndColCategory(obj)
            icCompleteLogical = ~any(isundefined(obj.dataTable.IndColCategory),2);
            dataTableICcomplete = obj.dataTable(icCompleteLogical,:);
            T = dataTableICcomplete(:,matches(dataTableICcomplete.Properties.VariableNames,{'IndColCategory', obj.countryType}));
        % horizontal/vertical
            G = groupsummary(T,{obj.countryType,'IndColCategory'},'IncludeEmptyGroups',true);
            d = reshape(G.GroupCount,numel(categories(T.IndColCategory)),[])';
            dNorm = d./sum(d,2);
            [S I] = sort(sum(dNorm(:,3:4),2));
            g = get(groot,'defaultfigureposition');
            g(4) = g(4)*2;
            figure('Position',g)
            b = barh(dNorm(I,:),'stacked');
            yticks(1:size(dNorm,1))
            C = unique(G.(obj.countryType));
            yticklabels(C(I))
            legend(strrep(categories(G.IndColCategory),'_',' '),'Location','NorthOutside','AutoUpdate','Off')
            title({['Frequency of Individualism/collectivism category '];['per '  lower(strrep(obj.countryType,'_',' of ')) ' (normalized to sum 1)']})
            xline(.5,'--');
            ax = gca;
            ax.FontSize = 16;
            % coll/ind
            C = reordercats(T.IndColCategory,[1 3 2 4]);
            T.IndColCategory = C;
            G = groupsummary(T,{obj.countryType,'IndColCategory'},'IncludeEmptyGroups',true);
            d = reshape(G.GroupCount,numel(categories(T.IndColCategory)),[])';
            dNorm = d./sum(d,2);
            [S I] = sort(sum(dNorm(:,3:4),2));
            g = get(groot,'defaultfigureposition');
            g(4) = g(4)*2;
            figure('Position',g)
            b = barh(dNorm(I,:),'stacked');
            yticks(1:size(dNorm,1))
            C = unique(G.(obj.countryType));
            yticklabels(C(I))
            legend(strrep(categories(G.IndColCategory),'_',' '),'Location','NorthOutside','AutoUpdate','Off')
            title({['Frequency of Individualism/collectivism category '];['per '  lower(strrep(obj.countryType,'_',' of ')) ' (normalized to sum 1)']})
            xline(.5,'--');
            ax = gca;
            ax.FontSize = 16;
        end
        function obj = indColCategoryANOVA(obj)
            addpath('~/Documents/MATLAB/violin')
            a = do_factor_analysis(obj);
            for k = 1:size(a.FAScores,2)
                FAs{k} = a.FAScores(:,k);
            end
            obj.dataTable = addvars(obj.dataTable,FAs{:},'After','Rebelliousness','NewVariableNames',obj.FactorNames);
            obj.dataTable(:,16:48) = []; % REMOVE HARDCODED EMO LOCATIONS
            obj.dataTable = removevars(obj.dataTable,{'RespondentID','Childhood','Adulthood','Residence','Identity','Duration','Employment','Gender','Horizontal_individualism','Horizontal_collectivism','Vertical_individualism','Vertical_collectivism'});
            obj.dataTable(any(obj.dataTable.Education == 7:9,2),:)=[];
            % remove people from 'Other' gender
            obj.dataTable(obj.dataTable.GenderCode == 3,:) = [];
            icCompleteLogical = ~any(isundefined(obj.dataTable.IndColCategory),2);
            dataTableICcomplete = obj.dataTable(icCompleteLogical,:);
            S = vartype('numeric');
            IV = dataTableICcomplete.IndColCategory;
            DVs = dataTableICcomplete(:,S);
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
                    text(1:numel(row2),repmat(range([lims(1), lims(2)])*3/100+lims(1),1,numel(row2)),row2,'HorizontalAlignment','Center')
                    F = num2str(cell2mat(tbl(2,end-1)),'%.2f');
                    P = strrep(num2str(cell2mat(tbl(2,end)),'%.3f'),'0.','.');
		    title([strrep(DVs.Properties.VariableNames{k},'_',' ') ' - F=' F ', p=' P]);
                    %boxplot(DVs{:,k},IV,'Notch','on')
                end
            end
        end
        function obj = do_explore_indiv_collect(obj)
            % a = stats.factor_analysis(obj.dataPath,obj.filterMethod);
            % for k = 1:size(a.FAScores,2)
            %     FAs{k} = a.FAScores(:,k);
            % end
            % obj.dataTable = addvars(obj.dataTable,FAs{:},'After','Rebelliousness','NewVariableNames',obj.FactorNames);
            icCompleteLogical = ~any(isnan(obj.dataTable{:,matches(obj.dataTable.Properties.VariableNames,obj.ICscalesNames)}),2);
            dataTableICcomplete = obj.dataTable(icCompleteLogical,:);
            T = dataTableICcomplete(:,matches(dataTableICcomplete.Properties.VariableNames,[obj.ICscalesNames obj.countryType]));

            title('Individualism/collectivism ratings across all participants')
            boxplot(T{:,2:end})
            xticklabels(T.Properties.VariableNames(2:end))

            V = varfun(@mean,T,'GroupingVariables',obj.countryType);
            V = sortrows(V,3);
            Tnorm = T;
            Tnorm{:,2:end} = T{:,2:end}./sum(T{:,2:end},2);
            Vnorm = varfun(@mean,Tnorm,'GroupingVariables',obj.countryType);

            [S I] = sort(sum(Vnorm{:,3:4},2));
            Vnorm = Vnorm(I,:);
            figure
            bar(V{:,3:end})
            xticks(1:size(V,1))
            xticklabels(V{:,1})
            legend(strrep(erase(string(V.Properties.VariableNames(3:end)),{'mean_'}),'_',' '));
            title(['Mean individualism/collectivism ratings per ' lower(strrep(obj.countryType,'_',' of '))])
            g = get(groot,'defaultfigureposition');
            g(4) = g(4)*2;
            figure('Position',g)
            b = barh(Vnorm{:,3:end},'stacked');
            yticks(1:size(Vnorm,1))
            yticklabels(Vnorm{:,1})
            legend(strrep(erase(string(Vnorm.Properties.VariableNames(3:end)),{'mean_'}),'_',' '),'Location','NorthOutside','AutoUpdate','Off');
            xline(.5,'--');
            title({['Mean individualism/collectivism per '  lower(strrep(obj.countryType,'_',' of '))];[ ' (normalized to sum 1)']})
            ax = gca;
            ax.FontSize = 16;
            g = get(groot,'defaultfigureposition');
            g(4) = g(4)*2;
            figure('Position',g)
            VnormHV = movevars(Vnorm,Vnorm.Properties.VariableNames(contains(Vnorm.Properties.VariableNames,'Vertical')),'After',size(Vnorm,2));
            [S I] = sort(sum(VnormHV{:,3:4},2));
            VnormHV = VnormHV(I,:);
            b = barh(VnormHV{:,3:end},'stacked');
            yticks(1:size(VnormHV,1))
            yticklabels(VnormHV{:,1})
            legend(strrep(erase(string(VnormHV.Properties.VariableNames(3:end)),{'mean_'}),'_',' '),'Location','NorthOutside','AutoUpdate','Off');
            xline(.5,'--');
            title({['Mean individualism/collectivism per '  lower(strrep(obj.countryType,'_',' of '))];[ ' (normalized to sum 1)']})
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
            p = stats.explore_indiv_collect.makestars(p);
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
            tab = stats.explore_indiv_collect.makeTableWithVarNamesStars(corrMat,pMat,xt,yt);
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
