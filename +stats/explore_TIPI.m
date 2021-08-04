classdef explore_TIPI < load_data.load_data
%example: obj = stats.explore_TIPI('responses_pilot/Music Listening Habits.csv','AllResponses');do_explore_TIPI(obj);

    properties
    end
    methods
        function obj = explore_TIPI(dataPath,filterMethod)
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
        function obj = do_explore_TIPI(obj)
            obj.dataTable = removevars(obj.dataTable,{'RespondentID','Childhood','Adulthood','Residence','Identity','Duration'});
            tipiCompleteLogical = ~any(isnan(obj.dataTable{:,matches(obj.dataTable.Properties.VariableNames,obj.TIPIscalesNames)}),2);
            dataTableTIPIcomplete = obj.dataTable(tipiCompleteLogical,:);
            S = vartype('numeric');
            numericT = dataTableTIPIcomplete(:,S);
            numericTnoNaNs = numericT(~any(isnan(numericT{:,:}),2),:);


            c = corr(numericTnoNaNs{:,:});
            c(triu(true(size(c)),1)) = NaN;
            figure('units','normalized','outerposition',[0 0 1 1])
            h = heatmap(c); % try to make it a heatmap so it's easier to navigate!
            h.XDisplayLabels = strrep(numericTnoNaNs.Properties.VariableNames,'_',' ');
            h.YDisplayLabels = strrep(numericTnoNaNs.Properties.VariableNames,'_',' ');
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
            h.XDisplayLabels = strrep(numericTnoNaNs.Properties.VariableNames,'_',' ');
            h.YDisplayLabels = strrep(numericTnoNaNs.Properties.VariableNames,'_',' ');
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
            h.XDisplayLabels = strrep(numericTnoNaNs.Properties.VariableNames,'_',' ');
            h.YDisplayLabels = strrep(numericTnoNaNs.Properties.VariableNames,'_',' ');
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
