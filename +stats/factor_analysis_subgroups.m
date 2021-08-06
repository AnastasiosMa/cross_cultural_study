classdef factor_analysis_subgroups
    %Compare factor analysis with subgroups and without
    %example obj = stats.factor_analysis_subgroups()
    properties
        Res
        subRes
        nosubRes
    end

    methods
        function obj = factor_analysis_subgroups(obj)
            a = stats.factor_analysis();
            a.filterMethod = 'AllResponses';
            a = stats.factor_analysis();
            a.filterMethod = 'BalancedSubgroups';
            b = stats.factor_analysis();
            obj.Res{1} = a.do_factor_analysis;
            obj.Res{2} = b.do_factor_analysis;

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
