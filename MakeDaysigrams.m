% Reset matlab
close all
clear
clc

exportDir = '\\ROOT\projects\GSA_Daysimeter\StateDepartment_2017\Daysimeter_Data\daysigrams';

% Load data
data = loadData;

n  = numel(data);

timestamp = upper(datestr(now,'mmmdd'));

for iObj = 1:n
    thisObj = data(iObj);
    
    if isempty(thisObj.Time)
        continue
    end
    
    titleText = {'GSA - State Dept';['ID: ',thisObj.ID,' ',thisObj.Session.Name]};
    
    StartDate = dateshift(min(thisObj.Time(thisObj.Observation)),'start','day') - duration(24,0,0);
    EndDate = dateshift(max(thisObj.Time(thisObj.Observation)),'end','day') + duration(24,0,0);
    d = d12pack.daysigram(thisObj,titleText,StartDate,EndDate);
    
    for iFile = 1:numel(d)
        d(iFile).Title = titleText;
        
        fileName = [thisObj.ID,'_',thisObj.Session.Name,'_',timestamp,'_p',num2str(iFile),'.pdf'];
        filePath = fullfile(exportDir,fileName);
        saveas(d(iFile).Figure,filePath);
        close(d(iFile).Figure);
        
    end
end
