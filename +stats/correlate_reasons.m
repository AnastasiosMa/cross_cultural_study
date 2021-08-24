classdef correlate_reasons < load_data.load_data
%example: obj = stats.correlate_reasons();obj.filterMethod='BalancedSubgroups';obj=do_load_data(obj);spider_reasons_country(obj); do_mean_reasons(obj);do_correlate_reasons(obj);

    properties
        countryType = 'Country_childhood';
    end
    methods
        function obj = correlate_reasons(dataPath,filterMethod)
            obj=do_load_data(obj);
        end
        function obj = spider_reasons_country(obj)
                        addpath('~/Documents/MATLAB/spider_plot')
                        addpath('~/Documents/MATLAB/distinguishable_colors')
                        reasonLabels = {'for background purposes'
                            'to bring up memories'
                            'to have fun'
                            'to feel music´s emotions'
                            'to change your mood'
                            'to express yourself'
                            'to feel connected to other people'};
                        reasonTypes = {'General Behavior','Selected Track'};
                        countries = unique(obj.dataTable.(obj.countryType));
                        countriesm = strrep(countries,'United Kingdom','UK');
                        countriesm = strrep(countriesm,'United States','US');
                        countriesm = cellfun(@(x) upper(x(1:2)),countriesm,'un',0);
                        % br = brewermap(12,'Set3');
                        % b = distinguishable_colors(numel(countries)-12);
                        % b = [br; b];
                        b = distinguishable_colors(numel(countries));
                        reasonTypesKey = {'Music_','Track_'};
                        figure('units','normalized','outerposition',[0 0 1 1])
                        for j = 1:numel(reasonTypesKey)
                            for k = 1:numel(countries)
                                logCountry = matches(obj.dataTable.(obj.countryType), countries(k));
                                reasonData = obj.dataTable(:,contains(obj.dataTable.Properties.VariableNames,reasonTypesKey{j}));
                                reasonDataCountry(j,k,:) = nanmean(reasonData{logCountry,:});
                            end
                            subplot(2,1,j)
                            spider_plot(squeeze(reasonDataCountry(j,:,:)),'AxesLabels',reasonLabels,'Color',b)
                            if j == 1
                                l = legend(countriesm,'Location','EastOutside','Orientation','Vertical');
                            end
                        end
                        l.Position(1) = 0;
                        keyboard(2) = 0;
        end
        function obj = do_mean_reasons(obj)
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
                X = tableFunctions{:,:};
                X(any(isnan(X), 2), :) = [];% remove nan rows

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
                set(gca,'xticklabel',reasonLabels)
                myTitle = ['Mean and SD of reasons, ' ReasonType ',' filterMethod ' (N=' num2str(size(X,1)) ')'];
                title(myTitle)
                stats.correlate_reasons.savefigures(['figures/correlate_reasons/mean_reasons_' obj.filterMethod])
                hold off
            end
        end
        function obj = do_correlate_reasons(obj)
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
                X = tableFunctions{:,:};
                X(any(isnan(X), 2), :) = [];% remove nan rows
                [rho pval]= corr(X);
                myTitle = ['Correlations between reasons, ' ReasonType ',' filterMethod ' (N=' num2str(size(X,1)) ')'];
                figure
                stats.correlate_reasons.plotCorrMat(rho,pval,reasonLabels,myTitle);
                stats.correlate_reasons.savefigures(['figures/correlate_reasons/correlate_reasons_' obj.filterMethod])
            end
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
            p = stats.correlate_reasons.makestars(p);
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
            tab = stats.correlate_reasons.makeTableWithVarNamesStars(corrMat,pMat,xt,yt);
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
