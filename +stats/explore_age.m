classdef explore_age < load_data.load_data & stats.factor_analysis
%obj = stats.explore_age();obj.filterMethod='AllResponses';obj=do_load_data(obj);obj=reasonsAge(obj);
%obj = stats.explore_age();obj.filterMethod='AllResponses';obj=do_load_data(obj);ageDensity(obj),emoVarsAgeDensity(obj),emoAgeDensity(obj),icVarsAgeDensity(obj)
%obj = stats.explore_age();obj.filterMethod='AllResponses';obj=do_load_data(obj);ageDensity(obj),emoVarsAgeDensity(obj),emoAgeDensity(obj),icVarsAgeDensity(obj);indColAgeDensity(obj)
    properties
        FactorNames = {'TendernessLove','TriumphEnergy','PainSadness','PleasureHappiness'};
        countryType = 'Country_childhood';
        reasonLabels = {'for background purposes'
                        'to bring up memories'
                        'to have fun'
                        'to feel music´s emotions'
                        'to change your mood'
                        'to express yourself'
                        'to feel connected to other people'};
        reasonTypes = {'General Behavior','Selected Track'};
    end
    methods
        function obj = explore_age(obj)
            obj=do_load_data(obj);
        end
        function obj = indColAgeDensity(obj)
            figure
            icData = obj.dataTable(:,matches(obj.dataTable.Properties.VariableNames,obj.ICscalesNames));
            %icData{:,:} = rescale(icData{:,:}')';
            for k = 1:numel(obj.ICscalesNames)
            [f(:,k),xi(:,k)] = ksdensity(obj.dataTable.Age,'Weights',icData{:,k});
            end
            plot(xi,f,'LineWidth',2)
            %area(xi,f./sum(f,2))
            l = legend(strrep(obj.ICscalesNames,'_',' '),'Location','NorthOutside','AutoUpdate','off');
            hold on
            stem(obj.dataTable.Age,zeros(size(obj.dataTable.Age))+.001,'k')
            title('Kernel density for age, weighted by IC/HV factors (Triandis approach)')
            xlabel('Age')
            ylabel('Density')
        end
        function obj = reasonsAgeDensity(obj)
            reasonTypesKey = {'Music_','Track_'};
            obj.dataTable(any(isnan(obj.dataTable{:,contains(obj.dataTable.Properties.VariableNames,reasonTypesKey)}),2),:) = [];
            figure
            tiledlayout(1,2)
            for j = 1:numel(reasonTypesKey)
                nexttile
                reasonData = obj.dataTable(:,contains(obj.dataTable.Properties.VariableNames,reasonTypesKey{j}));
                %reasonData{:,:} = rescale(reasonData{:,:}')';
                clear f xi
                for k = 1:size(reasonData,2)
                    [f(:,k),xi(:,k)] = ksdensity(obj.dataTable.Age,'Weights',reasonData{:,k});
                end
                %xi = wrev(xi);
                %f = wrev(f);
                %imagesc(f)
                %plot(xi,f)
                %area(xi,f);
                plot(xi,f,'LineWidth',2)
                axis tight
                xlabel('Age')
                ylabel('Density')
                if j == 1
                    l = legend(strrep(obj.reasonLabels,'_',' '),'Location','NorthOutside','AutoUpdate','off');
                    l.Layout.Tile = 'north'
                    l.PlotChildren = wrev(l.PlotChildren);
                end
            hold on
            stem(obj.dataTable.Age,zeros(size(obj.dataTable.Age))+.001,'k')
            title(strrep(reasonTypesKey{j},'_',''))
            end
            sgtitle('Kernel density for age, weighted by reasons for listening')
            xlim([17 87])
        end
        function ageDensity(obj)
        %obj.dataTable = obj.dataTable(obj.dataTable.GenderCode == 2,:)% select a gender
            figure
            clear f xi
            [f,xi] = ksdensity(obj.dataTable.Age);
            %xi = wrev(xi);
            %f = wrev(f);
            p = plot(xi,f,'LineWidth',2);
            p.Color = brewermap(1,'Set2');
            %plot(xi,f./sum(f,2))
            %area(xi,f);
            %area(xi,f./sum(f,2))
            axis tight
            hold on
            stem(obj.dataTable.Age,zeros(size(obj.dataTable.Age))+.001,'k')
            xlim([17 87])
            title('Kernel density for age')
            xlabel('Age')
            ylabel('Density')
        end
        function obj = emoVarsAgeDensity(obj)
            addpath('~/Documents/MATLAB/distinguishable_colors')
            emoLabels = obj.dataTable.Properties.VariableNames(obj.dataTableInd);
            %obj.dataTable = obj.dataTable(obj.dataTable.GenderCode == 2,:)% select a gender
            figure
            emoData = obj.dataTable(:,obj.dataTableInd);
            c = distinguishable_colors(numel(emoLabels));
            clear f xi
            for k = 1:size(emoData,2)
                [f(:,k),xi(:,k)] = ksdensity(obj.dataTable.Age,'Weights',emoData{:,k});
            end
            %xi = wrev(xi);
            %f = wrev(f);
            p = plot(xi,f,'LineWidth',1);
            for k = 1:size(emoData,2)
                p(k).Color = c(k,:);
            end
            %plot(xi,f./sum(f,2))
            %area(xi,f);
            %area(xi,f./sum(f,2))
            axis tight
            l = legend(strrep(emoLabels,'_',' '),'Location','EastOutside','AutoUpdate','off');
            %l.PlotChildren = wrev(l.PlotChildren);
            hold on
            stem(obj.dataTable.Age,zeros(size(obj.dataTable.Age))+.001,'k')
            xlim([17 87])
            title('Kernel density for age, weighted by emotion terms')
            xlabel('Age')
            ylabel('Density')
        end
        function obj = icVarsAgeDensity(obj)
            icVarsInd = find(matches(obj.dataTable.Properties.VariableNames, obj.icVars));
            icLabels = obj.dataTable.Properties.VariableNames(icVarsInd);
            %obj.dataTable = obj.dataTable(obj.dataTable.GenderCode == 2,:)% select a gender
            figure
            icData = obj.dataTable(:,icVarsInd);
            %icData{:,:} = rescale(icData{:,:}')';
            c = distinguishable_colors(numel(icLabels));
            clear f xi
            for k = 1:size(icData,2)
                [f(:,k),xi(:,k)] = ksdensity(obj.dataTable.Age,'Weights',icData{:,k});
            end
            %xi = wrev(xi);
            %f = wrev(f);
            p = plot(xi,f,'LineWidth',2);
            for k = 1:size(icData,2)
                p(k).Color = c(k,:);
            end
            %plot(xi,f./sum(f,2))
            %area(xi,f);
            %area(xi,f./sum(f,2))
            axis tight
            l = legend(strrep(icLabels,'_',' '),'Location','EastOutside','AutoUpdate','off');
            %l.PlotChildren = wrev(l.PlotChildren);
            hold on
            stem(obj.dataTable.Age,zeros(size(obj.dataTable.Age))+.001,'k')
            xlim([17 87])
            title('Kernel density for age, weighted by IC/HV terms')
            xlabel('Age')
            ylabel('Density')
        end
        function obj = emoAgeviolin(obj)
            addpath('~/Documents/MATLAB/violin')
            emo = do_factor_analysis(obj);
            for k = 1:size(emo.FAScores,2)
                FAs{k} = emo.FAScores(:,k);
            end
            obj.dataTable = addvars(obj.dataTable,FAs{:},'After','Rebelliousness','NewVariableNames',obj.FactorNames);
            figure
            emoData = obj.dataTable(:,contains(obj.dataTable.Properties.VariableNames,obj.FactorNames));
            ages = unique(obj.dataTable.Age);
            for k = 1:numel(ages)
                emoDataAge{k} = emoData.PleasureHappiness(obj.dataTable.Age == ages(k));
            end
            violin(emoDataAge,'bw',.1)
            xticks(1:numel(ages))
            xticklabels(string(ages))
        end
        function obj = emoCollectGausProcReg(obj)
            ColVars = obj.icVars(numel(obj.icVars)/2+1:end);
            ColVarsInd = find(matches(obj.dataTable.Properties.VariableNames, ColVars));
            ColLabels = obj.dataTable.Properties.VariableNames(ColVarsInd);

            colData = obj.dataTable(:,ColVarsInd);
            T = [colData obj.dataTable(:,'Age')];

            gprMdl = fitrgp(T,'Age','Basis','linear', 'FitMethod','exact','PredictMethod','exact');
            ypred = resubPredict(gprMdl);


            figure();
            plot(T.Age,'r.');
            hold on
            plot(ypred,'b');
            xlabel('x');
            ylabel('y');
            legend({'data','predictions'},'Location','Best');
            hold off;
        end
        function obj = emoVarsBarplots(obj)
            byGender = 'Yes';
            addpath('~/Documents/MATLAB/distinguishable_colors')
            emoLabels = obj.dataTable.Properties.VariableNames(obj.dataTableInd);
            obj.dataTable.AgeCategory = renamecats(obj.dataTable.AgeCategory,{'Under 20','Over 60'},{'<20','60+'});
            fh = figure();
            fh.WindowState = 'maximized';

            emoData = obj.dataTable(:,obj.dataTableInd);
            S = size(emoData,2);
            su = stats.explore_age.numSubplots(S);
            tl = tiledlayout(su(1),su(2),'TileSpacing','loose','Padding','loose');
            for k = 1:size(emoData,2)
                ax{k} = nexttile;
                if strcmpi(byGender,'No')
                        G = groupsummary(obj.dataTable,"AgeCategory","Mean",emoLabels{k});
                        %Gsd = groupsummary(obj.dataTable,"AgeCategory","std",emoLabels{k});
                        meanData = G.(['mean_' emoLabels{k}]);
                        b = bar(G.(['mean_' emoLabels{k}]));
                        c = categories(obj.dataTable.AgeCategory);
                        for j = 1:numel(c)
                            data = obj.dataTable.(emoLabels{k})(matches(string(obj.dataTable.AgeCategory),c{j}));
                            ci(:,j) = bootci(10000,@mean,data);
                        end
                        hold on
                        e = errorbar(1:numel(meanData),meanData,ci(1,:),ci(2,:));
                        e.LineStyle = 'none';
                        e.LineWidth = 2;
                        str = join([string(groupsummary(obj.dataTable,"AgeCategory").AgeCategory) + " (N=" groupsummary(obj.dataTable,"AgeCategory").GroupCount + ")"],'');
                        xticklabels(str);
                        ylabel(emoLabels{k});
                else
                    dataMF = obj.dataTable;
                    dataMF(matches(dataMF.Gender,'Other'),:) = [];
                    G = groupsummary(dataMF,{'AgeCategory','Gender'},"Mean",emoLabels{k});
                    meanData = G.(['mean_' emoLabels{k}]);
                    dataBar = reshape(meanData,2,[])';
                    b = bar(dataBar);
                    [ngroups, nbars] = size(dataBar);
                    groupwidth = min(0.8, nbars/(nbars + 1.5));
                    b(1).FaceColor = [0.8500 0.3250 0.0980];
                    b(2).FaceColor = [0 0.4470 0.7410];
                    [GR,ID1,ID2] = findgroups(dataMF.AgeCategory,dataMF.Gender);
                    for j = 1:numel(unique(GR))
                        data = dataMF.(emoLabels{k})(GR == j);
                        ci(:,j) = bootci(10000,@mean,data);
                    end
                    hold on
                    lo = reshape(ci(1,:),2,[])';
                    up = reshape(ci(2,:),2,[])';
                    for i = 1:nbars
                        % Calculate center of each bar
                        x{i} = (1:ngroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nbars);
                        e = errorbar(x{i}, dataBar(:,i), lo(:,i),up(:,i), 'k', 'linestyle', 'none','LineWidth', 2);
                    end
                    str = join([string(G.AgeCategory) + " (N=" G.GroupCount + ")"],'');
                    xticks(reshape(cell2mat(x'),[],1))
                    xticklabels(str)
                end
                ylabel(emoLabels{k})
                grid on
                %xlabel('Age group')
                curMinCI = min(meanData-ci(1,:)');
                curMaxCI = max(meanData+ci(1,:)');
                if k > 1
                   minCI = min(minCI,curMinCI);
                   maxCI = max(maxCI,curMaxCI);
                else
                    [minCI, maxCI] = deal(curMinCI,curMaxCI);
                end
            end
            for k = 1:numel(ax)
                ax{k}.YLim = [minCI,maxCI];
                extra = diff(ax{k}.YLim) * 10/100;
                ax{k}.YLim = [ax{k}.YLim(1) - extra, ax{k}.YLim(2) + extra];
            end

            if strcmpi(byGender,'Yes')
                lgd = legend;
                lgd.String = unique(dataMF.Gender);
                lgd.Layout.Tile = 'north';
                lgd.Orientation = 'horizontal';
            end
        end
        function obj = emoVarsBoxplots(obj)
            byGender = 'no';
            ageCats = 'Yes';
            addpath('~/Documents/MATLAB/distinguishable_colors')
            emoLabels = obj.dataTable.Properties.VariableNames(obj.dataTableInd);
            figure
            emoData = obj.dataTable(:,obj.dataTableInd);
            [m M] = bounds(emoData{:,:}(:));
            S = size(emoData,2);
            su = stats.explore_age.numSubplots(S);
            tiledlayout(su(1),su(2),'TileSpacing','loose','Padding','loose');
            for k = 1:size(emoData,2)
                nexttile
                if strcmpi(byGender,'No')
                    if strcmpi(ageCats,'Yes')
                        boxchart(obj.dataTable.AgeCategory,emoData{:,k},'Notch','on');
                    else
                        boxchart(obj.dataTable.Age,emoData{:,k},'Notch','on');
                    end
                else
                    if strcmpi(ageCats,'Yes')
                        boxchart(obj.dataTable.AgeCategory,emoData{:,k},'Notch','on','GroupByColor',obj.dataTable.Gender);
                    else
                        boxchart(obj.dataTable.Age,emoData{:,k},'Notch','on','GroupByColor',obj.dataTable.Gender);
                    end
                end
                ylabel(emoLabels{k})
                grid on
                ylim([m M]);
                if strcmpi(ageCats,'Yes')
                    %xlabel('Age group')
                    str = join([string(groupsummary(obj.dataTable,"AgeCategory").AgeCategory) + " (N=" groupsummary(obj.dataTable,"AgeCategory").GroupCount + ")"],'');
                else
                    str = join([string(groupsummary(obj.dataTable,"Age").Age) + " (N=" groupsummary(obj.dataTable,"Age").GroupCount + ")"],'');

                    xlabel('Age (years)')
                    [minAge maxAge] = bounds(groupsummary(obj.dataTable,"Age").Age);
                    xticks([minAge:maxAge])
                end
                xticklabels(str);
            end
            if strcmpi(byGender,'Yes')
                lgd = legend;
                lgd.Layout.Tile = 'north';
                lgd.Orientation = 'horizontal';
            end
        end
        function obj = emoVarsKerReg(obj)
            addpath('~/Documents/MATLAB/distinguishable_colors')
            addpath('~/Documents/MATLAB/ksr_vw')
            nn = 300;
            emoLabels = obj.dataTable.Properties.VariableNames(obj.dataTableInd);
            %obj.dataTable = obj.dataTable(obj.dataTable.GenderCode == 2,:)% select a gender
            figure
            emoData = obj.dataTable(:,obj.dataTableInd);
            c = distinguishable_colors(numel(emoLabels));
            clear f xi
            for k = 1:size(emoData,2)
                emoData{:,k} = (emoData{:,k}-mean(emoData{:,k}));
                r(k) = ksr_vw(obj.dataTable.Age,emoData{:,k},300);
                %ksr_vw

            end
            %xi = wrev(xi);
            %f = wrev(f);
            x = cell2mat(arrayfun(@(x) x.x(:),r,'un',0));
            f = cell2mat(arrayfun(@(x) x.f(:),r,'un',0));
            p = plot(x,f,'LineWidth',1);
            for k = 1:size(emoData,2)
                p(k).Color = c(k,:);
            end
            %plot(xi,f./sum(f,2))
            %area(xi,f);
            %area(xi,f./sum(f,2))
            axis tight
            l = legend(strrep(emoLabels,'_',' '),'Location','EastOutside','AutoUpdate','off');
            %l.PlotChildren = wrev(l.PlotChildren);
            hold on
            stem(obj.dataTable.Age,zeros(size(obj.dataTable.Age))+.001,'k')
            xlim([17 87])
            title('Kernel regression')
            xlabel('Age')
            ylabel('Feature value')
        end

        function obj = emoCollectGausKerReg(obj)
        % collectivism variables
            icVars = obj.icVars(numel(obj.icVars)/2+1:end);
            icVarsInd = find(matches(obj.dataTable.Properties.VariableNames, icVars));
            icLabels = obj.dataTable.Properties.VariableNames(icVarsInd);

            icData = obj.dataTable{:,icVarsInd};
            X = icData;
            Y = obj.dataTable.Age;
            R = rmmissing([X Y]);
            X = R(:,1:end-1);
            Y = R(:,end);

            N = length(Y);
            cvp = cvpartition(N,'Holdout',0.1);
            idxTrn = training(cvp); % Training set indices
            idxTest = test(cvp);    % Test set indices
            Xtrain = X(idxTrn,:);
            Ytrain = Y(idxTrn);
            [Ztrain,tr_mu,tr_sigma] = zscore(Xtrain); % Standardize the training data
            tr_sigma(tr_sigma==0) = 1;
            Mdl = fitrkernel(Ztrain,Ytrain)
            Xtest = X(idxTest,:);
            Ztest = (Xtest-tr_mu)./tr_sigma; % Standardize the test data
            Ytest = Y(idxTest);
            YFit = predict(Mdl,Ztest);
            T = table(Ytest,YFit,'VariableNames', {'ObservedValue','PredictedValue'});
            L = loss(Mdl,Ztest,Ytest);
        end
        function obj = emoAgeDensity(obj)
            addpath('~/Documents/MATLAB/brewermap')
        %obj.dataTable = obj.dataTable(obj.dataTable.GenderCode == 2,:)% select a gender
            emo = do_factor_analysis(obj);
            for k = 1:size(emo.FAScores,2)
                FAs{k} = emo.FAScores(:,k);
            end
            obj.dataTable = addvars(obj.dataTable,FAs{:},'After','Rebelliousness','NewVariableNames',obj.FactorNames);
            figure
            emoData = obj.dataTable(:,contains(obj.dataTable.Properties.VariableNames,obj.FactorNames));
            %emoData{:,:} = rescale(emoData{:,:}',-1,1)'; % do not rescale factors!
            c = brewermap(numel(obj.FactorNames),'Set2');
            clear f xi
            for k = 1:size(emoData,2)
                [f(:,k),xi(:,k),bw] = ksdensity(obj.dataTable.Age,'Weights',emoData{:,k});
            end
            %xi = wrev(xi);
            %f = wrev(f);
            p = plot(xi,f,'LineWidth',2);
            for k = 1:size(emoData,2)
                p(k).Color = c(k,:);
            end
            %plot(xi,f./sum(f,2))
            %area(xi,f);
            %area(xi,f./sum(f,2))
            axis tight
            l = legend(strrep(obj.FactorNames,'_',' '),'Location','NorthOutside','AutoUpdate','off');
            %l.PlotChildren = wrev(l.PlotChildren);
            hold on
            stem(obj.dataTable.Age,zeros(size(obj.dataTable.Age))+.001,'k')
            xlim([17 87])
            title('Kernel density for age, weighted by emotion factors')
            xlabel('Age')
            ylabel('Density')
        end
        function obj = emoAge(obj)
        %obj.dataTable = obj.dataTable(obj.dataTable.GenderCode == 2,:)% select a gender
            emo = do_factor_analysis(obj);
            for k = 1:size(emo.FAScores,2)
                FAs{k} = emo.FAScores(:,k);
            end
            obj.dataTable = addvars(obj.dataTable,FAs{:},'After','Rebelliousness','NewVariableNames',obj.FactorNames);
            emoData = obj.dataTable(:,contains(obj.dataTable.Properties.VariableNames,obj.FactorNames));
            emoAgeData = addvars(emoData,obj.dataTable.Age,'NewVariableNames','Age');
            g = grpstats(emoAgeData,'Age',{'median','iqr'});
            x = g.Age;
            f = figure;
            for k = 1:numel(obj.FactorNames)
                dataM = g{:,matches(g.Properties.VariableNames,{['median_' obj.FactorNames{k}]})}';
                dataSD = g{:,matches(g.Properties.VariableNames,{['iqr_' obj.FactorNames{k}]})}';
                c = brewermap(numel(obj.FactorNames),'Set2');
                set(f,'defaultLegendAutoUpdate','off');
                f = fill([x' fliplr(x')],[dataM-dataSD, fliplr(dataM)+fliplr(dataSD)],c(k,:),'LineStyle','none','FaceAlpha',.3);
                f.Annotation.LegendInformation.IconDisplayStyle = 'off'; % make the legend for step plot off
            hold on
            h = plot(x,dataM,'LineWidth',2,'Color',c(k,:));
            l = legend(strrep(obj.FactorNames,'_',' '),'Location','NorthOutside','AutoUpdate','off');
            xlim([17 87])
            end
        end
        function obj = emoAgePositiveRate(obj)
        %obj.dataTable = obj.dataTable(obj.dataTable.GenderCode == 2,:)% select a gender
            emo = do_factor_analysis(obj);
            for k = 1:size(emo.FAScores,2)
                FAs{k} = emo.FAScores(:,k);
            end
            obj.dataTable = addvars(obj.dataTable,FAs{:},'After','Rebelliousness','NewVariableNames',obj.FactorNames);
            emoData = obj.dataTable(:,contains(obj.dataTable.Properties.VariableNames,obj.FactorNames));
            emoAgeData = addvars(emoData,obj.dataTable.Age,'NewVariableNames','Age');
            g = grpstats(emoAgeData,'Age',@(x) sum(sign(x) > 0)/numel(x));
            x = g.Age;
            f = figure;
            for k = 1:numel(obj.FactorNames)
                dataM = g{:,matches(g.Properties.VariableNames,{['Fun1_' obj.FactorNames{k}]})}';
                c = brewermap(numel(obj.FactorNames),'Set2');
                set(f,'defaultLegendAutoUpdate','off');
                h = plot(x,dataM,'LineWidth',2,'Color',c(k,:));
                hold on
                l = legend(strrep(obj.FactorNames,'_',' '),'Location','NorthOutside','AutoUpdate','off');
                xlim([17 87])
            end
        end
    end
    methods (Static)
        function [p,n]=numSubplots(n)
        % function [p,n]=numSubplots(n)
        %
        % Purpose
        % Calculate how many rows and columns of sub-plots are needed to
        % neatly display n subplots.
        %
        % Inputs
        % n - the desired number of subplots.
        %
        % Outputs
        % p - a vector length 2 defining the number of rows and number of
        %     columns required to show n plots.
        % [ n - the current number of subplots. This output is used only by
        %       this function for a recursive call.]
        %
        %
        %
        % Example: neatly lay out 13 sub-plots
        % >> p=numSubplots(13)
        % p =
        %     3   5
        % for i=1:13; subplot(p(1),p(2),i), pcolor(rand(10)), end
        %
        %
        % Rob Campbell - January 2010


            while isprime(n) & n>4,
                n=n+1;
            end
            p=factor(n);
            if length(p)==1
                p=[1,p];
                return
            end
            while length(p)>2
                if length(p)>=4
                    p(1)=p(1)*p(end-1);
                    p(2)=p(2)*p(end);
                    p(end-1:end)=[];
                else
                    p(1)=p(1)*p(2);
                    p(2)=[];
                end
                p=sort(p);
            end
            %Reformat if the column/row ratio is too large: we want a roughly
            %square design
            while p(2)/p(1)>2.5
                N=n+1;
                [p,n]=stats.explore_age.numSubplots(N); %Recursive!
            end
        end
    end
end
