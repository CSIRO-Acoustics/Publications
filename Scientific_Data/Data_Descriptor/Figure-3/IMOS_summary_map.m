function IMOS_summary_map
%% About IMOS_summary_map
%
%  This function can read IMOS-NetCDF, primary production, and longhurst
%  files in the respective folders to generate a summary map of IMOS voyage
%  transects, superimposed on a satellite-derived map of net primary
%  productivity (averaged for the year selected) and the Longhurst oceanic
%  biogeographical provinces.
%
%% Syntax for usage
%
%       o IMOS_summary_map
%
%% Precondition
%
%       o Require Matlab mapping toolbox
%
%% Summary result
%
%  The total line km information of the published data will be displayed on
%  the screen. But note for distance calculation, treating files as single
%  frequency data.
%
%% Data source
%
%  The NPP data for different years can be downloaded from:
%  http://www.science.oregonstate.edu/ocean.productivity/standard.product.php
%
%  The Longhurst oceanic biogeographical provinces can be downloaded from:
%  http://www.marineregions.org/sources.php#longhurst
%
%% Author
%
%       Haris Kunnath <2017-02-22>
%       Updated on    <2020-04-14>

%% Select data folders

npp_folder = uigetdir('Q:\Generic_data_sets\primary_production','Select year'); % NPP
netcdf_folder = uigetdir('Q:\Generic_data_sets','Select NetCDF folder');  % NetCDF
longhurst_folder = uigetdir('Q:\Generic_data_sets','Select Longhurst folder'); % Longhurst

%% Read ocean colour data

% Get a list of all *.hdf files in the folder.
filePattern = fullfile(npp_folder, '*.hdf');
theFiles = dir(filePattern);

for i = 1 : length(theFiles)
    baseFileName = theFiles(i).name;
    fullFileName = fullfile(npp_folder, baseFileName);
    info = hdfinfo(fullFileName);
    fprintf(1, 'Now reading %s\n', baseFileName);
    try
        npp{i} = hdfread(fullFileName, '/npp', 'Index', {[1  1],[1  1],[2160  4320]});
    catch
        npp{i} = hdfread(fullFileName, '/npp', 'Index', {[1  1],[1  1],[1080  2160]});
    end      
end

allData = cat(3,npp{:});

% The max value goes up to 13K. Limit the value to get a good plot.
allData(allData == info.SDS(1).Attributes(16).Value) = NaN; % fill value to NaN
allData(allData < 0) = NaN;
allData(allData > 1000) = 1000;

data=nanmean(allData,3); % Average NPP for the whole year

% Generate Latitude\Longitude variables.
[r c] = size(npp{1,1});

for i=1:r
    lat(i) = 90 - (180/r)*((i-1)+0.5);
end

for j=1:c
    lon(j) = -180 + (360/c)*((j-1)+0.5);
end

%% Read bioacoustic data

% Get a list of all *.nc files in the folder.
filePattern = fullfile(netcdf_folder, '*.nc');
theFiles = dir(filePattern);

for i = 1 : length(theFiles)
    baseFileName = theFiles(i).name;
    fullFileName = fullfile(netcdf_folder, baseFileName);
    fprintf(1, 'Now reading %s\n', baseFileName);
    LATITUDE{i} = ncread(fullFileName,'LATITUDE');
    LONGITUDE{i} = ncread(fullFileName,'LONGITUDE');
end

%Finding the total line 'km'
for i = 1:length(LATITUDE)
    Length(i,1)=length(LATITUDE{1,i});
end

%% Generating the figure

figure

%The Map limit can be adjusted for better display
latlim = [-80 45];
lonlim = [10 -5];

% Different map projection can be used
% Eg: mercator, winkel, vgrint1

axesm('robinson','MapLatLimit',latlim,'MapLonLimit',lonlim,......
    'Frame','on','Grid','on','MeridianLabel','on','ParallelLabel','on')

surfm(lat,lon,data);
colormap('Jet');
axis off

%% Plot Longhurst oceanic biogeographical provinces

% Get a list of all *.shp files in the folder.
filePattern = fullfile(longhurst_folder, '*.shp');
theFiles = dir(filePattern);

for i = 1 : length(theFiles)
    baseFileName = theFiles(i).name;
    fullFileName = fullfile(longhurst_folder, baseFileName);
    fprintf(1, 'Now reading %s\n', baseFileName);
    LH = shaperead(fullFileName, 'UseGeoCoords', true);
end

for i = 1:length(LH)
    linem(LH(i).Lat,LH(i).Lon,'color','w', 'linewidth', 1)
end

%% Plot coastlines

load coastlines
patchm(coastlat, coastlon,[0.7 0.7 0.7])
setm(gca,'Origin',[0 195 0]) %The Map limit can be adjusted for better display

for i = 1:length(LATITUDE)
    linem(LATITUDE{1,i},LONGITUDE{1,i},'color','k', 'linewidth', 1.25)
end

c = colorbar;
year_label = strsplit(npp_folder,'\');
year = year_label{4};
c.Label.String = ['Annual primary production for ',year,' (mg C m^{-2} day^{-1})'];
c.Label.FontSize = 11;
c.Location = 'northoutside';
c.Position= [0.28 0.805 0.475 0.02];
% tightmap tight;

clc;

fprintf('The total line km is, %f.\n', ...
    (sum(Length)));
end

%% Average or mean value ignoring NaNs

function y = nanmean(x,dim)
% FORMAT: Y = NANMEAN(X,DIM)
%
%    Average or mean value ignoring NaNs
%
%    This function enhances the functionality of NANMEAN as distributed in
%    the MATLAB Statistics Toolbox and is meant as a replacement (hence the
%    identical name).
%
%    NANMEAN(X,DIM) calculates the mean along any dimension of the N-D
%    array X ignoring NaNs.  If DIM is omitted NANMEAN averages along the
%    first non-singleton dimension of X.
%
%    Similar replacements exist for NANSTD, NANMEDIAN, NANMIN, NANMAX, and
%    NANSUM which are all part of the NaN-suite.
%
%    See also MEAN

% -------------------------------------------------------------------------
%    author:      Jan Glascher
%    affiliation: Neuroimage Nord, University of Hamburg, Germany
%    email:       glaescher@uke.uni-hamburg.de
%
%    $Revision: 1.1 $ $Date: 2004/07/15 22:42:13 $

if isempty(x)
    y = NaN;
    return
end

if nargin < 2
    dim = min(find(size(x)~=1));
    if isempty(dim)
        dim = 1;
    end
end

% Replace NaNs with zeros.
nans = isnan(x);
x(isnan(x)) = 0;

% denominator
count = size(x,dim) - sum(nans,dim);

% Protect against a  all NaNs in one dimension
i = find(count==0);
count(i) = ones(size(i));

y = sum(x,dim)./count;
y(i) = i + NaN;
end