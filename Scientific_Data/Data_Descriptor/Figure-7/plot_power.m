function plot_power
%% About plot_power
%
% This script can be used to plot power values generated using IMOS
% basoop.jar. The maximum value of instantaneous power (dB re 1 W) received
% within 0-1 m range can be a diagnostic tool to monitor system performance
% over time.
%
%% Precondition
%
%   o The power.csv input files should be created using IMOS basoop.jar,
%   else change headers to conform. There should not be any other csv files
%   in the folder other than power.csv.
%
%   o Download basoop.jar from: https://github.com/CSIRO-Acoustics/IMOS-Bioacoustics/tree/main/IMOS_data_management_tools
%
%% Author
%
%   Haris Kunnath <2020-01-13>

%% Read data 

time_vector = [];
power = [];

data_folder = uigetdir('Q:\','Select power.csv data folder');  % power.csv folder

files = dir(fullfile(data_folder,'*power.csv'));

for i = 1 : length(files)
    fprintf(1, 'Now reading %s (%d/%d)\n', files(i).name,i,length(files));
    
    try
        data = readtable(fullfile(data_folder,files(i).name),'header',0); % failing with Matlab R2020a
    catch
        data = readtable(fullfile(data_folder,files(i).name),'VariableNamesLine',1,'Delimiter',',');
    end    
    
    data_time = datenum(data.Date + data.Time + data.Millisecond/(1000*24*3600)); % convert to date number
    data_power = data.MaxPower;
    
    time_vector = [time_vector; data_time];
    power = [power; data_power];
end
%% Plot data

sz = 20; % size of scatter symbol
flag = 0; % flag outlier - do not plot below this (dB)

figure;
ps = get(0,'ScreenSize');
set(gcf,'Position',[50 50 ps(3)*0.85 ps(4)*0.70]) % control figure size

scatter(time_vector(power>flag), power(power>flag), sz, power(power>flag), 'filled')
colorbar;

xlabel('Date')
ylabel('Peak values of instantaneous received power between 0-1 m range (dB re 1 W)')
datetick('x',29,'keepticks') % change Numeric Identifier to change Date and Time Format see: https://au.mathworks.com/help/matlab/ref/datetick.html  
set(gca,'XMinorTick','on','YMinorTick','on')
set(gca,'TickDir','out');
xtickangle(-20)
box on; grid on
% xlim([min(time_vector) max(time_vector)])
end