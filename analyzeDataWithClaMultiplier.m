function analyzeDataWithClaMultiplier
%ANALYZEDATA Summary of this function goes here
%   Detailed explanation goes here
timestamp = datestr(now,'yyyy-mm-dd HH-MM');

[githubDir,~,~] = fileparts(pwd);
d12packDir = fullfile(githubDir,'d12pack');
addpath(d12packDir);

projectDir = '\\ROOT\projects\GSA_Daysimeter\StateDepartment_2017\Daysimeter_Data';
saveDir = fullfile(projectDir,'tables');

objArray = loadData;

nObj = numel(objArray);
h = waitbar(0,'Please wait. Analyzing data...');
rn1 = datestr(datetime(0,0,0,0,0,0):duration(1,0,0):datetime(0,0,0,23,0,0),'HH:MM - ');
rn2 = datestr(datetime(0,0,0,1,0,0):duration(1,0,0):datetime(0,0,0,24,0,0),'HH:MM');
RowNames = cellstr([rn1,rn2]);
RowNames = [RowNames;{'Mean'}];

IDs = matlab.lang.makeUniqueStrings({objArray.ID}');

[IDs,I] = sort(IDs);

for iObj = 1:nObj
    
    obj = objArray(I(iObj));
    
    
    %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
    % Apply Multipliers to CLA (x2 & x3) then recompute CS
    % x2
    obj.UserData.CLAx2 = obj.CircadianLight*2;
    obj.UserData.CSx2 = obj.cla2cs(obj.UserData.CLAx2);
    % x3
    obj.UserData.CLAx3 = obj.CircadianLight*3;
    obj.UserData.CSx3 = obj.cla2cs(obj.UserData.CLAx3);
    %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
    
    idxKeep = obj.Observation & obj.Compliance & ~obj.Error & ~obj.InBed;
    
    if ~any(idxKeep)
        continue
    end
    
    t = obj.Time(idxKeep);
    CLAx2 = obj.UserData.CLAx2(idxKeep);
    CSx2  = obj.UserData.CSx2(idxKeep);
    CLAx3 = obj.UserData.CLAx3(idxKeep);
    CSx3  = obj.UserData.CSx3(idxKeep);
    
    date0 = dateshift(t(1),'start','day');
    dateF = dateshift(t(end),'start','day');
    dates = date0:calendarDuration(0,0,1):dateF;
    
    nDates = numel(dates);
    tb = array2table(nan(25,nDates));
    tb.Properties.VariableNames = cellstr(datestr(dates,'mmm_dd_yyyy'));
    tb.Properties.RowNames = RowNames;
    
    CLAx2TB = tb;
    CSx2TB  = tb;
    CLAx3TB = tb;
    CSx3TB  = tb;
    
    CLAx2TB.Properties.DimensionNames{1} = 'CLAx2';
    CSx2TB.Properties.DimensionNames{1}  = 'CS(CLAx2)';
    CLAx3TB.Properties.DimensionNames{1} = 'CALx3';
    CSx3TB.Properties.DimensionNames{1}  = 'CS(CLAx3)';
    
    for iCol = 1:nDates
        for iRow = 1:24
            idx = t >= (dates(iCol)+duration(iRow-1,0,0)) & t < (dates(iCol)+duration(iRow,0,0));
            
            if any(idx)
                CLAx2TB{iRow,iCol} = mean(CLAx2(idx));
                CSx2TB{iRow,iCol}  = mean(CSx2(idx));
                CLAx3TB{iRow,iCol} = mean(CLAx3(idx));
                CSx3TB{iRow,iCol}  = mean(CSx3(idx));
            end
            
        end
        
        idx = t >= dates(iCol) & t < (dates(iCol)+duration(24,0,0));
        CLAx2TB{25,iCol} = mean(CLAx2(idx));
        CSx2TB{25,iCol}  = mean(CSx2(idx));
        CLAx3TB{25,iCol} = mean(CLAx3(idx));
        CSx3TB{25,iCol}  = mean(CSx3(idx));
    end
    
    
    sheet = [obj.ID,'_',obj.Session.Name];
    
    CLAx2Name = [timestamp,' Mean CLAx2','.xlsx'];
    CLAx2Path = fullfile(saveDir,CLAx2Name);
    writetable(CLAx2TB,CLAx2Path,'Sheet',sheet,'WriteVariableNames',true,'WriteRowNames',true);
    
    CSx2Name = [timestamp,' Mean CS(CLAx2)','.xlsx'];
    CSx2Path = fullfile(saveDir,CSx2Name);
    writetable(CSx2TB,CSx2Path,'Sheet',sheet,'WriteVariableNames',true,'WriteRowNames',true);
    
    CLAx3Name = [timestamp,' Mean CLAx3','.xlsx'];
    CLAx3Path = fullfile(saveDir,CLAx3Name);
    writetable(CLAx3TB,CLAx3Path,'Sheet',sheet,'WriteVariableNames',true,'WriteRowNames',true);
    
    CSx3Name = [timestamp,' Mean CS(CLAx3)','.xlsx'];
    CSx3Path = fullfile(saveDir,CSx3Name);
    writetable(CSx3TB,CSx3Path,'Sheet',sheet,'WriteVariableNames',true,'WriteRowNames',true);
    
    waitbar(iObj/nObj);
end
close(h);


end

