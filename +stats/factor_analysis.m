classdef factor_analysis < load_data.load_data
%example obj = stats.factor_analysis();obj=do_load_data(obj);obj = do_factor_analysis(obj)

    properties
        dataTableInd = [16:48]; % emotion terms (obj.dataTable)
        rotateMethod = 'Varimax';
        emo
        emoLabels
        showPlotsAndTextFA = 1;
        distanceM = 'euclidean';
        removeLeastRatedTerms = 1;
        removalPercentage = .1;
        removedEmotions
        removeEmoTermsManually = 0; %select manually emotions to remove
        %emoToRemove  % = {'Spirituality','Longing','Amusement','Security','Belonging'};
        emoToRemove% = {'Tension','Eroticism'};
        PCNum =3;%number of factors
        sumSquaredLoadings
        maxLoadingValues
        FAcoeff
        FAScores
        factorNames
    end
    methods
        function obj = factor_analysis(obj)
        end
        function obj = do_factor_analysis(obj)
            % if nargin < 2
            %     error('ErrorTests:convertTest',...
            %           'Choose a filter method: \n  AllResponses \n  BalancedSubgroups');
            % end
            % if nargin == 0
            %     dataPath = [];
            %     filterMethod = [];
            % end
                obj.emoLabels = obj.dataTable.Properties.VariableNames(obj.dataTableInd);% emotion terms (obj.dataTable)
                obj.emo = obj.dataTable{:,obj.dataTableInd};
                obj = correct_emoLabels(obj);
            if obj.removeEmoTermsManually==1
                obj = removeEmotionTerms(obj);
            end
            if obj.showPlotsAndTextFA==1
                obj = plot_means(obj);
                obj = hierarchical_clust(obj);
                %obj = vif(obj);
            end
            if ~strcmpi(obj.filterMethod,'AllResponses') && obj.showPlotsAndTextFA == 1
                obj = dendrogram_categories(obj);
                %obj = cronbach_categories(obj);
            end
            if obj.removeLeastRatedTerms == 1
                obj = remove_least_rated_terms(obj);
            end
            if obj.showPlotsAndTextFA==1
                obj = pca_emo(obj);
            end
            obj = fa(obj);
            % if ~strcmpi(obj.filterMethod,'AllResponses')
            %     obj = anova_fa(obj);
            % end
            % I commented this because I get 'X and GROUP must have the
            % same length' error when running this class with IC items
        end
        function obj = plot_means(obj)
            if obj.showPlotsAndTextFA == 1
                disp('*** MEANS AND STANDARD DEVIATIONS ***')
            end
            t_m = table(obj.emoLabels', mean(obj.emo)',std(obj.emo)',...
                'VariableNames',{'Emotion','Mean score','Standard deviation'});
            t_m = sortrows(t_m,2,'descend');
            figure
            errorbar(table2array(t_m(:,2)),table2array(t_m(:,3))/2,'-s','markersize',7,...
                     'markeredgecolor','k','markerfacecolor','k','linewidth',1.5);
            set(gca,'XTick',1:(height(t_m)),'XTickLabels',strrep(table2array(t_m(:,1)),'_',' '),'FontSize',12),xtickangle(90)
            xlabel('Emotions','FontSize',14),ylabel('Mean ratings','FontSize',14)
            %title('Means and standard deviations of emotion terms')
            snapnow
            if obj.showPlotsAndTextFA == 1
                disp(t_m);
            end
        end
        function obj = pca_emo(obj)
            [pcLoadings, pcSores, eigenvalues, ~, explainedVar] = pca(obj.emo);
            %make scree plot
            if obj.showPlotsAndTextFA == 1
                disp('*** PCA ***')
                disp('Find optimal number of PCs from scree plot and MAP criterion')
            end
            figure
            subplot(1,2,1)
            plot(eigenvalues)
            xlabel('PCs');ylabel('Eigenvalues')
            title('Eigenvalues Scree plot')
            subplot(1,2,2)
            plot(cumsum(explainedVar))
            xlabel('PCs');ylabel('Cumulative variance explained')
            title('Cumulative variance explained by PCs')
            snapnow
            if obj.showPlotsAndTextFA == 1
                disp(['Selected ' num2str(obj.PCNum) ' Pcs']);
            end
            exp_var = cumsum(explainedVar(1:obj.PCNum));
            if obj.showPlotsAndTextFA == 1
                disp([num2str(exp_var(end)) '% of variance explained by first ' ...
                      num2str(obj.PCNum) ' Pcs']);
            end
        end
        function  obj = fa(obj)
            [obj.FAcoeff, psi, ~, stats,obj.FAScores] = factoran(obj.emo,obj.PCNum,'Rotate',obj.rotateMethod);
            if obj.showPlotsAndTextFA == 1
                disp(['*** FACTOR ANALYSIS (' obj.rotateMethod 'rotation)***'])
            end
            for i=1:obj.PCNum
                t=sortrows(table(obj.FAcoeff(:,i),obj.emoLabels','VariableNames',...
                    {'FALoadings','Emotions'}),1,'descend');
                obj.factorNames{i} = table2array(t(1:2,2))';
                obj.factorNames{i} = char(append(obj.factorNames{i}(1), '-',...
                    obj.factorNames{i}(2)));
            end
            if obj.showPlotsAndTextFA==1
               fName = array2table(obj.factorNames','VariableNames',{'Factor Names'});
               disp(fName)
            end
            obj.maxLoadingValues = array2table(max(obj.FAcoeff),'VariableNames',obj.factorNames);
            obj.sumSquaredLoadings = array2table(sum(obj.FAcoeff.^2),'VariableNames',obj.factorNames);
            if obj.showPlotsAndTextFA==1
                disp(['*** SUM OF SQUARED LOADINGS ***'])
                disp(obj.sumSquaredLoadings)
                %disp([': ' num2str(sum(obj.FAcoeff.^2))])
                figure
                y = sort_fa_loadings(obj);
                heatmap(y{1})
                ax = gca; ax.YDisplayLabels = num2cell(y{2});
                ax.YDisplayLabels = strrep(ax.YDisplayLabels,'_',' ');
                %title('Factor Loadings')
                snapnow
               % figure
               % bar(mean(obj.FAScores))
               % title('Factor Score Means')
               % xlabel('Factors');ylabel('Mean factor score')
               % xticklabels(obj.factorNames);
               % xtickangle(45);
               % snapnow
            end
        end
        function obj = anova_fa(obj)
            [groupings,groupNames] = findgroups(obj.groupTable(:,obj.groupingCategory));
            %disp('*** ANOVA Factor Scores ***')
            figure
            for i = 1:obj.PCNum
                fName = append('Factor ', num2str(i), ': ', obj.factorNames{i});
                    disp(['ANOVA ' fName])
                [p(i),tbl{i}] = anova1(obj.FAScores(:,i),obj.groupTable.Country_childhood,'on');
                close
                snapnow
                [FAScoreMeans] = splitapply(@mean,obj.FAScores(:,i),groupings);
                if obj.showPlotsAndTextFA==1
                    figure
                    bar(FAScoreMeans)
                    xticklabels(table2array(groupNames));
                    xtickangle(45);
                    title(fName)
                    xlabel('Groups'); ylabel('Factor Scores');
                    snapnow
                end
            end
        end
        function obj = hierarchical_clust(obj)
            linkageMethod = 'average';
            if obj.showPlotsAndTextFA == 1
                disp('*** HIERARCHICAL CLUSTERING ***')
                disp('Pairwises distances computed between variables')
                disp(['Distance: ' obj.distanceM])
                disp(['Linkage Method: ' linkageMethod])
            end
            d = pdist(obj.emo',obj.distanceM);
            l = linkage(d,linkageMethod);
            figure
            dendrogram(l,33,'orientation','right','labels',strrep(obj.emoLabels,'_',' '));
            title('Dendrogram of emotion ratings')
            snapnow
            %Cluster evaluation
            cluster_num = [2:6];
            for k = cluster_num
                linkmethod = @(x,c) clusterdata(x,'linkage','average','distance',obj.distanceM,'maxclust',c);
                eva_link{k-1} = evalclusters(obj.emo',linkmethod,'silhouette','distance',obj.distanceM,'klist',k,'ClusterPriors','empirical');
            end
            silh_val = cell2mat(cellfun(@(x) x.CriterionValues, eva_link,'uni',false)); %get silhouettes
            [opt_sil_value,idx] = max(silh_val); %get cluster solution with max silhouette
            optimal_cnum = cluster_num(idx); %optimal number of clusters
                                             %figure
                                             %silhouette(eva_link{idx}.X,eva_link{idx}.OptimalY,'euclidean')
                                             %title('Silhouette');
                                             %snapnow
                                             %disp('Silhouette values for best cluster')
                                             %disp(array2table([optimal_cnum' opt_sil_value'],'VariableNames',{'Optimal number of clusters','Silhouette value'},'RowNames',{'Alldata'}));
                                             %disp('Silhouette values for each cluster')
                                             %disp(array2table(silh_val','VariableNames',{'All data'},'RowNames',cellstr(string(cluster_num))));
        end
        function obj = vif(obj)
        % Variance inflation factor
            R = corrcoef(obj.emo);
            VIF = diag(inv(R));
            VIF_t = array2table(VIF,'VariableNames',{'VIF'},'RowNames',obj.emoLabels);
            disp('Variance Inflation Factors')
            sortrows(VIF_t,1,'descend')
        end
        function obj = dendrogram_categories(obj)
            remove_diagonal = @(t)reshape(t(~diag(ones(1,size(t, 1)))), size(t)-[1 0]);
            for i = 1:length(obj.subgroupNames)
                d(:,i) = pdist(obj.emo(strcmpi(obj.subgroupNames(i),...
                                               table2array(obj.dataTable(:,obj.groupingCategory))),:)',obj.distanceM);
                sqForm{i} = squareform(d(:,i));
                sqForm{i} = remove_diagonal(sqForm{i});
            end
            t_corr = corr(d,'rows','complete');
            figure, hold on
            imagesc(t_corr), colorbar
            ax = gca;
            ax.YTick = 1:length(obj.subgroupNames);
            ax.XTick = 1:length(obj.subgroupNames);
            ax.YTickLabel = obj.subgroupNames;
            ax.XTickLabel = obj.subgroupNames;
            ax.XTickLabelRotation = 45;
            hold off
            title('Correlations between Countries')
            snapnow
            for i=1:length(sqForm{1})
                dCat{i} = cell2mat(arrayfun(@(x) x{:}(:,i), sqForm, 'UniformOutput', false));
                alpha(i,1) = stats.factor_analysis.cronbach(dCat{i});
            end
                disp('*** CROSS-CULTURAL CONSISTENCY OF EMOTION TERMS ***')
                disp('Running Cronbachs Alpha on pairwise distances vector of each emotion between LANGUAGES')
            t_alpha = array2table(alpha,'VariableNames',{'CronbachAlpha'},'RowNames',obj.emoLabels);
                disp(sortrows(t_alpha,1,'descend'));
        end
        function obj = removeEmotionTerms(obj)
            for i=1:length(obj.emoToRemove)
                idx(i) = find(strcmpi(obj.emoToRemove{i},obj.emoLabels));
            end
            obj.emo(:,idx) = [];
            obj.emoLabels(:,idx) = [];
        end
        function obj = remove_least_rated_terms(obj)
        %number of emotions to remove
            removeEmoNum = floor(obj.removalPercentage*length(mean(obj.emo)));
            %remove least rated emotions
            [b,idx] = sort(mean(obj.emo),'descend');
            obj.removedEmotions = obj.emoLabels(idx(end-removeEmoNum+1:end));
            if obj.showPlotsAndTextFA==1
                disp('*** REDUCING EMOTION LIST ***')
                disp(['Removing ' num2str(obj.removalPercentage*100) '% of' ...
                      ' least rated emotions'])
                disp(array2table(obj.removedEmotions','VariableNames',{'Emotions removed'}));
            end
            idx = idx(1:end-removeEmoNum);
            idx = sort(idx,'ascend');
            obj.emo = obj.emo(:,idx);
            obj.emoLabels = obj.emoLabels(:,idx);
        end
        function obj = correct_emoLabels(obj)
            idx = find(strcmpi('Curiousity',obj.emoLabels));
            if idx
                obj.emoLabels{idx} = 'Curiosity';
            end
        end
        function obj = cronbach_categories(obj)
            remove_diagonal = @(t)reshape(t(~diag(ones(1,size(t, 1)))), size(t)-[1 0]);
            [groupings,groupnames] = findgroups(obj.dataTable(:,obj.groupingCategory));
            for i = 1:size(obj.emo,1)
                disParticipant{i} = remove_diagonal(squareform(pdist(obj.emo(i,:)')));
            end
            for i=1:size(obj.emo,2)
                disEmo = cell2mat(arrayfun(@(x) x{:}(:,i), disParticipant, 'UniformOutput', false));
                alphasCat(i,:) = splitapply(@cronbach,disEmo',groupings);
                alphasWhole(i,1) = cronbach(disEmo');
            end
            t_alpha = array2table([alphasWhole alphasCat],'VariableNames',[{'Global'}; table2array(groupnames)],'RowNames',obj.emoLabels);
            if obj.showPlotsAndTextFA==1
                disp(t_alpha);
            end
        end
        function y = sort_fa_loadings(obj)
            thx = 0.40;
             for i=1:size(obj.FAcoeff,2)-1
                 [l,idx{i}] = sort(obj.FAcoeff(:,i),'descend');
                 idx{i} = idx{i}(l>=thx);
             end
             [l,idx{i+1}] = sort(obj.FAcoeff(:,i+1),'descend');
             idx{i+1} = idx{i+1};
             idx = unique(cell2mat(idx(:)),'stable');
             %otherEmo = [1:30]';
             %otherEmo = setdiff(otherEmo,idx);
             %idx = [idx',otherEmo'];
             y{1} = obj.FAcoeff(idx',:);
             y{2} = obj.emoLabels(idx');
        end
    end
    methods (Static)
        function a=cronbach(X)
        %Syntax: a=cronbach(X)
        %_____________________
        %
        % Calculates the Cronbach's alpha of a data set X.
        %
        % a is the Cronbach's alpha.
        % X is the data set.
        %
        %
        % Reference:
        % Cronbach L J (1951): Coefficient alpha and the internal structure of
        % tests. Psychometrika 16:297-333
        %
        %
        % Alexandros Leontitsis
        % Department of Education
        % University of Ioannina
        % Ioannina
        % Greece
        %
        % e-mail: leoaleq@yahoo.com
        % Homepage: http://www.geocities.com/CapeCanaveral/Lab/1421
        %
        % June 10, 2005.


            if nargin<1 | isempty(X)==1
                error('You shoud provide a data set.');
            else
                % X must be a 2 dimensional matrix
                if ndims(X)~=2
                    error('Invalid data set.');
                end
            end


            % Calculate the number of items
            k=size(X,2); % how many variables

            % Calculate the variance of the items' sum
            VarTotal=var(sum(X')); % sum across items, then variance across
                                   % subjects: high if subjects differ a lot

            % Calculate the item variance
            SumVarX=sum(var(X)); % sum across subjects, then variance across
                                 % items: high if items differ a lot

            % Calculate the Cronbach's alpha
            a=k/(k-1)*(VarTotal-SumVarX)/VarTotal;
        end
    end
end
