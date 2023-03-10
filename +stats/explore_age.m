classdef explore_age < load_data.load_data & stats.factor_analysis
    %obj = stats.explore_age();obj.filterMethod='AllResponses';obj=do_load_data(obj);obj=reasonsAge(obj);
    %obj = stats.explore_age();obj.filterMethod='AllResponses';obj=do_load_data(obj);ageDensity(obj),emoVarsAgeDensity(obj),emoAgeDensity(obj),icVarsAgeDensity(obj)
    %obj = stats.explore_age();obj.filterMethod='AllResponses';obj=do_load_data(obj);ageDensity(obj),emoVarsAgeDensity(obj),emoAgeDensity(obj),icVarsAgeDensity(obj);indColAgeDensity(obj)
    %obj = stats.explore_age();obj.filterMethod='AllResponses';obj=do_load_data(obj);emoFactorsDensity(obj)
    %obj = stats.explore_age();obj.filterMethod='AllResponses';obj=do_load_data(obj);emoVarsRegressionScatter(obj)
    %obj = stats.explore_age();obj.filterMethod='AllResponses';obj=do_load_data(obj);factorSolutionAgeGenderReplications(obj)
    %obj = stats.explore_age();obj.filterMethod='AllResponses';obj=do_load_data(obj);emoVarsRegressionScatter(obj)
    %obj = stats.explore_age();obj.filterMethod='UnbalancedSubgroups';obj=do_load_data(obj);ttestCountryGender(obj)
    %obj = stats.explore_age();obj.filterMethod='AllResponses';obj=do_load_data(obj);emoFactorsAgeNonLinear(obj)
    properties
        FactorNames
        countryType = 'Country_childhood';
        reasonLabels = {'for background purposes'
            'to bring up memories'
            'to have fun'
            'to feel music´s emotions'
            'to change your mood'
            'to express yourself'
            'to feel connected to other people'};
        reasonTypes = {'General Behavior','Selected Track'};
        scatterPlotData
        byGender = 'Yes';
        bootCImethod = 'standard';% 'standard' or 'quantile'
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
            obj.FactorNames = emo.factorNames;
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
            tl.TileSpacing = 'Compact';
            tl.Padding = 'None';
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
                    [~,T] = anovan(obj.dataTable.(emoLabels{k}),findgroups(obj.dataTable.AgeCategory),'Display','off');
                    title("F("+string(T(2,3))+","+string(T(3,3))+") = " + num2str(str2num(string(T(2,end-1))),'%.2f')+", p = " + string(strrep(num2str(cell2mat(T(2,end)),'%.3f'),'0.','.')))
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
                    [~,T] = anovan(obj.dataTable.(emoLabels{k}),{findgroups(obj.dataTable.AgeCategory),findgroups(obj.dataTable.Gender)},'Display','off','model','interaction');
                    ageAN = "F("+string(T(2,3))+","+string(T(5,3))+") = " + num2str(str2num(string(T(2,end-1))),'%.2f')+", p = " + string(strrep(num2str(cell2mat(T(2,end)),'%.3f'),'0.','.'));
                    genderAN = "F("+string(T(3,3))+","+string(T(5,3))+") = " + num2str(str2num(string(T(3,end-1))),'%.2f')+", p = " + string(strrep(num2str(cell2mat(T(3,end)),'%.3f'),'0.','.'));
                    ageGenderAN = "F("+string(T(4,3))+","+string(T(5,3))+") = " + num2str(str2num(string(T(4,end-1))),'%.2f')+", p = " + string(strrep(num2str(cell2mat(T(4,end)),'%.3f'),'0.','.'));
                    title({join(['Age ' ageAN ],'');join(['Gender ' genderAN ],'');join(['Interaction ' ageGenderAN ],'')})
                    %title(join(['Age ' ageAN '; Gender ' genderAN],''))
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
        function obj = emoFactorsBoxplotsGender(obj)
            addpath('~/Documents/MATLAB/distinguishable_colors')
            emo = do_factor_analysis(obj);
            obj.FactorNames = emo.factorNames;
            emoLabels = obj.FactorNames;
            for k = 1:size(emo.FAScores,2)
                FAs{k} = emo.FAScores(:,k);
            end
            %close all
            obj.dataTable = addvars(obj.dataTable,FAs{:},'After','Rebelliousness','NewVariableNames',obj.FactorNames);
            emoData = obj.dataTable(:,contains(obj.dataTable.Properties.VariableNames,obj.FactorNames));
            
            S = size(emoData,2);
            fh = figure();
            su = stats.explore_age.numSubplots(S);
            tl = tiledlayout(su(1),su(2),'TileSpacing','loose','Padding','loose');
            tl.TileSpacing = 'None';
            tl.Padding = 'None';
            obj.dataTable(matches(obj.dataTable.Gender,'Other'),:) = [];
            for k = 1:size(emoData,2)
                disp(emoLabels{k})
                ax{k} = nexttile;
                obj.dataTable.(emoLabels{k});
                b = boxchart(obj.dataTable.(emoLabels{k}),'groupbyColor',obj.dataTable.Gender,'Notch','on');
                b(1).SeriesIndex = 2;
                b(2).SeriesIndex = 1;
                xlabel(emoLabels{k});
                if k == 1
                    ylabel('Factor score')
                    lgd = legend;
                    lgd.String = unique(obj.dataTable.Gender);
                    lgd.Layout.Tile = 'north';
                    lgd.Orientation = 'horizontal';
                    ax{k}.TickDir = 'out';
                    set(lgd,'AutoUpdate','off')
                else
                    yticks('')
                end
                xticks('')
                [~, ttestp, ~, tteststats] = ttest2(obj.dataTable.(emoLabels{k})(string(obj.dataTable.Gender) == 'Female'),obj.dataTable.(emoLabels{k})(string(obj.dataTable.Gender) == 'Male'));
                disp(['t(' num2str(tteststats.df) ') = ' num2str(tteststats.tstat,'%.2f') ', p = ' strrep(num2str(ttestp,'%.3f'),'0.','.')]);
                if ttestp < .05
                    %sigstar([1,2],ttestp) -> doesn't do the trick
                end
                keyboard
                hold on
                G = groupsummary(obj.dataTable.(emoLabels{k}),findgroups(obj.dataTable.Gender),'mean');
                plot([0.75; 1.25],G,'dk')
                axis square
                
            end
            linkaxes([ax{:}],'y')
            %savefigures('figures/paper_emotions_listening_habits/Gender_EmoFactors_barplots')
        end
        function obj = emoFactorsBoxplotsGender_old(obj)
            close all
            addpath('~/Documents/MATLAB/distinguishable_colors')
            emo = do_factor_analysis(obj);
            obj.FactorNames = emo.factorNames;
            emoLabels = obj.FactorNames;
            for k = 1:size(emo.FAScores,2)
                FAs{k} = emo.FAScores(:,k);
            end
            obj.dataTable = addvars(obj.dataTable,FAs{:},'After','Rebelliousness','NewVariableNames',obj.FactorNames);
            emoData = obj.dataTable(:,contains(obj.dataTable.Properties.VariableNames,obj.FactorNames));
            
            S = size(emoData,2);
            fh = figure();
            su = stats.explore_age.numSubplots(S);
            tl = tiledlayout(su(1),su(2),'TileSpacing','loose','Padding','loose');
            tl.TileSpacing = 'Compact';
            tl.Padding = 'None';
            obj.dataTable(matches(obj.dataTable.Gender,'Other'),:) = [];
            for k = 1:size(emoData,2)
                ax{k} = nexttile;
                obj.dataTable.(emoLabels{k});
                b = boxchart(obj.dataTable.(emoLabels{k}),'groupbyColor',obj.dataTable.Gender,'Notch','on');
                b(1).SeriesIndex = 2;
                b(2).SeriesIndex = 1;
                ylabel(emoLabels{k});
                xticks('')
                grid on;
                [~,T] = anovan(obj.dataTable.(emoLabels{k}),findgroups(obj.dataTable.Gender),'Display','off');
                title("F("+string(T(2,3))+","+string(T(3,3))+") = " + num2str(str2num(string(T(2,end-1))),'%.2f')+", p = " + string(strrep(num2str(cell2mat(T(2,end)),'%.3f'),'0.','.')));
                hold on
                G = groupsummary(obj.dataTable.(emoLabels{k}),findgroups(obj.dataTable.Gender),'mean');
                scatter([0.75 1.25],G,'xk')
                axis square
            end
            linkaxes([ax{:}],'y')
            savefigures('figures/emoFactorsBoxplotsGender/')
        end
        function obj = emoFactorsBarplots(obj,options)
            arguments
                obj
                options.minimalXTickLabel = 'yes' % if minimal, then only age groups are shown. Otherwise, we also add sample sizes for each gender
                options.byGender = 'yes'
            end
            byGender = options.byGender;
            addpath('~/Documents/MATLAB/distinguishable_colors')
            emo = do_factor_analysis(obj);
            obj.FactorNames = emo.factorNames;
            emoLabels = obj.FactorNames;
            for k = 1:size(emo.FAScores,2)
                FAs{k} = emo.FAScores(:,k);
            end
            obj.dataTable.AgeCategory = renamecats(obj.dataTable.AgeCategory,{'Under 20','Over 60'},{'<20','60+'});
            obj.dataTable = addvars(obj.dataTable,FAs{:},'After','Rebelliousness','NewVariableNames',obj.FactorNames);
            emoData = obj.dataTable(:,contains(obj.dataTable.Properties.VariableNames,obj.FactorNames));
            %close all
            g = get(groot,'defaultfigureposition');
            g(3) = g(3)*2;
            f = figure('Position',g);
            %fh.WindowState = 'maximized';
            S = size(emoData,2);
            su = stats.explore_age.numSubplots(S);
            tl = tiledlayout(su(1),su(2),'TileSpacing','loose','Padding','loose');
            for k = 1:size(emoData,2)
                disp(emoLabels{k})
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
                    [~,T] = anovan(obj.dataTable.(emoLabels{k}),findgroups(obj.dataTable.AgeCategory),'Display','off');
                    title("F("+string(T(2,3))+","+string(T(3,3))+") = " + num2str(str2num(string(T(2,end-1))),'%.2f')+", p = " + string(strrep(num2str(cell2mat(T(2,end)),'%.3f'),'0.','.')))
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
                    [~,T] = anovan(dataMF.(emoLabels{k}),{findgroups(dataMF.AgeCategory),findgroups(dataMF.Gender)},'Display','off','model','interaction');
                    ageAN = "F("+string(T(2,3))+","+string(T(5,3))+") = " + num2str(str2num(string(T(2,end-1))),'%.2f')+", p = " + string(strrep(num2str(cell2mat(T(2,end)),'%.3f'),'0.','.'));
                    genderAN = "F("+string(T(3,3))+","+string(T(5,3))+") = " + num2str(str2num(string(T(3,end-1))),'%.2f')+", p = " + string(strrep(num2str(cell2mat(T(3,end)),'%.3f'),'0.','.'));
                    ageGenderAN = "F("+string(T(4,3))+","+string(T(5,3))+") = " + num2str(str2num(string(T(4,end-1))),'%.2f')+", p = " + string(strrep(num2str(cell2mat(T(4,end)),'%.3f'),'0.','.'));
                    disp({join(['Age ' ageAN ],'');join(['Gender ' genderAN ],'');join(['Interaction ' ageGenderAN ],'')})
                    %title(join(['Age ' ageAN '; Gender ' genderAN],''))
                end
                title(emoLabels{k})
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
                %ax{k}.YLim = [minCI,maxCI];
                %extra = diff(ax{k}.YLim) * 10/100;
                %ax{k}.YLim = [ax{k}.YLim(1) - extra, ax{k}.YLim(2) + extra];
            end
            
            if strcmpi(byGender,'Yes')
                lgd = legend;
                lgd.String = unique(dataMF.Gender);
                lgd.Layout.Tile = 'north';
                lgd.Orientation = 'horizontal';
            end
            linkaxes([ax{:}],'y');
            
            for k = 1:numel(ax)
                ax{k}.TickDir='out';
                ax{k}.Box = 'off';
                ax{k}.FontSize = 16;
                if strcmpi(options.minimalXTickLabel, 'yes')
                    ax{k}.XTick = mean(reshape(ax{k}.XTick,2,[]))
                    ax{k}.XTickLabel=string(groupsummary(obj.dataTable,"AgeCategory").AgeCategory);
                end
                ax{k}.XLabel.String = 'Age group';
                if k == 1
                    ax{k}.YLabel.String='Factor score';
                else
                    ax{k}.YTick = [];
                end
            end
            tl.TileSpacing = 'Tight';
            tl.Padding = 'Compact';
            %savefigures('figures/paper_emotions_listening_habits/AgeGroup_EmoFactors_barplots')
        end
        function obj = emoVarsDensity(obj)
            byGender = obj.byGender;
            bootCImethod = obj.bootCImethod;
            sigma = 5;
            iter = 10000;
            warning('check number of iterations')
            addpath('~/Documents/MATLAB/distinguishable_colors')
            emoLabels = obj.dataTable.Properties.VariableNames(obj.dataTableInd);
            fh = figure();
            fh.WindowState = 'maximized';
            emoData = obj.dataTable(:,obj.dataTableInd);
            S = size(emoData,2);
            su = stats.explore_age.numSubplots(S);
            tl = tiledlayout(su(1),su(2),'TileSpacing','loose','Padding','loose');
            tl.TileSpacing = 'Compact';
            tl.Padding = 'None';
            for k = 1:size(emoData,2)
                ax{k} = nexttile;
                if strcmpi(byGender,'No')
                    ageRange = min(obj.dataTable.Age):max(obj.dataTable.Age);
                    [B,BG] = groupsummary(emoData{:,k},obj.dataTable.Age,@mean);
                    m = nan(1,max(BG));
                    m(BG) = B;
                    % Kernel regression with constant bandwidth
                    z1=sum(emoData{:,k}.*normpdf(ageRange-obj.dataTable.Age,0,sigma));
                    z2=sum(normpdf(ageRange-obj.dataTable.Age,0,sigma));
                    z=z1./z2;
                    if strcmpi(bootCImethod,'standard')
                        CI = stats.explore_age.confidenceLimits(obj.dataTable.Age,emoData{:,k},95,iter,sigma,bootCImethod);
                        l = z-CI;
                        u = z+CI;
                        l = l(:);
                        u = u(:);
                    else
                        [~,l,u] = stats.explore_age.confidenceLimits(obj.dataTable.Age,emoData{:,k},95,iter,sigma,bootCImethod);
                    end
                    
                    
                    c = brewermap(1,'Set2');
                    set(fh,'defaultLegendAutoUpdate','off');
                    for ii = 1:size(l,2)
                        fill([ageRange fliplr(ageRange)],[l(:,ii)' fliplr(u(:,ii)')],c(ii,:),'LineStyle','none','FaceAlpha',.3);
                        hold on
                    end
                    plot(ageRange,z,'-k','LineWidth',2)
                    reg = regress(z',[ones(size(ageRange,2),1) ageRange']);
                    beta(k) = reg(2);
                    meanKerReg(k)= mean(z);
                    percXlim = prctile(obj.dataTable.Age,[5 95]);
                    smallAgeRange = ageRange(ageRange >= percXlim(1) & ageRange <= percXlim(2));
                    smallZ = z(ageRange >= percXlim(1) & ageRange <= percXlim(2));
                    smallL = l(ageRange >= percXlim(1) & ageRange <= percXlim(2));
                    smallU = u(ageRange >= percXlim(1) & ageRange <= percXlim(2));
                    regsmallAgeRange = regress(smallZ',[ones(size(smallAgeRange,2),1) smallAgeRange']);
                    betasmallAgeRange(k) = regsmallAgeRange(2);
                    
                    reg = regress(z',[ones(size(ageRange,2),1) ageRange']);
                    
                    axis tight
                    xlabel('Age')
                    [~,T] = anovan(obj.dataTable.(emoLabels{k}),findgroups(obj.dataTable.AgeCategory),'Display','off');
                    title("F("+string(T(2,3))+","+string(T(3,3))+") = " + num2str(str2num(string(T(2,end-1))),'%.2f')+", p = " + string(strrep(num2str(cell2mat(T(2,end)),'%.3f'),'0.','.')))
                else
                    dataMF = obj.dataTable;
                    dataMF(matches(dataMF.Gender,'Other'),:) = [];
                    genderLabels = unique(dataMF.Gender);
                    c = brewermap(numel(genderLabels)+1,'Set2');
                    for gg = 1:numel(genderLabels)
                        data = dataMF(matches(dataMF.Gender, genderLabels{gg}),:);
                        emoDataCurGend = data(:,obj.dataTableInd);
                        ageRange = min(data.Age):max(data.Age);
                        [B,BG] = groupsummary(emoDataCurGend{:,k},data.Age,@mean);
                        m = nan(1,max(BG));
                        m(BG) = B;
                        % Kernel regression with constant bandwidth
                        z1=sum(emoDataCurGend{:,k}.*normpdf(ageRange-data.Age,0,sigma));
                        z2=sum(normpdf(ageRange-data.Age,0,sigma));
                        z=z1./z2;
                        if strcmpi(bootCImethod,'standard')
                            CI = stats.explore_age.confidenceLimits(data.Age,emoDataCurGend{:,k},95,iter,sigma,bootCImethod);
                            l = z-CI;
                            u = z+CI;
                            l = l(:);
                            u = u(:);
                        else
                            [~,l,u] = stats.explore_age.confidenceLimits(data.Age,emoDataCurGend{:,k},95,iter,sigma,bootCImethod);
                        end
                        set(fh,'defaultLegendAutoUpdate','off');
                        for ii = 1:size(l,2)
                            fill([ageRange fliplr(ageRange)],[l(:,ii)' fliplr(u(:,ii)')],c(gg+1,:),'LineStyle','none','FaceAlpha',.3);
                            hold on
                        end
                        p = plot(ageRange,z,'-k','LineWidth',2);
                        p.Annotation.LegendInformation.IconDisplayStyle = 'off';
                        
                        reg = regress(z',[ones(size(ageRange,2),1) ageRange']);
                        percXlim = prctile(data.Age,[5 95]);
                        smallAgeRange = ageRange(ageRange >= percXlim(1) & ageRange <= percXlim(2));
                        smallZ = z(ageRange >= percXlim(1) & ageRange <= percXlim(2));
                        smallL{gg} = l(ageRange >= percXlim(1) & ageRange <= percXlim(2));
                        smallU{gg} = u(ageRange >= percXlim(1) & ageRange <= percXlim(2));
                        regsmallAgeRange = regress(smallZ',[ones(size(smallAgeRange,2),1) smallAgeRange']);
                        betasmallAgeRange(k) = regsmallAgeRange(2);
                        reg = regress(z',[ones(size(ageRange,2),1) ageRange']);
                        axis tight
                        if gg == 1
                            xlabel('Age')
                            [~,T] = anovan(obj.dataTable.(emoLabels{k}),findgroups(obj.dataTable.AgeCategory),'Display','off');
                            [~,T] = anovan(obj.dataTable.(emoLabels{k}),{findgroups(obj.dataTable.AgeCategory),findgroups(obj.dataTable.Gender)},'Display','off','model','interaction');
                            ageAN = "F("+string(T(2,3))+","+string(T(5,3))+") = " + num2str(str2num(string(T(2,end-1))),'%.2f')+", p = " + string(strrep(num2str(cell2mat(T(2,end)),'%.3f'),'0.','.'));
                            genderAN = "F("+string(T(3,3))+","+string(T(5,3))+") = " + num2str(str2num(string(T(3,end-1))),'%.2f')+", p = " + string(strrep(num2str(cell2mat(T(3,end)),'%.3f'),'0.','.'));
                            ageGenderAN = "F("+string(T(4,3))+","+string(T(5,3))+") = " + num2str(str2num(string(T(4,end-1))),'%.2f')+", p = " + string(strrep(num2str(cell2mat(T(4,end)),'%.3f'),'0.','.'));
                            title({join(['Age ' ageAN ],'');join(['Gender ' genderAN ],'');join(['Interaction ' ageGenderAN ],'')})
                            %title(join(['Age ' ageAN '; Gender ' genderAN],''))
                        end
                    end
                end
                ylabel(emoLabels{k})
                grid on
                %xlabel('Age group')
                if strcmpi(byGender,'Yes')
                    curMinCI = min(cellfun(@min,smallL));
                    curMaxCI = max(cellfun(@max,smallU));
                else
                    curMinCI = min(smallL);
                    curMaxCI = max(smallU);
                end
                if k > 1
                    minCI = min(minCI,curMinCI);
                    maxCI = max(maxCI,curMaxCI);
                else
                    [minCI, maxCI] = deal(curMinCI,curMaxCI);
                end
            end
            for k = 1:numel(ax)
                ax{k}.YLim = [minCI,maxCI];
                ax{k}.XLim = percXlim;
                %extra = diff(ax{k}.YLim) * 1/100;
                %ax{k}.YLim = [ax{k}.YLim(1) - extra, ax{k}.YLim(2) + extra];
            end
            
            if strcmpi(byGender,'Yes')
                lgd = legend;
                lgd.String = unique(dataMF.Gender);
                lgd.Layout.Tile = 'north';
                lgd.Orientation = 'horizontal';
            else
                obj.scatterPlotData = [beta;meanKerReg];
            end
            [S I] = sort(betasmallAgeRange,'descend');
            for k = 1:numel(ax)
                ax{I(k)}.Layout.Tile = k;
            end
        end
        function obj = factorSolutionAgeGenderReplications(obj)
            addpath('~/Documents/MATLAB/brewermap')
            addpath('~/Documents/MATLAB/distinguishable_colors')
            dataMF = obj.dataTable;
            dataMF(matches(dataMF.Gender,'Other'),:) = [];
            genderCats = unique(dataMF.Gender);
            dataMF.AgeCategory = string(dataMF.AgeCategory);
            dataMF.AgeCategory = strrep(dataMF.AgeCategory,' ','-');
            dataMF.AgeCategory = strrep(dataMF.AgeCategory,'-','_');
            dataMF.AgeCategory = append('age_',dataMF.AgeCategory);
            ageCats = unique(dataMF.AgeCategory);
            for k = 1:numel(genderCats)
                data.(genderCats{k}).allData = dataMF(matches(dataMF.Gender,genderCats{k}),:);
                for j = 1:numel(ageCats)
                    data.(genderCats{k}).(ageCats{j}) = data.(genderCats{k}).allData(matches(data.(genderCats{k}).allData.AgeCategory,ageCats{j}),:);
                    a = obj;
                    a.dataTable = data.(genderCats{k}).(ageCats{j});
                    
                    f = do_factor_analysis(a);
                    disp('')
                    disp([genderCats{k} ' ' ageCats{j}])
                    disp(['N=' num2str(size(data.(genderCats{k}).(ageCats{j}),1))])
                    disp(join(string(['Factor Names: ' f.factorNames])))
                    disp('Sum of squared loadings:')
                    disp(f.sumSquaredLoadings)
                    disp('Maximum loading values:')
                    disp(f.maxLoadingValues)
                    dataFA.(genderCats{k}).(ageCats{j}) = f;
                end
            end
            
            
            emo = do_factor_analysis(obj);
            obj.FactorNames = emo.factorNames;
            emoLabels = obj.FactorNames;
            for k = 1:size(emo.FAScores,2)
                FAs{k} = emo.FAScores(:,k);
            end
            
        end
        function obj = MeanEmotionRatingsAgeGender(obj)
            addpath('~/Documents/MATLAB/brewermap')
            addpath('~/Documents/MATLAB/distinguishable_colors')
            dataMF = obj.dataTable;
            dataMF(matches(dataMF.Gender,'Other'),:) = [];
            genderCats = unique(dataMF.Gender);
            dataMF.AgeCategory = string(dataMF.AgeCategory);
            dataMF.AgeCategory = strrep(dataMF.AgeCategory,' ','-');
            dataMF.AgeCategory = strrep(dataMF.AgeCategory,'-','_');
            dataMF.AgeCategory = append('age_',dataMF.AgeCategory);
            dataMF.AgeCategory = categorical(dataMF.AgeCategory);
            dataMF.AgeCategory = reordercats(dataMF.AgeCategory,circshift(categories(dataMF.AgeCategory),1));
            ageCats = unique(dataMF.AgeCategory);
            figure
            t = tiledlayout('flow');
            t.TileIndexing = 'columnmajor';
            for k = 1:numel(genderCats)
                data.(genderCats{k}).allData = dataMF(matches(dataMF.Gender,genderCats{k}),:);
                for j = 1:numel(ageCats)
                    nexttile
                    data.(genderCats{k}).(string(ageCats(j))) = data.(genderCats{k}).allData(data.(genderCats{k}).allData.AgeCategory == ageCats(j),:);
                    a = obj;
                    emoTerms = a.dataTable.Properties.VariableNames(a.dataTableInd);
                    a.dataTable = data.(genderCats{k}).(string(ageCats(j)));
                    [S I] = sort(mean(a.dataTable{:,a.dataTableInd}),'Descend');
                    bar(S)
                    xticks(1:numel(S))
                    xticklabels(emoTerms(I))
                    grid on
                    mytitle = [genderCats{k} ' ' string(ageCats(j)) ' (N=' num2str(size(data.(genderCats{k}).(string(ageCats(j))),1)) ')'];
                    mytitle = join(mytitle,'');
                    title(strrep(mytitle,'_',' '))
                end
            end
        end
        function obj = emoFactorsAgeNonLinear(obj)
           emo = do_factor_analysis(obj);
            obj.FactorNames = emo.factorNames;
            emoLabels = obj.FactorNames;
            for k = 1:size(emo.FAScores,2)
                FAs{k} = emo.FAScores(:,k);
            end
            obj.dataTable = addvars(obj.dataTable,FAs{:},'After','Rebelliousness','NewVariableNames',obj.FactorNames);
            dataMF = obj.dataTable;
            dataMF(matches(dataMF.Gender,'Other'),:) = [];
            genderLabels = unique(dataMF.Gender);
            age = zscore(obj.dataTable.Age);
            for k = 1:size(emo.FAScores,2)
                figure
                %polyfit linear
                [p,S,mu]=polyfit(age,FAs{k},1);
                p_str=[];
                for i=1:length(p)
                    if p(i)<0
                       p_str{i} = string(round(p(i),3));
                    else
                       p_str{i} = strcat('+',string(round(p(i),3)));  
                    end
                end
                [y_fit,delta] = polyval(p,age,S);
                subplot(1,2,1)    
                plot(age,FAs{k},'o')
                hold on
                plot(age,y_fit,'r-','LineWidth',2)
                sgtitle(emoLabels{k})
                form=strcat('Parameters: y=',p_str{1},'x ',p_str{2});
                mse = immse(age,y_fit);
                aic = length(FAs{k}) * log(mse) + 2 * 3
                bic = length(FAs{k}) * log(mse) + 3 * log(length(FAs{k}))
                mseStr = strcat(' MSE: ',string(round(mse,2)));
                aicStr = strcat(' AIC: ',string(round(aic,2)),' BIC: ',string(round(bic,2)));
                title(['Linear Fit',form,mseStr,aicStr])
                ylabel('Factor Score'); xlabel('Age')
                legend('Data','Linear Fit','95% Prediction Interval')
                hold off

                %polyfit quadratic
                [p,S,mu]=polyfit(age,FAs{k},2);
                p_str=[];
                for i=1:length(p)
                    if p(i)<0
                       p_str{i} = string(round(p(i),3));
                    else
                       p_str{i} = strcat('+',string(round(p(i),3))); 
                    end
                end
                [y_fit,delta] = polyval(p,age,S);
                x= linspace(min(age),max(age),2000);
                y_quadratic = polyval(p,x,S);
                subplot(1,2,2)    
                plot(age,FAs{k},'o')
                hold on
                plot(x,y_quadratic,'r-','LineWidth',2)
                form=strcat('Parameters: y=',p_str{1},'x^2 ',p_str{2},...
                    'x ',p_str{3});
                mse = immse(age,y_fit);
                aic = length(FAs{k}) * log(mse) + 2 * 3
                bic = length(FAs{k}) * log(mse) + 3 * log(length(FAs{k}))
                mseStr = strcat(' MSE: ',string(round(mse,2)));
                aicStr = strcat(' AIC: ',string(round(aic,2)),' BIC: ',string(round(bic,2)));
                title(['Quadratic Fit',form,mseStr,aicStr])
                ylabel('Factor Score'); xlabel('Age')
                legend('Data','Quadratic Fit')
                hold off
            end
            keyboard
        end
        function obj = emoFactorsDensity(obj,options)
            arguments
                obj
                options.sigma = 5
                options.iter = 10000
            end
            close all
            addpath('~/Documents/MATLAB/brewermap')
            byGender = obj.byGender;
            bootCImethod = obj.bootCImethod;
            sigma = options.sigma;
            iter = options.iter;
            warning('check number of iterations for confidence interval')
            addpath('~/Documents/MATLAB/distinguishable_colors')
            emo = do_factor_analysis(obj);
            obj.FactorNames = emo.factorNames;
            emoLabels = obj.FactorNames;
            for k = 1:size(emo.FAScores,2)
                FAs{k} = emo.FAScores(:,k);
            end
            obj.dataTable = addvars(obj.dataTable,FAs{:},'After','Rebelliousness','NewVariableNames',obj.FactorNames);
            fh = figure();
            %fh.WindowState = 'maximized';
            emoData = obj.dataTable(:,contains(obj.dataTable.Properties.VariableNames,obj.FactorNames));
            S = size(emoData,2);
            su = stats.explore_age.numSubplots(S);
            tl = tiledlayout(su(1),su(2),'TileSpacing','loose','Padding','loose');
            for k = 1:size(emoData,2)
                disp(emoLabels{k})
                ax{k} = nexttile;
                if strcmpi(byGender,'No')
                    ageRange = min(obj.dataTable.Age):max(obj.dataTable.Age);
                    [B,BG] = groupsummary(emoData{:,k},obj.dataTable.Age,@mean);
                    m = nan(1,max(BG));
                    m(BG) = B;
                    % Kernel regression with constant bandwidth
                    z1=sum(emoData{:,k}.*normpdf(ageRange-obj.dataTable.Age,0,sigma));
                    z2=sum(normpdf(ageRange-obj.dataTable.Age,0,sigma));
                    z=z1./z2;
                    
                    if strcmpi(bootCImethod,'standard')
                        CI = stats.explore_age.confidenceLimits(obj.dataTable.Age,emoData{:,k},95,iter,sigma,bootCImethod);
                        l = z-CI;
                        u = z+CI;
                        l = l(:);
                        u = u(:);
                    else
                        [~,l,u] = stats.explore_age.confidenceLimits(obj.dataTable.Age,emoData{:,k},95,iter,sigma,bootCImethod);
                    end
                    c = brewermap(1,'Set2');
                    set(fh,'defaultLegendAutoUpdate','off');
                    for ii = 1:size(l,2)
                        fill([ageRange fliplr(ageRange)],[l(:,ii)' fliplr(u(:,ii)')],c(ii,:),'LineStyle','none','FaceAlpha',.3);
                        hold on
                    end
                    plot(ageRange,z,'-k','LineWidth',2)
                    reg = regress(z',[ones(size(ageRange,2),1) ageRange']);
                    beta(k) = reg(2);
                    meanKerReg(k)= mean(z);
                    percXlim = prctile(obj.dataTable.Age,[5 95]);
                    smallAgeRange = ageRange(ageRange >= percXlim(1) & ageRange <= percXlim(2));
                    smallZ = z(ageRange >= percXlim(1) & ageRange <= percXlim(2));
                    smallL = l(ageRange >= percXlim(1) & ageRange <= percXlim(2));
                    smallU = u(ageRange >= percXlim(1) & ageRange <= percXlim(2));
                    regsmallAgeRange = regress(smallZ',[ones(size(smallAgeRange,2),1) smallAgeRange']);
                    betasmallAgeRange(k) = regsmallAgeRange(2);
                    
                    reg = regress(z',[ones(size(ageRange,2),1) ageRange']);
                    
                    axis tight
                    xlabel('Age')
                    [~,T] = anovan(obj.dataTable.(emoLabels{k}),findgroups(obj.dataTable.AgeCategory),'Display','off');
                    disp("F("+string(T(2,3))+","+string(T(3,3))+") = " + num2str(str2num(string(T(2,end-1))),'%.2f')+", p = " + string(strrep(num2str(cell2mat(T(2,end)),'%.3f'),'0.','.')))
                else
                    dataMF = obj.dataTable;
                    dataMF(matches(dataMF.Gender,'Other'),:) = [];
                    genderLabels = unique(dataMF.Gender);
                    c = brewermap(numel(genderLabels)+1,'Set2');
                    for gg = 1:numel(genderLabels)
                        data = dataMF(matches(dataMF.Gender, genderLabels{gg}),:);
                        emoDataCurGend = data.(obj.FactorNames{k});
                        ageRange = min(data.Age):max(data.Age);
                        [B,BG] = groupsummary(emoDataCurGend,data.Age,@mean);
                        m = nan(1,max(BG));
                        m(BG) = B;
                        % Kernel regression with constant bandwidth
                        z1=sum(emoDataCurGend.*normpdf(ageRange-data.Age,0,sigma));
                        z2=sum(normpdf(ageRange-data.Age,0,sigma));
                        z=z1./z2;
                        
                        if strcmpi(bootCImethod,'standard')
                            CI = stats.explore_age.confidenceLimits(data.Age,emoDataCurGend,95,iter,sigma,bootCImethod);
                            l = z-CI;
                            u = z+CI;
                            l = l(:);
                            u = u(:);
                        else
                            [~,l,u] = stats.explore_age.confidenceLimits(data.Age,emoDataCurGend,95,iter,sigma,bootCImethod);
                        end
                        set(fh,'defaultLegendAutoUpdate','off');
                        for ii = 1:size(l,2)
                            fill([ageRange fliplr(ageRange)],[l(:,ii)' fliplr(u(:,ii)')],c(gg+1,:),'LineStyle','none','FaceAlpha',.3);
                            hold on
                        end
                        p = plot(ageRange,z,'-k','LineWidth',2);
                        p.Annotation.LegendInformation.IconDisplayStyle = 'off';
                        
                        reg = regress(z',[ones(size(ageRange,2),1) ageRange']);
                        percXlim = prctile(data.Age,[5 95]);
                        smallAgeRange = ageRange(ageRange >= percXlim(1) & ageRange <= percXlim(2));
                        smallZ = z(ageRange >= percXlim(1) & ageRange <= percXlim(2));
                        smallL{gg} = l(ageRange >= percXlim(1) & ageRange <= percXlim(2));
                        smallU{gg} = u(ageRange >= percXlim(1) & ageRange <= percXlim(2));
                        regsmallAgeRange = regress(smallZ',[ones(size(smallAgeRange,2),1) smallAgeRange']);
                        betasmallAgeRange(k) = regsmallAgeRange(2);
                        reg = regress(z',[ones(size(ageRange,2),1) ageRange']);
                        axis tight
                        if gg == 1
                            xlabel('Age')
                            [~,T] = anovan(dataMF.(obj.FactorNames{k}),findgroups(dataMF.AgeCategory),'Display','off');
                            [~,T] = anovan(dataMF.(obj.FactorNames{k}),{findgroups(dataMF.AgeCategory),findgroups(dataMF.Gender)},'Display','off','model','interaction');
                            ageAN = "F("+string(T(2,3))+","+string(T(5,3))+") = " + num2str(str2num(string(T(2,end-1))),'%.2f')+", p = " + string(strrep(num2str(cell2mat(T(2,end)),'%.3f'),'0.','.'));
                            genderAN = "F("+string(T(3,3))+","+string(T(5,3))+") = " + num2str(str2num(string(T(3,end-1))),'%.2f')+", p = " + string(strrep(num2str(cell2mat(T(3,end)),'%.3f'),'0.','.'));
                            ageGenderAN = "F("+string(T(4,3))+","+string(T(5,3))+") = " + num2str(str2num(string(T(4,end-1))),'%.2f')+", p = " + string(strrep(num2str(cell2mat(T(4,end)),'%.3f'),'0.','.'));
                            disp({join(['Age ' ageAN ],'');join(['Gender ' genderAN ],'');join(['Interaction ' ageGenderAN ],'')})
                            %title(join(['Age ' ageAN '; Gender ' genderAN],''))
                        end
                    end
                end
                title(emoLabels{k})
                %grid on
                %xlabel('Age group')
                if strcmpi(byGender,'Yes')
                    curMinCI = min(cellfun(@min,smallL));
                    curMaxCI = max(cellfun(@max,smallU));
                else
                    curMinCI = min(smallL);
                    curMaxCI = max(smallU);
                end
                if k > 1
                    minCI = min(minCI,curMinCI);
                    maxCI = max(maxCI,curMaxCI);
                else
                    [minCI, maxCI] = deal(curMinCI,curMaxCI);
                end
            end
            for k = 1:numel(ax)
                ax{k}.YLim = [minCI,maxCI];
                ax{k}.XLim = percXlim;
                %extra = diff(ax{k}.YLim) * 1/100;
                %ax{k}.YLim = [ax{k}.YLim(1) - extra, ax{k}.YLim(2) + extra];
            end
            
            if strcmpi(byGender,'Yes')
                lgd = legend;
                lgd.String = unique(dataMF.Gender);
                lgd.Layout.Tile = 'north';
                lgd.Orientation = 'horizontal';
            end
            [S I] = sort(betasmallAgeRange,'descend');
            for k = 1:numel(ax)
                ax{I(k)}.Layout.Tile = k;
                ax{I(k)}.TickDir='out'
                ax{I(k)}.Box = 'off'
                if k == 1
                    ax{I(k)}.YLabel.String='Factor score';
                else
                    ax{I(k)}.YTick = [];
                end
            end
            tl.TileSpacing = 'Tight';
            tl.Padding = 'Compact';
            %savefigures('figures/paper_emotions_listening_habits/Age_EmoFactors_kRegression')
        end
        function scatterRegMean(obj)
            emoLabels = obj.dataTable.Properties.VariableNames(obj.dataTableInd);
            figure
            scatter(obj.scatterPlotData(1,:),obj.scatterPlotData(2,:))
            hold on
            text(obj.scatterPlotData(1,:),obj.scatterPlotData(2,:),emoLabels,'Verticalalignment','top','HorizontalAlignment','Center')
            xlabel('slope of kernel regression curve')
            ylabel('mean of kernel regression curve')
            [r p] = corr(obj.scatterPlotData(1,:)',obj.scatterPlotData(2,:)');
            l = lsline
            df = num2str(numel(obj.scatterPlotData(1,:))-2);
            rtext = ['r(' df ') = ' num2str(r,'%.2f')];
            ptext = ['p = ' strrep(num2str(p,'%.3f'),'0.','.')];
            text(l.XData(2),l.YData(2),{rtext;ptext})
            grid on
        end
        function reasonsVarsBarplots(obj)
            % crashes for very long names
            byGenderOpts = {'No','Yes'};
            for kk = 1:numel(byGenderOpts)
                if kk == 1
                    byGender = 'No';
                else
                    byGender = 'Yes';
                end
                trackOpts = {'No','Yes'};
                for jj = 1:numel(trackOpts)
                    mydata = obj.dataTable;
                    if jj == 1
                        track = 'No'; % Yes: reasons for selected track; No: reasons for music in general
                    else
                        track = 'Yes'; % Yes: reasons for selected track; No: reasons for music in general
                    end
                    addpath('~/Documents/MATLAB/distinguishable_colors')
                    mydata.AgeCategory = renamecats(mydata.AgeCategory,{'Under 20','Over 60'},{'<20','60+'});
                    fh = figure();
                    fh.WindowState = 'maximized';
                    reasonTypesKey = {'Music_','Track_'};
                    switch lower(track)
                        case 'no'
                            flag = 1;
                        case 'yes'
                            flag = 2;
                    end
                    REASONData = mydata(:,contains(mydata.Properties.VariableNames,reasonTypesKey{flag}));
                    myTitle = obj.reasonTypes{flag};
                    REASONLabels = REASONData.Properties.VariableNames;
                    [~,TF] = rmmissing(REASONData);
                    mydata(TF,:) = [];
                    S = size(REASONData,2);
                    su = stats.explore_age.numSubplots(S);
                    tl = tiledlayout(su(1),su(2),'TileSpacing','loose','Padding','loose');
                    tl.TileSpacing = 'Compact';
                    tl.Padding = 'None';
                    for k = 1:size(REASONData,2)
                        ax{k} = nexttile;
                        if strcmpi(byGender,'No')
                            G = groupsummary(mydata,"AgeCategory","Mean",REASONLabels{k});
                            %Gsd = groupsummary(mydata,"AgeCategory","std",REASONLabels{k});
                            meanData = G.(['mean_' REASONLabels{k}]);
                            b = bar(G.(['mean_' REASONLabels{k}]));
                            c = categories(mydata.AgeCategory);
                            for j = 1:numel(c)
                                data = mydata.(REASONLabels{k})(matches(string(mydata.AgeCategory),c{j}));
                                ci(:,j) = bootci(10000,@mean,data);
                            end
                            hold on
                            e = errorbar(1:numel(meanData),meanData,ci(1,:),ci(2,:));
                            e.LineStyle = 'none';
                            e.LineWidth = 2;
                            str = join([string(groupsummary(mydata,"AgeCategory").AgeCategory) + " (N=" groupsummary(mydata,"AgeCategory").GroupCount + ")"],'');
                            xticklabels(str);
                            xtickangle(45)
                            [~,T] = anovan(mydata.(REASONLabels{k}),findgroups(mydata.AgeCategory),'Display','off');
                            title("F("+string(T(2,3))+","+string(T(3,3))+") = " + num2str(str2num(string(T(2,end-1))),'%.2f')+", p = " + string(strrep(num2str(cell2mat(T(2,end)),'%.3f'),'0.','.')))
                        else
                            dataMF = mydata;
                            dataMF(matches(dataMF.Gender,'Other'),:) = [];
                            G = groupsummary(dataMF,{'AgeCategory','Gender'},"Mean",REASONLabels{k});
                            meanData = G.(['mean_' REASONLabels{k}]);
                            dataBar = reshape(meanData,2,[])';
                            b = bar(dataBar);
                            [ngroups, nbars] = size(dataBar);
                            groupwidth = min(0.8, nbars/(nbars + 1.5));
                            b(1).FaceColor = [0.8500 0.3250 0.0980];
                            b(2).FaceColor = [0 0.4470 0.7410];
                            [GR,ID1,ID2] = findgroups(dataMF.AgeCategory,dataMF.Gender);
                            for j = 1:numel(unique(GR))
                                data = dataMF.(REASONLabels{k})(GR == j);
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
                            xtickangle(45)
                            [~,T] = anovan(mydata.(REASONLabels{k}),{findgroups(mydata.AgeCategory),findgroups(mydata.Gender)},'Display','off','model','interaction');
                            ageAN = "F("+string(T(2,3))+","+string(T(5,3))+") = " + num2str(str2num(string(T(2,end-1))),'%.2f')+", p = " + string(strrep(num2str(cell2mat(T(2,end)),'%.3f'),'0.','.'));
                            genderAN = "F("+string(T(3,3))+","+string(T(5,3))+") = " + num2str(str2num(string(T(3,end-1))),'%.2f')+", p = " + string(strrep(num2str(cell2mat(T(3,end)),'%.3f'),'0.','.'));
                            ageGenderAN = "F("+string(T(4,3))+","+string(T(5,3))+") = " + num2str(str2num(string(T(4,end-1))),'%.2f')+", p = " + string(strrep(num2str(cell2mat(T(4,end)),'%.3f'),'0.','.'));
                            title({join(['Age ' ageAN ],'');join(['Gender ' genderAN ],'');join(['Interaction ' ageGenderAN ],'')})
                            % ageAN = "F("+string(T(2,3))+","+string(T(4,3))+") = " + num2str(str2num(string(T(2,end-1))),'%.2f')+", p = " + string(strrep(num2str(cell2mat(T(2,end)),'%.3f'),'0.','.'));
                            % genderAN = "F("+string(T(3,3))+","+string(T(4,3))+") = " + num2str(str2num(string(T(3,end-1))),'%.2f')+", p = " + string(strrep(num2str(cell2mat(T(3,end)),'%.3f'),'0.','.'));
                            % title({join(['Age ' ageAN ],'');join(['Gender ' genderAN ],'')})
                            %title(join(['Age ' ageAN '; Gender ' genderAN],''))
                        end
                        ylabel(strrep(obj.reasonLabels{k},'_',' '))
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
                    sgtitle(myTitle)
                end
            end
        end
        function icVarsBarplots(obj)
            % crashes for very long names
            byGender = 'No';
            addpath('~/Documents/MATLAB/distinguishable_colors')
            % shorter versions of obj.icVars
            obj.dataTable.AgeCategory = renamecats(obj.dataTable.AgeCategory,{'Under 20','Over 60'},{'<20','60+'});
            fh = figure();
            fh.WindowState = 'maximized';
            ICData = obj.dataTable(:,ICLabels);
            [~,TF] = rmmissing(ICData);
            obj.dataTable(TF,:) = [];
            S = size(ICData,2);
            su = stats.explore_age.numSubplots(S);
            tl = tiledlayout(su(1),su(2),'TileSpacing','loose','Padding','loose');
            tl.TileSpacing = 'Compact';
            tl.Padding = 'None';
            for k = 1:size(ICData,2)
                ax{k} = nexttile;
                if strcmpi(byGender,'No')
                    G = groupsummary(obj.dataTable,"AgeCategory","Mean",ICLabels{k});
                    %Gsd = groupsummary(obj.dataTable,"AgeCategory","std",ICLabels{k});
                    meanData = G.(['mean_' ICLabels{k}]);
                    b = bar(G.(['mean_' ICLabels{k}]));
                    c = categories(obj.dataTable.AgeCategory);
                    for j = 1:numel(c)
                        data = obj.dataTable.(ICLabels{k})(matches(string(obj.dataTable.AgeCategory),c{j}));
                        ci(:,j) = bootci(10000,@mean,data);
                    end
                    hold on
                    e = errorbar(1:numel(meanData),meanData,ci(1,:),ci(2,:));
                    e.LineStyle = 'none';
                    e.LineWidth = 2;
                    str = join([string(groupsummary(obj.dataTable,"AgeCategory").AgeCategory) + " (N=" groupsummary(obj.dataTable,"AgeCategory").GroupCount + ")"],'');
                    xticklabels(str);
                    [~,T] = anovan(obj.dataTable.(ICLabels{k}),findgroups(obj.dataTable.AgeCategory),'Display','off');
                    title("F("+string(T(2,3))+","+string(T(3,3))+") = " + num2str(str2num(string(T(2,end-1))),'%.2f')+", p = " + string(strrep(num2str(cell2mat(T(2,end)),'%.3f'),'0.','.')))
                else
                    dataMF = obj.dataTable;
                    dataMF(matches(dataMF.Gender,'Other'),:) = [];
                    G = groupsummary(dataMF,{'AgeCategory','Gender'},"Mean",ICLabels{k});
                    meanData = G.(['mean_' ICLabels{k}]);
                    dataBar = reshape(meanData,2,[])';
                    b = bar(dataBar);
                    [ngroups, nbars] = size(dataBar);
                    groupwidth = min(0.8, nbars/(nbars + 1.5));
                    b(1).FaceColor = [0.8500 0.3250 0.0980];
                    b(2).FaceColor = [0 0.4470 0.7410];
                    [GR,ID1,ID2] = findgroups(dataMF.AgeCategory,dataMF.Gender);
                    for j = 1:numel(unique(GR))
                        data = dataMF.(ICLabels{k})(GR == j);
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
                    [~,T] = anovan(obj.dataTable.(ICLabels{k}),{findgroups(obj.dataTable.AgeCategory),findgroups(obj.dataTable.Gender)},'Display','off');
                    
                    ageAN = "F("+string(T(2,3))+","+string(T(4,3))+") = " + num2str(str2num(string(T(2,end-1))),'%.2f')+", p = " + string(strrep(num2str(cell2mat(T(2,end)),'%.3f'),'0.','.'));
                    genderAN = "F("+string(T(3,3))+","+string(T(4,3))+") = " + num2str(str2num(string(T(3,end-1))),'%.2f')+", p = " + string(strrep(num2str(cell2mat(T(3,end)),'%.3f'),'0.','.'));
                    title({join(['Age ' ageAN ],'');join(['Gender ' genderAN ],'')})
                    %title(join(['Age ' ageAN '; Gender ' genderAN],''))
                end
                ylabel(strrep(ICLabels{k},'_',' '))
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
        function obj = emoVarsRegressionScatter(obj)
            addpath('~/Documents/MATLAB/brewermap')
            fontSize = 12;
            emoLabels = obj.dataTable.Properties.VariableNames(obj.dataTableInd);
            if strcmpi(obj.byGender,'Yes')
                dataMF = obj.dataTable;
                dataMF(matches(dataMF.Gender,'Other'),:) = [];
                genderLabels = unique(dataMF.Gender);
                emoData = dataMF(:,obj.dataTableInd);
                age = dataMF.Age;
                c = brewermap(numel(genderLabels)+1,'Set2');
                g = get(groot,'defaultfigureposition');
                g(3:4) = g(3:4)*2;
                figure('Position',g)
                for k = 1:numel(genderLabels)
                    genderLog = string(dataMF.Gender) == genderLabels{k};
                    ageGender{k} = age(genderLog);
                    emoGender{k} = emoData(genderLog,:);
                    
                    meanGender(k) = mean(emoGender{k}{:,:},[1 2]);
                    stdGender(k) = std(emoGender{k}{:,:},[],[1 2]);
                    for j = 1:size(emoGender{k},2)
                        reg = regress(emoGender{k}{:,j},[ones(size(ageGender{k},1),1) ageGender{k}]);
                        % note that only predictors are
                        % standardized; we just want to mean center x
                        [corrR(j,k) corrP(j,k)] = corr(emoGender{k}{:,j}, ageGender{k});
                        y(j,k) = mean(emoGender{k}{:,j});
                        %y(j,k) = reg(1);%intercept
                        x(j,k) = reg(2);%slope
                    end
                end
                for k = 1:numel(genderLabels)
                    yl(k) = yline(meanGender(k),'--','Color',c(k+1,:));
                    yl(k).Color(4) = .5;
                    yl(k).Annotation.LegendInformation.IconDisplayStyle = 'off';
                end
                xl = xline(0,'Color',[.5,.5,.5]);
                xl.Annotation.LegendInformation.IconDisplayStyle = 'off';
                hold on
                p = plot(x',y','k','Color',[.5 .5 .5]);
                pax = axis;
                for k = 1:numel(p)
                    p(k).Annotation.LegendInformation.IconDisplayStyle = 'off';
                end
                grid on
                for k = 1:numel(genderLabels)
                    S = scatter(x(:,k),y(:,k));
                    yreg = S.YData';
                    xreg = S.XData';
                    xregInt = [ones(length(xreg),1) xreg];
                    b{k} = xregInt\yreg;
                    %plot(xreg,xregInt*b{k},'LineWidth',2)
                    anglsline(k) = rad2deg(atan(b{k}(2)));
                    S.MarkerFaceColor = c(k+1,:);
                    S.MarkerEdgeColor = c(k+1,:);
                end
                rText = arrayfun(@(x) strrep(num2str(x,'%.2f'),'0.','.'),corrR,'un',0);
                pStarsText = stats.correlate_reasons.makestars(corrP);
                corrsText = string(rText) + string(pStarsText);
                
                %text(x(:),y(:),corrsText(:),'Verticalalignment','top','HorizontalAlignment','Center','FontSize',fontSize-3);
                
                text(mean(x,2),mean(y,2),emoLabels,'Verticalalignment','top','HorizontalAlignment','Center','FontSize',fontSize);
                set(gca,'FontSize', fontSize)
                l = legend(genderLabels);
                l.AutoUpdate = 'off';
                [rCorr pCorr] = corr(x,y);
                rCorr = diag(rCorr);
                pCorr = diag(pCorr);
                df = num2str(numel(x)-2);
                for k = 1:numel(rCorr)
                    r = rCorr(k);
                    p = pCorr(k);
                    rtext{k} = ['r(' df ') = ' strrep(num2str(r,'%.2f'),'0.','.')];
                    ptext{k} = ['p = ' strrep(num2str(p,'%.3f'),'0.','.')];
                end
                axis square
                ax = axis;
                for k = 1:numel(genderLabels)
                    text(ax(2),meanGender(k),string(genderLabels(k))+' mean rating','Color',c(k+1,:));
                end
                %axis([-ax(2) ax(2) mean(meanGender)-mean(stdGender) mean(meanGender)+mean(stdGender)])
                axis([-ax(2) ax(2) pax(3) pax(4)])
                ax = axis;
                lsl = lsline;
                axis([-ax(2) ax(2) pax(3) pax(4)]);
                %axis([-ax(2) ax(2) mean(meanGender)-mean(stdGender) mean(meanGender)+mean(stdGender)])
                ax = axis;
                i = numel(genderLabels);
                for k = 1:numel(genderLabels)
                    l = lsl(i);
                    xValueText =-.02;
                    xValueText2 = -.01;
                    yValueText = [1 xValueText]*b{k};
                    yValueText2 = [1 xValueText2]*b{k};
                    xO = xValueText2-xValueText;
                    yO = yValueText2-yValueText;
                    xONew = ax(2)-ax(1);
                    yONew = ax(4)-ax(3);
                    nXValue = xO*xONew;
                    nYValue = yO*yONew;
                    newAngle = atand(nYValue/nXValue);
                    %axAng = atand((ax(4)-ax(3))/(ax(2)-ax(1)));
                    %f = gcf;
                    %pos = f.Position;
                    %posAng = atand((pos(4)-pos(3))/(pos(2)-pos(1)));
                    l.Color = [c(k+1,:) .25];
                    t = text(xValueText,yValueText,{rtext{k};ptext{k}},'Color',c(k+1,:));
                    
                    t.Rotation = 0;
                    %text(l.XData(2),l.YData(2),{rtext{k};ptext{k}},'FontSize',fontSize-2,'Color',c(k+1,:));
                    i = i-1;
                end
            else
                emoData = obj.dataTable(:,obj.dataTableInd);
                age = obj.dataTable.Age;
                for k = 1:size(emoData,2)
                    reg = regress(emoData{:,k},[ones(size(age,1),1) age]);
                    [corrR(j,k) corrP(j,k)] = corr(emoData{:,k},age);
                    y(k) = reg(1);%intercept
                    x(k) = reg(2);%slope
                end
                scatter(x,y)
                hold on
                grid on
                
                text(x,y,emoLabels,'Verticalalignment','top','HorizontalAlignment','Center','FontSize',fontSize)
                grid on
                [r p] = corr(x',y');
                l = lsline
                df = num2str(numel(x)-2);
                rtext = ['r(' df ') = ' num2str(r,'%.2f')];
                ptext = ['p = ' strrep(num2str(p,'%.3f'),'0.','.')];
                text(l.XData(2),l.YData(2),{rtext;ptext},'FontSize',fontSize-2);
            end
            xlabel('Slope')
            ylabel('Mean')
            set(gca,'FontSize', fontSize)
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
            obj.FactorNames = emo.factorNames;
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
            obj.FactorNames = emo.factorNames;
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
            obj.FactorNames = emo.factorNames;
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
        function obj = ttestCountryGenderAncova(obj)
           emo = do_factor_analysis(obj);
           %ageCats = onehotencode(obj.dataTable.AgeCategory,2);
            figure
            for k = 1:size(emo.FAScores,2)
                subplot(1,size(emo.FAScores,2),k)
                [b(:,k),~,r(:,k),~,statCov{k}] = regress(emo.FAScores(:,k),[ones(length(emo.FAScores),1) obj.dataTable.Age]);
                gscatter(obj.dataTable.Age,emo.FAScores(:,k),obj.dataTable{:,obj.groupingCategory})
            end
            emo.FAScores = r; %Regressing out the influence of age from fator scores 
            for i = 1:length(obj.subgroupNames)
                for k = 1:size(emo.FAScores,2) 
                    data = obj.dataTable(strcmpi(obj.dataTable{:,obj.groupingCategory},obj.subgroupNames{i}),:);
                    FScores = emo.FAScores(strcmpi(obj.dataTable{:,obj.groupingCategory},obj.subgroupNames{i}),k);
                    m = FScores(strcmpi(data.Gender,'Male'));
                    f = FScores(strcmpi(data.Gender,'Female'));
                    [~,p(i,k),~,tstats] = ttest2(f,m);
                    tstat(i,k) = tstats.tstat;
                    tstatStr{i,k} = stats.explore_age.pvalue_stars_string_estimate(tstat(i,k),p(i,k),1);
                end
            end
            disp(array2table(tstatStr,'RowNames',obj.subgroupNames,'VariableNames',emo.factorNames))
            %plot tstatistic for each factor 
            figure
            for k=1:size(emo.FAScores,2)
                [t,i] = sortrows(tstat(:,k));
                subplot(1,size(emo.FAScores,2),k)
                plot((t));
                set(gca,'Xtick',1:height(t),'XTickLabels',obj.subgroupNames(i));
                xtickangle(45)
                title(emo.factorNames{k})
            end
            giiPath = 'data/2020_statistical_annex_table_5.xlsx';
            gii = readtable(giiPath);
            
            for c = 1:length(obj.subgroupNames)
                giiValue(c) = gii.Var3(strcmpi(gii.Var2,obj.subgroupNames{c}));
                %FAGroups(c,:) = nanmean(emo.FAScores(strcmpi(obj.dataTable{:,obj.groupingCategory},obj.subgroupNames{c}),:));
            end
            
            figure
            for k=1:size(emo.FAScores,2)
                [rho,pval] = corr(giiValue',tstat(:,k));
                subplot(1,size(emo.FAScores,2),k)
                scatter(giiValue',tstat(:,k),'filled');                
                title([emo.factorNames{k}, newline 'r = ' sprintf('%0.02f',rho)])
                xlabel('Gender Inequality Index')
                ylabel ('Tstatistic')
                lsline
            end
        end
        function obj = ttestGIISubscalesAncova(obj)
           emo = do_factor_analysis(obj);
           %ageCats = onehotencode(obj.dataTable.AgeCategory,2);
            figure
            for k = 1:size(emo.FAScores,2)
                subplot(1,size(emo.FAScores,2),k)
                [b(:,k),~,r(:,k),~,statCov{k}] = regress(emo.FAScores(:,k),[ones(length(emo.FAScores),1) obj.dataTable.Age]);
                gscatter(obj.dataTable.Age,emo.FAScores(:,k),obj.dataTable{:,obj.groupingCategory})
            end
            emo.FAScores = r; %Regressing out the influence of age from fator scores 
            for i = 1:length(obj.subgroupNames)
                for k = 1:size(emo.FAScores,2) 
                    data = obj.dataTable(strcmpi(obj.dataTable{:,obj.groupingCategory},obj.subgroupNames{i}),:);
                    FScores = emo.FAScores(strcmpi(obj.dataTable{:,obj.groupingCategory},obj.subgroupNames{i}),k);
                    m = FScores(strcmpi(data.Gender,'Male'));
                    f = FScores(strcmpi(data.Gender,'Female'));
                    [~,p(i,k),~,tstats] = ttest2(f,m);
                    tstat(i,k) = tstats.tstat;
                    tstatStr{i,k} = stats.explore_age.pvalue_stars_string_estimate(tstat(i,k),p(i,k),1);
                end
            end
            disp(array2table(tstatStr,'RowNames',obj.subgroupNames,'VariableNames',emo.factorNames))
            %plot tstatistic for each factor 
            figure
            for k=1:size(emo.FAScores,2)
                [t,i] = sortrows(tstat(:,k));
                subplot(1,size(emo.FAScores,2),k)
                plot((t));
                set(gca,'Xtick',1:height(t),'XTickLabels',obj.subgroupNames(i));
                xtickangle(45)
                title(emo.factorNames{k})
            end
            giiPath = 'data/2020_statistical_annex_table_5.xlsx';
            gii = readtable(giiPath);
            
            %plot gii values
            figure
            [g,i] = sortrows(giiValue');
            plot(g)
            set(gca, 'XTick',1:length(obj.subgroupNames),'XTickLabel',obj.subgroupNames(i))
            xlabel('Countries of origins')
            xtickangle(45)
            ylabel('Gender Inequality Index')
            
            education = gii.SDG4_4 - gii.Var15;
            labor = gii.Var17 - gii.Var19;
            
            giiVars = [gii.Var3, gii.SDG3_1, gii.SDG3_7, education, labor]
            labels = {'GII', 'Maternal Mortality','Adolescent birth rate','Parliament seats',...
                'Education Participation','Labor Market Participation'}
            for c = 1:length(obj.subgroupNames)
                for i=1:5
                giiRes(i,c) = giiVars(strcmpi(gii.Var2,obj.subgroupNames{c}),i);
                %FAGroups(c,:) = nanmean(emo.FAScores(strcmpi(obj.dataTable{:,obj.groupingCategory},obj.subgroupNames{c}),:));
                end
            end
            
            for i=1:5
                figure
            for k=1:size(emo.FAScores,2)
                [rho,pval] = corr(giiRes(i,:)',tstat(:,k));
                subplot(1,size(emo.FAScores,2),k)
                scatter(giiRes(i,:)',tstat(:,k),'filled');                
                title([emo.factorNames{k}, newline 'r = ' sprintf('%0.02f',rho)])
                xlabel(labels{i})
                ylabel ('Tstatistic')
                lsline
            end
            sgtitle(labels{i})
            end
        end
        function obj = ttestCountryGender(obj)
            emo = do_factor_analysis(obj);
            for i = 1:length(obj.subgroupNames)
                for k = 1:size(emo.FAScores,2) 
                    data = obj.dataTable(strcmpi(obj.dataTable{:,obj.groupingCategory},obj.subgroupNames{i}),:);
                    FScores = emo.FAScores(strcmpi(obj.dataTable{:,obj.groupingCategory},obj.subgroupNames{i}),k);
                    m = FScores(strcmpi(data.Gender,'Male'));
                    f = FScores(strcmpi(data.Gender,'Female'));
                    [~,p(i,k),~,tstats] = ttest2(f,m);
                    tstat(i,k) = tstats.tstat;
                    tstatStr{i,k} = stats.explore_age.pvalue_stars_string_estimate(tstat(i,k),p(i,k),1);
                end
            end
            disp(array2table(tstatStr,'RowNames',obj.subgroupNames,'VariableNames',emo.factorNames))
            %plot tstatistic for each factor 
            figure
            for k=1:size(emo.FAScores,2)
                [t,i] = sortrows(tstat(:,k));
                subplot(1,size(emo.FAScores,2),k)
                plot((t));
                set(gca,'Xtick',1:height(t),'XTickLabels',obj.subgroupNames(i));
                xtickangle(45)
                title(emo.factorNames{k})
            end
            giiPath = 'data/2020_statistical_annex_table_5.xlsx';
            gii = readtable(giiPath);
            
            for c = 1:length(obj.subgroupNames)
                giiValue(c) = gii.Var3(strcmpi(gii.Var2,obj.subgroupNames{c}));
                %FAGroups(c,:) = nanmean(emo.FAScores(strcmpi(obj.dataTable{:,obj.groupingCategory},obj.subgroupNames{c}),:));
            end
            %plot gii values
            figure
            [g,i] = sortrows(giiValue');
            plot(g)
            set(gca, 'XTick',1:length(obj.subgroupNames),'XTickLabel',obj.subgroupNames(i))
            xlabel('Countries of origins')
            xtickangle(45)
            ylabel('Gender Inequality Index')
            
            figure
            for k=1:size(emo.FAScores,2)
                [rho,pval] = corr(giiValue',tstat(:,k));
                subplot(1,size(emo.FAScores,2),k)
                scatter(giiValue',tstat(:,k),'filled');                
                title([emo.factorNames{k}, newline 'r = ' sprintf('%0.02f',rho)])
                xlabel('Gender Inequality Index')
                ylabel ('Tstatistic')
                lsline
            end
        end
        function obj = anovaCountryAge(obj)
            emo = do_factor_analysis(obj);
            emo.factorNames;
            for i = 1:length(obj.subgroupNames)
                for k = 1:size(emo.FAScores,2)
                    data = obj.dataTable(strcmpi(obj.dataTable{:,obj.groupingCategory},obj.subgroupNames{i}),:);
                    FScores = emo.FAScores(strcmpi(obj.dataTable{:,obj.groupingCategory},obj.subgroupNames{i}),k)
                    m = FScores(strcmpi(data.Gender,'Male'));
                    f = FScores(strcmpi(data.Gender,'Female'));
                    [~,p(i,k),~,tstats] = ttest2(f,m);
                    [~,tbl] = anova1(cell2mat(a),[],'off');
                    fStat(ii) = tbl{2,5}; % anova F-statistic
                    SScol = tbl{2,2}; SStotal = tbl{4,2};
                    etaSquare = SScol/SStotal;
                    tstat(i,k) = tstats.tstat;
                    tstatStr{i,k} = stats.explore_age.pvalue_stars_string_estimate(tstat(i,k),p(i,k),1);
                end
            end
            disp(array2table(tstatStr,'RowNames',obj.subgroupNames,'VariableNames',emo.factorNames))
        end
    end
    methods (Static)
        function [lower upper] = confidenceLimits_old(x,y,p,k,sigma)
            % Kernel regression with constant bandwidth
            
            % this should be done for each of the existing ages
            % separately, maybe: for each age, do a datasample with
            % replacement with the number
            % of people that we have from that age.
            p1 = (100-p)/2;
            p2 = 100-(100-p)/2;
            ageRange = min(x):max(x);
            for j = 1:k
                ys = y;
                for ii = 1:numel(ageRange)
                    logAge = x == ageRange(ii);
                    numParticPerAgeYear(ii) = sum(logAge);
                    [d idx] = datasample(y(logAge),size(y(logAge),1));
                    ys(logAge) = d;
                end
                [B,BG] = groupsummary(ys,x,@mean);
                m = nan(1,max(BG));
                m(BG) = B;
                z1=sum(ys.*normpdf(ageRange-x,0,sigma));
                z2=sum(normpdf(ageRange-x,0,sigma));
                z=z1./z2;
                r(j,:) = z;
            end
            lower = squeeze(prctile(r,p1,1))';
            upper = squeeze(prctile(r,p2,1))';
        end
        function [CI,lower,upper] = confidenceLimits(x,y,p,k,sigma,bootCImethod)
            %[lower upper]: use the quantile method
            %CI = uses the standard method (normal approximation)
            % Kernel regression with constant bandwidth
            
            p1 = (100-p)/2;
            p2 = 100-(100-p)/2;
            ageRange = min(x):max(x);
            for j = 1:k
                data = [x,y];% original data
                ds = datasample(data,size(data,1),'Replace',true);% data sample
                [B,BG] = groupsummary(ds(:,2),ds(:,1),@mean);% mean
                % feature value
                % for
                % each
                % age
                % year
                % in
                % the
                % data sample
                m = nan(1,max(BG));
                m(BG) = B;
                z1=sum(ds(:,2).*normpdf(ageRange-ds(:,1),0,sigma));
                z2=sum(normpdf(ageRange-ds(:,1),0,sigma));
                z=z1./z2;
                r(j,:) = z;
            end
            CI = -norminv((1-(p/100))/2).*sqrt(var(r));
            lower = squeeze(prctile(r,p1,1))';
            upper = squeeze(prctile(r,p2,1))';
        end
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
        function y = pvalue_stars_string_estimate(estimate,pval,mulComparisons)
            % for a given p-val, gives stars
            if pval < .001/mulComparisons
                stars = '***';
            elseif pval < .01/mulComparisons & pval >= .001/mulComparisons
                stars = '**';
            elseif pval < .05/mulComparisons & pval >= .01/mulComparisons
                stars = '*';
            elseif pval >= .05/mulComparisons
                stars = '';
            end
            y=sprintf('%0.02f',round(estimate,2));
            y=[y stars];
        end
    end
end
