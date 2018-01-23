function varargout = ConvertData

clear
clc

addpath('C:\Users\jonesg5\Documents\GitHub\d12pack')
addpath('C:\Users\jonesg5\Documents\GitHub\circadian')

rootDir = '\\root\projects';
calPath = fullfile(rootDir,'DaysimeterAndDimesimeterReferenceFiles',...
    'recalibration2016','calibration_log.csv');

projectDir = '\\ROOT\projects\GSA_Daysimeter\StateDepartment_2017\Daysimeter_Data';
croppedDir = fullfile(projectDir,'cropped');
dataDir    = fullfile(projectDir,'original');
logDir     = fullfile(projectDir,'logs');

timestamp = datestr(now,'yyyy-mm-dd_HHMM');
dbName  = [timestamp,'.mat'];
dbPath  = fullfile(projectDir,'converted',dbName);

previousData = loadData(croppedDir);
if ~isempty(previousData)
    previousSubjects = {previousData.ID}';
else
    previousSubjects = {''};
end

datalogLs = dir(fullfile(dataDir,'*data.txt'));
datalogPaths = fullfile(dataDir,{datalogLs.name}');
loginfoPaths = regexprep(datalogPaths,'DATA\.txt','LOG.txt');
cdfPaths     = regexprep(datalogPaths,'-DATA\.txt','.cdf');

LocObj = d12pack.LocationData;
LocObj.BuildingName             = 'US Department of State';
LocObj.Street                   = '2201 C St NW';
LocObj.City                     = 'Washington, DC';
LocObj.Country                  = 'United States of America';
LocObj.Organization             = 'Department of State';
LocObj.Lattitude                =  38.8961946;
LocObj.Longitude                = -77.049669;

nFile = numel(datalogPaths);

sessionBaseline = struct('Name','baseline');
sessionIntervention = struct('Name','intervention');

% Convert files to objects
ii = 1
for iFile = 1:nFile
    obj = d12pack.HumanData;
    
    obj.CalibrationPath = calPath;
    obj.RatioMethod     = 'normal';
    obj.Location        = LocObj;
    obj.TimeZoneLaunch	= 'America/New_York';
    obj.TimeZoneDeploy	= 'America/New_York';
    
    % Import the original data
    obj.log_info = obj.readloginfo(loginfoPaths{iFile});
    obj.data_log = obj.readdatalog(datalogPaths{iFile});
    
    % Read CDF data
    try
    cdfData = daysimeter12.readcdf(cdfPaths{iFile});
    catch err
        display(err)
    end
    
    % Add ID
    obj.ID = cdfData.GlobalAttributes.subjectID;
    
    if ~any(ismember(obj.ID, previousSubjects))
        % Add object to array of objects (make duplicate of each file)
        objArray(ii*2,1)   = obj;
        objArray(ii*2-1,1) = obj;
        
        % Set session of coppied objects
        objArray(ii*2,1).Session = sessionBaseline;
        objArray(ii*2-1,1).Session = sessionIntervention;
        
        ii = ii + 1;
    end
end

% Add logs to objects seperate baseline and intervention with bounds
for iObj = 1:numel(objArray)
    thisLogDir  = fullfile(logDir,objArray(iObj).Session.Name, ['Subject ', objArray(iObj).ID]);
    thisBedLog  = fullfile(thisLogDir, ['bedLog_subject',  objArray(iObj).ID, '.xlsx']);
    thisWorkLog = fullfile(thisLogDir, ['workLog_subject', objArray(iObj).ID, '.xlsx']);
    
    if exist(thisBedLog, 'file') == 2
        objArray(iObj).BedLog = objArray(iObj).BedLog.import(thisBedLog,objArray(iObj).TimeZoneDeploy);
    else
        warning(['Subject ', objArray(iObj).ID, ' missing ', objArray(iObj).Session.Name, ' bed log.']);
    end
    
    if exist(thisWorkLog, 'file') == 2
        objArray(iObj).WorkLog = objArray(iObj).WorkLog.import(thisWorkLog,objArray(iObj).TimeZoneDeploy);
        
        objArray(iObj).Observation = objArray(iObj).Time >= objArray(iObj).WorkLog(1).StartTime & objArray(iObj).Time <= objArray(iObj).WorkLog(end).EndTime;
    else
        warning(['Subject ', objArray(iObj).ID, ' missing ', objArray(iObj).Session.Name, ' work log.']);
    end
end

if ~isempty(previousData)
    objArray = vertcat(previousData, objArray);
end

% Sort by subject and session
tmpSessions = vertcat(objArray(:).Session);
tmpTable = table({objArray(:).ID}',{tmpSessions(:).Name}','VariableNames',{'ID','Session'});
[~, idxSort] = sortrows(tmpTable,{'ID','Session'});
objArray = objArray(idxSort);

% Save converted data to file
save(dbPath,'objArray');

if nargout > 0
    varargout{1} = objArray;
end

end