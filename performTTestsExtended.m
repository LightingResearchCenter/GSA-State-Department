function performTTestsExtended
timestamp = datestr(now,'yyyy-mm-dd HH-MM');

[githubDir,~,~] = fileparts(pwd);
d12packDir = fullfile(githubDir,'d12pack');
addpath(d12packDir);

projectDir = '\\ROOT\projects\GSA_Daysimeter\StateDepartment_2017\Daysimeter_Data';

% Load data
objArray = loadData;

% Remove subjects
% idx610 = strcmp('610',{objArray(:).ID}');
% idx621 = strcmp('621',{objArray(:).ID}');
% idxRemove = idx610 | idx621;
% objArray(idxRemove) = [];

VarNames = {'CircadianStimulus','CircadianLight','Melanopsin'};
nVar = numel(VarNames);

for iVar = 1:nVar
    performTTestsBasic(objArray, VarNames{iVar}, projectDir, timestamp);
end



end

function performTTestsBasic(objArray, VarName, projectDir, timestamp)
%ANALYZEDATA Summary of this function goes here
%   Detailed explanation goes here

nObj = numel(objArray);
h = waitbar(0,'Please wait. Analyzing data...');

IDs = matlab.lang.makeUniqueStrings({objArray.ID}');
[IDs,I] = sort(IDs);

tmpl = table;
tmpl.subject = {};
tmpl.value = zeros(0);

baselineMorning   = tmpl;
baselineAfternoon = tmpl;
interventionMorning   = tmpl;
interventionAfternoon = tmpl;


for iObj = 1:nObj
    
    obj = objArray(I(iObj));
    thisSubject = obj.ID;
    
    idxKeep = obj.Observation & obj.Compliance & ~obj.Error & ~obj.InBed;
    
    if ~any(idxKeep)
        continue
    end
    
    t = obj.Time(idxKeep);
    value = obj.(VarName)(idxKeep);
    
    date0 = dateshift(t(1),'start','day');
    dateF = dateshift(t(end),'start','day');
    dates = date0:calendarDuration(0,0,1):dateF;
    
    nDates = numel(dates);
    
    tempMorning = table;
    tempAfternoon = table;
    for iDate = 1:nDates
        idx = t >= (dates(iDate)+duration(7,0,0)) & t < (dates(iDate)+duration(12,0,0));
        if any(idx)
            thisValue =  value(idx);
            thisSubjectExtended = repmat({thisSubject},size(thisValue));
            tbl = table;
            tbl.subject = thisSubjectExtended;
            tbl.value = thisValue;
            tempMorning = vertcat(tempMorning, tbl );
        end
        
        idx = t >= (dates(iDate)+duration(14,0,0)) & t < (dates(iDate)+duration(17,0,0));
        if any(idx)
            thisValue =  value(idx);
            thisSubjectExtended = repmat({thisSubject},size(thisValue));
            tbl = table;
            tbl.subject = thisSubjectExtended;
            tbl.value = thisValue;
            tempAfternoon = vertcat(tempAfternoon, tbl );
        end
    end
    
    switch obj.Session.Name
        case 'baseline'
            baselineMorning   = vertcat(baselineMorning,   tempMorning);
            baselineAfternoon = vertcat(baselineAfternoon, tempAfternoon);
        case 'intervention'
            interventionMorning   = vertcat(interventionMorning,   tempMorning);
            interventionAfternoon = vertcat(interventionAfternoon, tempAfternoon);
    end
    
    waitbar(iObj/nObj);
end
close(h);


xslxPath = fullfile(projectDir,'tables', [timestamp,' ',VarName,' for t-Test extended.xlsx']);
writetable(baselineMorning, xslxPath, 'Sheet', 'baselineMorning');
writetable(interventionMorning, xslxPath, 'Sheet', 'interventionMorning');
writetable(baselineAfternoon, xslxPath, 'Sheet', 'baselineAfternoon');
writetable(interventionAfternoon, xslxPath, 'Sheet', 'interventionAfternoon');

plotPath = fullfile(projectDir,'plots', [timestamp,' ',VarName,' histogram.pdf']);
f = figure;
f.Units = 'inches';
f.Position = [5,0,8.5,11];
f.PaperPosition = [0,0,8.5,11];


means = struct;
means.baselineMorning = mean(baselineMorning.value);
means.baselineAfternoon = mean(baselineAfternoon.value);
means.interventionMorning = mean(interventionMorning.value);
means.interventionAfternoon = mean(interventionAfternoon.value);

medians = struct;
medians.baselineMorning = median(baselineMorning.value);
medians.baselineAfternoon = median(baselineAfternoon.value);
medians.interventionMorning = median(interventionMorning.value);
medians.interventionAfternoon = median(interventionAfternoon.value);

switch VarName
    case 'CircadianStimulus'
        limits = [0 0.7];
        nbins = 28;
        edges = 0:0.7/nbins:0.7;
        scale = 'linear';
    otherwise
        M = max(vertcat(baselineMorning.value, baselineAfternoon.value, baselineAfternoon.value, baselineAfternoon.value));
        limits = [1 M];
        nbins = 28;
        edges = exp(0:log(M)/nbins:log(M));
        scale = 'log';
        
        baselineMorning.value(baselineMorning.value<1) = 1;
        baselineAfternoon.value(baselineAfternoon.value<1) = 1;
        interventionMorning.value(interventionMorning.value<1) = 1;
        interventionAfternoon.value(interventionAfternoon.value<1) = 1;
end

h = subplot(2,2,1);
histogram(baselineMorning.value,edges);
title({VarName;'Baseline Morning'})
ylabel('Frequency')
xlabel(VarName)
h.XScale = scale;
h.YScale = scale;
xlim(limits)
hold on
plot([means.baselineMorning,means.baselineMorning],h.YLim,'LineWidth',2)
plot([medians.baselineMorning,medians.baselineMorning],h.YLim,'LineWidth',2)
hold off
legend('data','mean','median')

h = subplot(2,2,2);
histogram(baselineAfternoon.value,edges);
title({VarName;'Baseline Afternoon'})
ylabel('Frequency')
xlabel(VarName)
h.XScale = scale;
h.YScale = scale;
xlim(limits)
hold on
plot([means.baselineAfternoon,means.baselineAfternoon],h.YLim,'LineWidth',2)
plot([medians.baselineAfternoon,medians.baselineAfternoon],h.YLim,'LineWidth',2)
hold off
legend('data','mean','median')

h = subplot(2,2,3);
histogram(interventionMorning.value,edges);
title({VarName;'Intervention Morning'})
ylabel('Frequency')
xlabel(VarName)
h.XScale = scale;
h.YScale = scale;
xlim(limits)
hold on
plot([means.interventionMorning,means.interventionMorning],h.YLim,'LineWidth',2)
plot([medians.interventionMorning,medians.interventionMorning],h.YLim,'LineWidth',2)
hold off
legend('data','mean','median')

h = subplot(2,2,4);
histogram(interventionAfternoon.value,edges);
title({VarName;'Intervention Afternoon'})
ylabel('Frequency')
xlabel(VarName)
h.XScale = scale;
h.YScale = scale;
xlim(limits)
hold on
plot([means.interventionAfternoon,means.interventionAfternoon],h.YLim,'LineWidth',2)
plot([medians.interventionAfternoon,medians.interventionAfternoon],h.YLim,'LineWidth',2)
hold off
legend('data','mean','median')


saveas(f, plotPath);

close(f)

summary = table;
% summary.Properties.RowNames = {'Baseline_Morning','Baseline_Afternoon','Intervention_Morning','Intervention_Afternoon'};
% summary.Mean = vertcat(mean(

end

