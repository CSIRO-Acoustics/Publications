function vessel_contribution
%% About vessel_contribution
%
% To check IMOS data delivery contribution by each participating vessel for
% each year. All information can be obtained from the INF file generated
% for each NetCDF. See function 'create_inf' if there are no INF generated.
%
%% Syntax for usage
%
%   o vessel_contribution
%
%% Acknowledgement
%
% Read INF function is based on Gordon's code available at
% Q:\MATLAB_codes_basoop\register_raw_data_for_IMOS
%
%% Author
%
%   Haris Kunnath <2020-04-24>

%% Read INF data

data_folder = uigetdir('Q:\Generic_data_sets','Select INF data folder');  % INF folder

files = dir(fullfile(data_folder,'*.inf'));

% create empty data structure
data.ship = {};
data.distance = [];
data.year = [];

% read INf and populate data structure
for i = 1 : length(files)
    fprintf(1, 'Now reading %s (%d/%d)\n', files(i).name,i,length(files));    
    meta = read_inf_info([],fullfile(files(i).folder, files(i).name));
    data.ship = [data.ship; meta.vessel];
    data.distance = [data.distance; meta.distance];
    data.year = [data.year; str2double(meta.voyage_start_date(1:4))];
end

%% Plot total distance covered by each vessel for each year

ps = get(0,'ScreenSize');

% plot box plot of distance covered by vessel - uncomment if needed

% if license('test','statistics_toolbox') % try box plot
%     figure;
%     set(gcf,'Color','w')
%     set(gcf,'Position',[50 50 ps(3)*0.85 ps(4)*0.70]) % control figure size
%     boxplot(data.distance, data.ship)
%     ylabel('Distribution of distance covered (km)')
%     set(gca,'TickDir','out');
%     set(gca,'fontsize',12)
%     xtickangle(-15)
%     box on; grid on
% else % if box plot is not available
%     warning('No box plot for distribution of distance covered (km)')    
% end

% plot stacked bar graph
year_u = unique(data.year,'sorted'); % get sorted unique years 
ship_u = unique(data.ship,'sorted'); % get sorted unique ship names

table = zeros(numel(ship_u),numel(year_u)); % create a table with rows = ship name in alphabetical order; and columns = years in ascending order 

for i = 1:length(ship_u)
    distance = data.distance(~cellfun('isempty',regexp(data.ship,ship_u(i)))); % get distance values for a particular ship
    year = data.year(~cellfun('isempty',regexp(data.ship,ship_u(i)))); % get years for a particular ship
    year_u_p = unique(year,'sorted'); % get sorted years for a particular ship
    
    for j = 1:length(year_u_p)
        distance_year = sum(distance(year == year_u_p(j))); % get sum of distance for each year
        idx = find(year_u == year_u_p(j)); % find column index for writing to table
        table(i,idx) = distance_year; % write sum of distance to table, were 'i' is varied for each ship and 'idx' is varied for each year
    end    
end

X = categorical(ship_u); % create categorical array for plotting X axis based on ship name

EK500cmap = EK500colourmap(); % EK500 color map to replace Matlab's default 
EK80cmap = EK80colourmap(); % EK80 color map to replace Matlab's default 

figure;
set(gcf,'Color','w')
set(gcf,'Position',[50 50 ps(3)*0.85 ps(4)*0.70]) % control figure size
H = bar(X,table,'stacked');

for k = 1:numel(year_u)
    if length(year_u) < length(EK500cmap) % use EK500 color map
        if k ==1
            warning('Replacing Matlab default color with EK500 color map')
        end        
        H(k).FaceColor = EK500cmap(k+1,:); % exclude white
    else
        if k ==1
            warning('Replacing Matlab default color with EK80 color map')            
        end        
        incr = floor(length(EK80cmap)/length(year_u)); % use EK80 reshaped color map
        EK80cmap_a = EK80cmap(1:incr:end,:);
        H(k).FaceColor = EK80cmap_a(k,:);
    end    
end

ylabel('Total distance covered (km)')
set(gca,'TickDir','out');
set(gca,'fontsize',12)
box on; grid on
Ax = gca;
Ax.YAxis.Exponent = 0; % No exponent label 
legend(num2str(year_u),'Location','northeastoutside','Orientation','vertical')

% display total distance at the tips of bar
xtips = H(end).XEndPoints;
ytips = H(end).YEndPoints;
text(xtips,ytips,string(sum(table,2)),'HorizontalAlignment','center',...
    'VerticalAlignment','bottom')

% display table
T = array2table(table);
T.Properties.VariableNames = cellstr(num2str(year_u));
T.Properties.RowNames = ship_u;
T.Total = sum(T{:,1:end},2); % add vessel total as new column
T.Properties.VariableNames{end} = 'Vessel Total (km)';

Tnew = array2table(sum(T{:,1:end},1)); % new table to get year total
Tnew.Properties.VariableNames = T.Properties.VariableNames;
Tnew.Properties.RowNames{1} = 'Year Total (km)';

Tdisp = [T;Tnew]; % concatenate 2 tables

disp(Tdisp);

f = figure;
set(gcf,'Position',[50 50 ps(3)*0.6 ps(4)*0.4])
uitable(f,'Data',Tdisp{:,:},'ColumnName',Tdisp.Properties.VariableNames,...
    'RowName',Tdisp.Properties.RowNames,'Position',[70 80 1300 400]);
end

%% Read metadata from INF files

function meta = read_inf_info(meta, inf_file)
% Read an .inf file for the voyage and return voyage metadata.
%
% Inputs:
%   meta        structure containing metadata, may be empty
%   inf_file    full path to voyage information file (.inf for whole voyage)
%
% Outputs:
%   meta        structure containing metadata
%

start = 0;
fin = 0;


% read inf file
fid    = fopen(inf_file, 'rt');

line = fgetl(fid);
while (ischar(line))
    if length(line) > 4
        switch line(1:4)
            
            case 'Vess'
                meta.vessel = sscanf(line, 'Vessel: %s%c%s%c%s');
                
            case 'Tota'
%                 time = sscanf(line, 'Total Time: %f hours');
%                 if ~isempty(time)
%                     meta.total_time = time;
%                 end
                distance = sscanf(line, 'Total Track Length: %f km');
                if ~isempty(distance)
                    meta.distance = distance;
                end
                
            case 'Star'
                start = 1;
            case 'End '
                fin = 1;
                
            case 'Time'
                if fin
                    meta.voyage_end_date = sscanf(line, 'Time: %s%c%s JD');
                elseif start
                    meta.voyage_start_date = sscanf(line, 'Time: %s%c%s JD');
                end
                
            case 'Lon:'
                if fin
                    endpos =  sscanf(line, 'Lon: %f Lat: %f');
                elseif start
                    startpos = sscanf(line, 'Lon: %f Lat: %f');
                end
                
            case 'Mini'
                lon = sscanf(line,'Minimum Longitude:%f Maximum Longitude: %f');
                lat = sscanf(line,'Minimum Latitude:%f Maximum Latitude: %f');
                if ~isempty(lon)
                    meta.voyage_geospatial_lon_min = lon(1);
                    meta.voyage_geospatial_lon_max = lon(2);
                end
                if ~isempty(lat)
                    meta.voyage_geospatial_lat_min = lat(1);
                    meta.voyage_geospatial_lat_max = lat(2);
                end
        end
    end
    line = fgetl(fid);
end

fclose(fid);
end

%% EK500 color map

function [EK500cmap] = EK500colourmap()

EK500cmap = [255   255   255   % white
    159   159   159   % light grey
    95    95    95   % grey
    0     0   255   % dark blue
    0     0   127   % blue
    0   191     0   % green
    0   127     0   % dark green
    255   255     0   % yellow
    255   127     0   % orange
    255     0   191   % pink
    255     0     0   % red
    166    83    60   % light brown
    120    60    40]./255;  % dark brown
end

%% EK80 color map

function [EK80cmap] = EK80colourmap()

EK80cmap = [156/255 138/255 168/255
    141/255 125/255 150/255
    126/255 113/255 132/255
    112/255 100/255 114/255
    97/255 88/255 96/255
    82/255 76/255 78/255
    68/255 76/255 94/255
    53/255 83/255 129/255
    39/255 90/255 163/255
    24/255 96/255 197/255
    9/255 103/255 232/255
    9/255 102/255 249/255
    9/255 84/255 234/255
    15/255 66/255 219/255
    22/255 48/255 204/255
    29/255 30/255 189/255
    36/255 12/255 174/255
    37/255 49/255 165/255
    38/255 86/255 156/255
    39/255 123/255 147/255
    40/255 160/255 138/255
    41/255 197/255 129/255
    37/255 200/255 122/255
    30/255 185/255 116/255
    24/255 171/255 111/255
    17/255 156/255 105/255
    10/255 141/255 99/255
    21/255 139/255 92/255
    68/255 162/255 82/255
    114/255 185/255 72/255
    161/255 208/255 62/255
    208/255 231/255 52/255
    255/255 255/255 42/255
    254/255 229/255 43/255
    253/255 204/255 44/255
    253/255 179/255 45/255
    252/255 153/255 46/255
    252/255 128/255 47/255
    252/255 116/255 63/255
    252/255 110/255 85/255
    252/255 105/255 108/255
    252/255 99/255 130/255
    252/255 93/255 153/255
    252/255 85/255 160/255
    252/255 73/255 139/255
    253/255 61/255 118/255
    253/255 48/255 96/255
    254/255 36/255 75/255
    255/255 24/255 54/255
    240/255 30/255 52/255
    226/255 37/255 51/255
    212/255 44/255 50/255
    198/255 51/255 49/255
    184/255 57/255 48/255
    176/255 57/255 49/255
    170/255 54/255 51/255
    165/255 51/255 54/255
    159/255 47/255 56/255
    153/255 44/255 58/255
    150/255 39/255 56/255
    151/255 31/255 45/255
    153/255 23/255 33/255
    154/255 15/255 22/255
    155/255 7/255 11/255];
end
