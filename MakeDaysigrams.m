% Reset matlab
close all
clear
clc

exportDir = '\\ROOT\projects\GSA_Daysimeter\GSA US Embassy\Reykjavik\Daysimeter_Data\daysigrams';

% Load data
data = loadData;

n  = numel(data);

timestamp = upper(datestr(now,'mmmdd'));

for iObj = 1:n
    thisObj = data(iObj);
    
    if isempty(thisObj.Time)
        continue
    end
    
    titleText = {'GSA - US Embassy in Reykjavik';['ID: ',thisObj.ID,', Device SN: ',num2str(thisObj.SerialNumber)]};
    
    d = d12pack.daysigram(thisObj,titleText);
    
    for iFile = 1:numel(d)
        d(iFile).Title = titleText;
        
        fileName = [thisObj.ID,'_',timestamp,'_p',num2str(iFile),'.pdf'];
        filePath = fullfile(exportDir,fileName);
        saveas(d(iFile).Figure,filePath);
        close(d(iFile).Figure);
        
    end
end
