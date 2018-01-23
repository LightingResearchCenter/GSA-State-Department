function data = loadData(varargin)
%LOADDATA Summary of this function goes here
%   Detailed explanation goes here

% Enable dependencies
[githubDir,~,~] = fileparts(pwd);
d12packDir      = fullfile(githubDir,'d12pack');
addpath(d12packDir);

if nargin >= 1
    projectDir = varargin{1};
else
    projectDir = '\\ROOT\projects\GSA_Daysimeter\StateDepartment_2017\Daysimeter_Data\cropped';
end

ls = dir([projectDir,filesep,'*.mat']);
if ~isempty(ls)
    [~,idxMostRecent] = max(vertcat(ls.datenum));
    dataName = ls(idxMostRecent).name;
    dataPath = fullfile(projectDir,dataName);
    
    d = load(dataPath);
    
    data = d.objArray;
else
    data = [];
end

end

