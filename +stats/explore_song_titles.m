classdef explore_song_titles < load_data.load_data & stats.factor_analysis
%obj = stats.explore_song_titles();obj.filterMethod='AllResponses';obj=do_load_data(obj);do_explore(obj)
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
        byGender = 'Yes';
        fullTitles = 'No'
    end
    methods
        function obj = explore_song_titles(obj)
            obj=do_load_data(obj);
        end
        function obj = do_explore(obj)
            shape = 'oval';
            obj.dataTable(strcmpi(obj.dataTable.Track,'prockink'),:) = [];
            %fh = figure();
            %fh.WindowState = 'maximized';
            tiledlayout('flow')
            cats = categories(obj.dataTable.IndColCategory);
            for k = 1:numel(cats)
                nexttile
                catLog = obj.dataTable.IndColCategory == cats{k};
                N{k} = sum(catLog);
                fullTitles = lower(obj.dataTable.Track(catLog));
                fullTitles=replace(string(fullTitles),{'bohemian rapsody','bohemia rapsody'},'bohemian rhapsody');
                disp(cats{k})
                disp('percentage of occurrences of Bohemian Rhapsody:')
                (sum(strcmpi(fullTitles,'bohemian rhapsody'))/numel(fullTitles))*100
                if strcmpi(obj.fullTitles,'Yes')
                    wordcloud(categorical(fullTitles),'shape',shape)
                else
                    split = arrayfun(@(x) strsplit(x,' ')',string(fullTitles),'un',0);
                    str = string;
                    for j = 1:numel(split)
                    str = [str; split{j}];
                    end
                    punctuationCharacters = ["." "?" "!" "," ";" ":"];
                    str = replace(str,punctuationCharacters," ");
                    str(matches(str,{'the','of','in','you','re','my','a','and','i','me','to','for','it','is','de','la','no'})) = [];
                    wordcloud(categorical(str),'shape',shape)
                end
                mytitle = [cats{k} ' (N=' num2str(N{k}) ')'];
                title(strrep(mytitle,'_',' '))
                if k == 4
                    keyboard
                end
            end
        end
    end
end
