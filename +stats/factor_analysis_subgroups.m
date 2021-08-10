classdef factor_analysis_subgroups
    %Compare factor analysis with subgroups and without
    %example obj = stats.factor_analysis_subgroups('~/Desktop/ccstudy/responses_pilot/Music Listening Habits.csv')
    
    properties
        Res
        subRes
        nosubRes
    end
    
    methods
        function obj = factor_analysis_subgroups(dataPath)
            obj.Res{1} = stats.factor_analysis(dataPath,'AllResponses');
            obj.Res{2} = stats.factor_analysis(dataPath,'BalancedSubgroups');
            
            obj = fa_compare(obj);
        end
        function obj = fa_compare(obj)
            figure
            for i=1:2
                subplot(1,2,i)
                heatmap(obj.Res{i}.FAcoeff)
                ax = gca; ax.YDisplayLabels = num2cell(obj.Res{i}.emoLabels);
                title(['Factor Loadings ' obj.Res{i}.filterMethod])
            end
            snapnow
        end
    end
end

