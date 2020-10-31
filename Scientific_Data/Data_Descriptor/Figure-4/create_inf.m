function create_inf
%% About create_inf
%
% This script can be used to create INF files from IMOS BASOOP NetCDFs
% using viz_sv. 
%
%% Precondition
%
%   o Require viz_sv in the path.
%   o Download viz_sv: https://github.com/CSIRO-Acoustics/Visualize-IMOS-Bioacoustics-data
%   o Download viz_sv: https://github.com/CSIRO-Acoustics/IMOS-Bioacoustics
%
%% Author
%
%   Haris Kunnath <2020-04-24>

%% Read data 

data_folder = uigetdir('Q:\Generic_data_sets','Select NetCDF data folder');  % NetCDF folder

files = dir(fullfile(data_folder,'*.nc'));

% Checking duplicate files to warn user
files_split = cellfun(@(x) extractBefore(x,'Z_C-'),{files.name},'UniformOutput',false)'; % cellfun to extract string before 'Z_C-' in file name
[~, ind] = unique(files_split);
duplicate_ind = setdiff(1:length(files_split), ind);

if ~isempty(duplicate_ind)
    for i = 1:length(duplicate_ind)
        warning('This file %s has duplicate?',files(duplicate_ind(i)).name)        
        warning('No INF for %s',files(duplicate_ind(i)).name)        
    end
    files = files(ind);
end

% create gps.csv and INF
for i = 1 : length(files)
    fprintf(1, 'Now reading %s (%d/%d)\n', files(i).name,i,length(files));
    
    viz_sv(fullfile(files(i).folder, files(i).name),[],'inf','noplot'); % to create gps.csv, and INF    
end
end