function performTTests(VarName)
%ANALYZEDATA Summary of this function goes here
%   Detailed explanation goes here
timestamp = datestr(now,'yyyy-mm-dd HH-MM');

[githubDir,~,~] = fileparts(pwd);
d12packDir = fullfile(githubDir,'d12pack');
addpath(d12packDir);

projectDir = '\\ROOT\projects\GSA_Daysimeter\StateDepartment_2017\Daysimeter_Data';
saveDir = fullfile(projectDir,'tables');

% Load data
objArray = loadData;

nObj = numel(objArray);
h = waitbar(0,'Please wait. Analyzing data...');

IDs = matlab.lang.makeUniqueStrings({objArray.ID}');
[IDs,I] = sort(IDs);

tmpl = table;
tmpl.subject = {};
tmpl.date = {};
tmpl.hour = {};
tmpl.melanopic_CLA = zeros(0);

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
    
    tempMorning = tmpl;
    tempAfternoon = tmpl;
    for iDate = 1:nDates
        thisDate = datestr(dates(iDate),'mmm_dd_yyyy');
        for iHour = 7:11
            idx = t >= (dates(iDate)+duration(iHour,0,0)) & t < (dates(iDate)+duration(iHour+1,0,0));
            if any(idx)
                thisHour = {sprintf('%02u:00 - %02u:00',iHour,iHour+1)};
                thisValue =  mean(value(idx));
                tempMorning = vertcat(tempMorning, {thisSubject,thisDate,thisHour,thisValue} );
            end
        end
        
        for iHour = 14:16
            idx = t >= (dates(iDate)+duration(iHour,0,0)) & t < (dates(iDate)+duration(iHour+1,0,0));
            if any(idx)
                thisHour = {sprintf('%02u:00 - %02u:00',iHour,iHour+1)};
                thisValue =  mean(value(idx));
                tempAfternoon = vertcat(tempAfternoon, {thisSubject,thisDate,thisHour,thisValue} );
            end
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

xslxPath = fullfile(saveDir, [timestamp,' ',VarName,' for t-Test.xlsx']);
writetable(baselineMorning, xslxPath, 'Sheet', 'baselineMorning');
writetable(interventionMorning, xslxPath, 'Sheet', 'interventionMorning');
writetable(baselineAfternoon, xslxPath, 'Sheet', 'baselineAfternoon');
writetable(interventionAfternoon, xslxPath, 'Sheet', 'interventionAfternoon');


end

