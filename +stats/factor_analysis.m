classdef factor_analysis < load_data.load_data
%example obj = stats.factor_analysis();obj=do_load_data(obj);obj = do_factor_analysis(obj)

    properties
        dataTableInd = [16:48]; % emotion terms (obj.dataTable)
        rotateMethod = 'Varimax'
        emo
        emoLabels
        showPlotsAndTextFA = 0;
        distanceM = 'euclidean';
        removeLeastRatedTerms = 1;
        removalPercentage = .2;
        removedEmotions
        removeEmoTermsManually = 0; %select manually emotions to remove
        emoToRemove  % = {'Spirituality','Longing','Amusement','Security','Belonging'};
                     %emoToRemove = {'Tension','Eroticism'};
        PCNum =4;%number of factors
        FAcoeff
        FAscores
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
            if ~strcmpi(obj.filterMethod,'AllResponses')
                obj = dendrogram_categories(obj);
                obj = cronbach_categories(obj);
            end
            if obj.removeLeastRatedTerms == 1
                obj = remove_least_rated_terms(obj);
            end
            if obj.showPlotsAndTextFA==1
                obj = pca_emo(obj);
            end
            obj = fa(obj);
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
            set(gca,'XTick',1:(height(t_m)),'XTickLabels',table2array(t_m(:,1)),'FontSize',12),xtickangle(90)
            xlabel('Emotions','FontSize',14),ylabel('Mean ratings','FontSize',14)
            title('Means and standard deviations of emotion terms')
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
            [obj.FAcoeff, psi, ~, stats,obj.FAscores] = factoran(obj.emo,obj.PCNum,'Rotate',obj.rotateMethod);
            if obj.showPlotsAndTextFA == 1
                disp(['*** FACTOR ANALYSIS (' obj.rotateMethod 'rotation)***'])
            end
            if obj.showPlotsAndTextFA==1
                figure
                heatmap(obj.FAcoeff)
                ax = gca; ax.YDisplayLabels = num2cell(obj.emoLabels);
                title('Factor Loadings')
                snapnow
            end
        end
        function obj = hierarchical_clust(obj)
            linkageMethod = 'average';
            if obj.showPlotsAndTextFA == 1
                disp('*** HIERARCHICAL CLUSTERING ***')
                disp('Pairwises distances computed between EMOTION TERMS')
                disp(['Distance: ' obj.distanceM])
                disp(['Linkage Method: ' linkageMethod])
            end
            d = pdist(obj.emo',obj.distanceM);
            l = linkage(d,linkageMethod);
            dendrogram(l,33,'orientation','right','labels',obj.emoLabels);
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
            %figure, hold on
            %imagesc(t_corr), colorbar
            %ax = gca;
            %ax.YTick = 1:length(obj.subgroupNames);
            %ax.XTick = 1:length(obj.subgroupNames);
            %ax.YTickLabel = obj.subgroupNames;
            %ax.XTickLabel = obj.subgroupNames;
            %hold off
            %title('Correlations between languages')
            %snapnow
            for i=1:length(sqForm{1})
                dCat{i} = cell2mat(arrayfun(@(x) x{:}(:,i), sqForm, 'UniformOutput', false));
                alpha(i,1) = stats.factor_analysis.cronbach(dCat{i});
            end
            if obj.showPlotsAndTextFA == 1
                disp('*** CROSS-CULTURAL CONSISTENCY OF EMOTION TERMS ***')
                disp('Running Cronbachs Alpha on pairwise distances vector of each emotion between LANGUAGES')
            end
            t_alpha = array2table(alpha,'VariableNames',{'CronbachAlpha'},'RowNames',obj.emoLabels);
            if obj.showPlotsAndTextFA == 1
                disp(sortrows(t_alpha,1,'descend'));
            end
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
            groupings = findgroups(obj.dataTable(:,obj.groupingCategory));
            for i = 1:size(obj.emo,1)
                disParticipant{i} = remove_diagonal(squareform(pdist(obj.emo(i,:)')));
            end
            for i=1:size(obj.emo,2)
                disEmo = cell2mat(arrayfun(@(x) x{:}(:,i), disParticipant, 'UniformOutput', false));
                alphasCat(i,:) = splitapply(@stats.factor_analysis.cronbach,disEmo',groupings);
                alphasWhole(i,1) = stats.factor_analysis.cronbach(disEmo');
            end
            t_alpha = array2table([alphasWhole alphasCat],'VariableNames',[{'Global'}; obj.subgroupNames],'RowNames',obj.emoLabels);
            if obj.showPlotsAndTextFA==1
                disp(t_alpha);
            end
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
