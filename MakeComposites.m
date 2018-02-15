function MakeComposites
%MAKE Summary of this function goes here
%   Detailed explanation goes here

timestamp = datestr(now,'yyyy-mm-dd HH-MM');

% Enable dependencies
[githubDir,~,~] = fileparts(pwd);
d12packDir      = fullfile(githubDir,'d12pack');
addpath(d12packDir);

projectDir = '\\root\projects\GSA_Daysimeter\StateDepartment_2017\Daysimeter_Data';
dataDir = fullfile(projectDir,'cropped');
saveDir = fullfile(projectDir,'composites');

ls = dir([dataDir,filesep,'*.mat']);

for iFile = 1:numel(ls)
    dataName = ls(iFile).name;
    dataPath = fullfile(dataDir,dataName);
    load(dataPath);
    
    for iObj = 1:numel(objArray)
        thisObj = objArray(iObj);
        
        switch class(thisObj)
            case {'d12pack.HumanData', 'd12pack.MobileData'}
                if isempty(thisObj.Time)
                    continue
                end
                
                titleText = {'GSA - State Department';['ID: ',thisObj.ID,', Session: ',thisObj.Session.Name,', Device SN: ',num2str(thisObj.SerialNumber)]};
                
                c = d12pack.composite(thisObj,titleText);
                c.Title = titleText;
                
                fileName = [thisObj.ID,'_',thisObj.Session.Name,'_',timestamp,'.pdf'];
                filePath = fullfile(saveDir,fileName);
                saveas(c.Figure,filePath);
                close(c.Figure);
        end
    end
end


end

