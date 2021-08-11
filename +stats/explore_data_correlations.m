classdef explore_data_correlations < load_data.load_data & stats.factor_analysis
%example: obj = stats.explore_data_correlations();obj.filterMethod='AllResponses';obj=do_load_data(obj);obj=do_explore_data_correlations(obj);correlate_features_and_plot(obj);steplm(obj)

    properties
            FactorNames = {'TendernessLove','TriumphEnergy','PainSadness','PleasureHappiness'};
            data
    end
    methods
        function obj = explore_data_correlations(obj)
            obj=do_load_data(obj);
        end
        function obj = do_explore_data_correlations(obj)
            a = do_factor_analysis(obj);
            for k = 1:size(a.FAScores,2)
                FAs{k} = a.FAScores(:,k);
            end
            obj.dataTable = addvars(obj.dataTable,FAs{:},'After','Rebelliousness','NewVariableNames',obj.FactorNames);
            %obj.dataTable(:,16:48) = []; % REMOVE HARDCODED EMO LOCATIONS
            % remove variables that are difficult to make ordinal
            obj.dataTable = removevars(obj.dataTable,{'RespondentID','Childhood','Adulthood','Residence','Identity','Duration','Employment','IndColCategory'});
            % remove people from 'Other' gender
            obj.dataTable(obj.dataTable.GenderCode == 3,:) = [];
            obj.dataTable(any(obj.dataTable.Education == 7:9,2),:)=[];
            tipiCompleteLogical = ~any(isnan(obj.dataTable{:,matches(obj.dataTable.Properties.VariableNames,obj.TIPIscalesNames)}),2);
            dataTableTIPIcomplete = obj.dataTable(tipiCompleteLogical,:);
            S = vartype('numeric');
            numericT = dataTableTIPIcomplete(:,S);
            obj.data = numericT(~any(isnan(numericT{:,:}),2),:);
            icVarInd = find(matches(obj.data.Properties.VariableNames, obj.icVars));
            [coeff, score, ~, ~, explained] = pca(obj.data{:,icVarInd},'NumComponents',3);
            PCnames = {'IndCol','HorzVert'};
            obj.data = addvars(obj.data,score(:,2),score(:,3),'NewVariableNames',PCnames);
        end
        function obj = steplm(obj)
            DV = [obj.FactorNames obj.dataTable.Properties.VariableNames(contains(obj.dataTable.Properties.VariableNames,{'Music_','Track_'}))];
            IV = obj.data(:,~matches(obj.data.Properties.VariableNames,DV));
            for k = 1:numel(DV)
                data = addvars(IV,obj.data.(DV{k}),'After',size(IV,2),'NewVariableNames',DV{k});
                data{:,:} = zscore(data{:,:});
                mdl = stepwiselm(data,'Upper','linear','Verbose',0,'Criterion','aic');
                disp(mdl.Formula)
                M = mdl.Coefficients;
                M(1,:) = [];
                C = sortrows(M(:,1),'Estimate','descend');
                C.Properties.VariableNames = {'Standardized beta'};
                R2 = arrayfun(@(x) strrep(num2str(x,'%.2f'),'0.','.'), struct2array(mdl.Rsquared),'un',0);
                disp(['R-squared = ', R2{1} ', Adjusted R-squared = ' R2{2}])
                disp(C);
                disp('----------------------------------------------------------------')
            end
        end
        function obj = correlate_features_and_plot(obj)
        %obj.data = obj.data(obj.data.GenderCode == 1,:)% select a gender

            obj.data(:,find(matches(obj.data.Properties.VariableNames, 'MusicWellBeing'))+1:find(matches(obj.data.Properties.VariableNames, 'IndCol'))-1)=[];

            c = corr(obj.data{:,:});
            c(triu(true(size(c)),1)) = NaN;
            figure('units','normalized','outerposition',[0 0 1 1])
            h = heatmap(c); % try to make it a heatmap so it's easier to navigate!
            h.XDisplayLabels = strrep(obj.data.Properties.VariableNames,'_',' ');
            h.YDisplayLabels = strrep(obj.data.Properties.VariableNames,'_',' ');
            h.FontSize = 12;
            % show max highlights
            tf = eye(size(c))==1;
            c(tf) = NaN;
            [m,I] = max(c,[],'Linear');
            highlights = nan(size(c));
            logPos = sign(m) == 1;
            highlights(I(logPos)) = m(logPos);

            figure('units','normalized','outerposition',[0 0 1 1])
            h = heatmap(highlights); % try to make it a heatmap so it's easier to navigate!
            h.XDisplayLabels = strrep(obj.data.Properties.VariableNames,'_',' ');
            h.YDisplayLabels = strrep(obj.data.Properties.VariableNames,'_',' ');
            h.FontSize = 12;
            title('Maximum positive correlation of each variable')


            % show min highlights
            tf = eye(size(c))==1;
            c(tf) = NaN;
            [m,I] = min(c,[],'Linear');
            highlights = nan(size(c));
            logNeg = sign(m) == -1;
            highlights(I(logNeg)) = m(logNeg);

            figure('units','normalized','outerposition',[0 0 1 1])
            h = heatmap(highlights); % try to make it a heatmap so it's easier to navigate!
            h.XDisplayLabels = strrep(obj.data.Properties.VariableNames,'_',' ');
            h.YDisplayLabels = strrep(obj.data.Properties.VariableNames,'_',' ');
            h.FontSize = 12;
            title('Minimum negative correlation of each variable')
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
            p = stats.explore_TIPI.makestars(p);
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
            tab = stats.explore_TIPI.makeTableWithVarNamesStars(corrMat,pMat,xt,yt);
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
