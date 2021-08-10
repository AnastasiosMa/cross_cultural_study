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
            a = do_load_data(a);
            obj.Res{1} = a.do_factor_analysis;

            b = stats.factor_analysis();
            b.filterMethod = 'BalancedSubgroups';
            b = do_load_data(b);
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
