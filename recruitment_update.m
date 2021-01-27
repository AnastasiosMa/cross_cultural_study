%% Music Listening Habits Recruitment Report
%Basic Demographic Information for recruited sample
disp(['Note: Includes only participants that have completed the MLH ',...
    'and Demographics part of the survey']);

disp(['Date: ' datestr(datetime('now'))])
warning off
cd(('~/Desktop/ccstudy'));
%obj = load_data.load_data('~/Desktop/ccstudy/responses_pilot/Music Listening Habits.csv');
obj.dataTable = readtable('~/Desktop/ccstudy/ccsData.csv','Encoding','UTF-8');
%% Number of participants
N = height(obj.dataTable);
disp(['Total number of responses: ' num2str(N)]);

%Display Number of participants per LANGUAGE
language_counts = groupcounts(obj.dataTable,'language');
language_counts.language = string(language_counts.language);
disp('Number of responses per LANGUAGE')
disp(sortrows(language_counts,-2))
%Display Number of participants per COUNTRY
country_counts = groupcounts(obj.dataTable,'Country_childhood');
country_counts.('Country_childhood') = string(country_counts.('Country_childhood'));
disp('Number of responses per COUNTRY OF CHILDHOOD')
disp(sortrows(country_counts,-2))
%% Gender
gender_N = groupcounts(obj.dataTable,'Gender');
disp(gender_N)

%% Age (all)
m_Age = mean(obj.dataTable.Age);
sd_Age = std(obj.dataTable.Age);
disp('Mean and SD for ALL participants')
disp(array2table([m_Age, sd_Age],'VariableNames',{'Mean','SD'}))
disp('Histogram for ALL participants')
figure
histogram(obj.dataTable.Age);
xlabel('Age (in years)'); ylabel('Number of responders');
title('Age Histogram')
%% Age (languages)
%Age distribution across languages
disp('Age distribution per LANGUAGE')
%figure
boxplot(obj.dataTable.Age,obj.dataTable.language)
xlabel('Languages');ylabel('Age');
title('Boxplots per language');
%% Age (countries)
disp('Age distribution per COUNTRY OF ORIGIN')
disp('Note: Only including countries with 20 or more participants')
countries_N = groupcounts(obj.dataTable,'Country_childhood');
            %find countries with enough participants
countries_N = table2array(countries_N(table2array(countries_N(:,2))>=20,1));
%Find indexes of countries with enough participants
all_idx = cellfun(@(x) find(strcmp(x, obj.dataTable.Country_childhood)),...
    countries_N, 'UniformOutput', false);
idx_c = [];
disp('Histograms per country')
for i=1:length(all_idx)
    idx_c = [idx_c; all_idx{i}];
    stats_c(i,1) = mean(obj.dataTable.Age(all_idx{i}));
    stats_c(i,2) = std(obj.dataTable.Age(all_idx{i}));
    figure
    histogram(obj.dataTable.Age(all_idx{i}))
    xlabel('Age (in years)'); ylabel('Number of responders');
    title([countries_N{i}])    
end
%%
disp('Means and SDs per country')
disp(array2table(stats_c,'VariableNames',{'Mean','SD'},'RowNames',countries_N))
%%
disp('Boxplots per country')
boxplot(obj.dataTable.Age(idx_c),obj.dataTable.Country_childhood(idx_c))
xlabel('Countries');ylabel('Age');
title('Boxplots per Country');
%options_doc_nocode.format = 'pdf';
%options_doc_nocode.showCode = false;
%publish('recruitment_update.m',options_doc_nocode);