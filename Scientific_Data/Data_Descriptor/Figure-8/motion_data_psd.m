function motion_data_psd
%% About motion_data_psd
%
% This script can be used to plot Welch’s power spectral density (PSD) and
% Spectrogram of platform motion data i.e. pitch, roll, and angle off-axis.
%
%% Precondition
%
%   o The CSV input files should contain following fields and their headers
%   need to be as follows:
%   Pitch_date,Pitch_time,Pitch_milliseconds,Pitch_angle
%   Roll_date,Roll_time,Roll_milliseconds,Roll_angle 
%   Else change the code to adapt  
%
%% Acknowledgement
%
% Third party code for PSD and Spectrogram were sourced from:
% PSD: https://raw.githubusercontent.com/wojzaremba/active-delays/master/external_tools/eeglab11_0_4_3b/functions/octavefunc/signal/pwelch.m
% Spectrogram: https://au.mathworks.com/matlabcentral/fileexchange/45386-spectrogram
%
%% Author
%
%   Haris Kunnath <2019-06-17>
%                 <2020-04-26>

%% Select pitch and roll csv files

[file1, path1] = uigetfile('*.csv','Select pitch.csv file'); % select pitch file
if isequal(file1,0)
    error('pitch.csv file required');
end

[file2, path2] = uigetfile('*.csv','Select roll.csv file',path1); % select roll file
if isequal(file2,0)
    error('roll.csv file required');
end

fprintf(1, 'Now reading %s\n', file1);
data_p = readtable(fullfile(path1,file1),'Delimiter', ',');
fprintf(1, 'Now reading %s\n', file2);
data_r = readtable(fullfile(path2,file2),'Delimiter', ',');

date_n = datenum(data_p.Pitch_date + data_p.Pitch_time + data_p.Pitch_milliseconds/(1000*24*3600)); % convert to date number

angle_p = data_p.Pitch_angle; % read pitch angle
angle_p(angle_p>100 | angle_p<-100) = 0; % remove outliers setting to zero, note it can't be NaN

angle_r = data_r.Roll_angle; % read roll angle
angle_r(angle_r>100 | angle_r<-100) = 0; % remove outliers setting to zero, note it can't be NaN

angle_p_r = deg2rad(angle_p); % convert pitch from degrees to radians
angle_r_r = deg2rad(angle_r); % convert roll from degrees to radians

% Cartesian to polar coordinate conversion - 'theta' is the
% counterclockwise angle in the x-y plane measured in radians from the
% positive x-axis [-pi pi]. 'rho' is the distance from the origin to a
% point in the x-y plane,i.e. radial coordinate which is the angle
% off-axis. By convention, rho can't be negative for PSD analysis.
% However,any polar coordinate is identical to the coordinate with the
% negative radial component in the opposite direction (adding 180° to the
% polar angle). Therefore, the same point (rho, theta) can be expressed as
% (-rho, theta+180°) in the opposite direction. Negative 'rho' can be
% obtained by multiplying 'rho' with the 'sign' of 'theta' I believe.

[~,rho] = cart2pol(angle_p_r, angle_r_r); % transform Cartesian coordinates in radians to polar (angle off-axis) for PSD
% X axis - pitch Y axis - roll
% theta = atan2(y,x)
% rho = sqrt(x.^2 + y.^2)

% variable 'angle_offaxis_psd' below is subjet to PSD and spectrogram
% analysis
angle_offaxis_psd = rho; % off-axis angle for PSD

% variable 'angle' below is not subject to PSD and spectrogram analysis,
% only for plotting purpose
[theta1,rho1] = cart2pol(angle_p, angle_r); % using degrees angle for plotting (angle off-axis)
sign = theta1./abs(theta1); % sign vector containing ones, note this will put sign for rho, i.e. to get angle in opposite direction
angle = rho1.*sign; % for plotting angle off-axis

%% Plot pitch, roll, and off-axis angle

ps = get(0,'ScreenSize');

figure
set(gcf,'Position',[50 50 ps(3)*0.5 ps(4)*0.5])

if numel(unique(data_p.Pitch_date)) <= 2
    datetick_id = 31;
else
    datetick_id = 29;
end

subplot(3,1,1)
plot(date_n,angle_p,'LineWidth',1)
ylabel('Pitch (^o)')
datetick('x',datetick_id)
xlim([min(date_n) max(date_n)])
title(sprintf('Platform motion data'))
set(gca,'TickDir','out')
box on; grid on

subplot(3,1,2)
plot(date_n,angle_r,'LineWidth',1)
ylabel('Roll (^o)')
datetick('x',datetick_id)
xlim([min(date_n) max(date_n)])
set(gca,'TickDir','out')
box on; grid on

subplot(3,1,3)
plot(date_n,angle,'LineWidth',1)
ylabel('Roll (^o)')
datetick('x',datetick_id)
xlabel('Date')
ylabel('Angle off-axis (^o)')
xlim([min(date_n) max(date_n)])
set(gca,'TickDir','out')
box on; grid on

%% Compute and plot Welch’s power spectral density (PSD)

fs = 1/(24*3600*((date_n(end) - date_n(1))/length(date_n))); % calculate sample rate thanks to Tim
disp(['Motion data sample rate in Hz is: ' num2str(fs)]);

if license('test','signal_toolbox')
    % Note that 'mean' is removed from the data to avoid high PSD value at 0 Hz
    [Pxx_angle_offaxis,f_angle_offaxis] = pwelch(angle_offaxis_psd - mean(angle_offaxis_psd),2048,1024,2048,fs); % angle off-axis  
    [Pxx_pitch,f_pitch] = pwelch(angle_p_r - mean(angle_p_r),2048,1024,2048,fs); % pitch
    [Pxx_roll,f_roll] = pwelch(angle_r_r - mean(angle_r_r),2048,1024,2048,fs); % roll
    %                   pwelch(data,window,noverlap,nfft,sample rate)
else
    warning('Looks like you do not have Matlab signal processing toolbox, using third-party code')
    % Note that 'mean' is removed from the data in the third-party code 
    [Pxx_angle_offaxis,f_angle_offaxis] = pwelch_tp(angle_offaxis_psd,[],[],[],fs); % angle off-axis
    [Pxx_pitch,f_pitch] = pwelch_tp(angle_p_r,[],[],[],fs); % pitch
    [Pxx_roll,f_roll] = pwelch_tp(angle_r_r,[],[],[],fs); % pitch
end

% PSD for angle-offaxis
figure
plot(f_angle_offaxis,10*log10(Pxx_angle_offaxis),'LineWidth',1.5)
xlabel('Frequency (Hz)')
xlim([min(f_angle_offaxis) max(f_angle_offaxis)])
ylabel('PSD (dB re 1 rad^2 Hz^-^1)')
title(sprintf('Welch’s Power Spectral Density (PSD) for angle off-axis'))
set(gca,'TickDir','out')
box on; grid on

% PSD for pitch and roll
figure
plot(f_pitch,10*log10(Pxx_pitch),'LineWidth',1.5,'DisplayName','Pitch')
hold on
plot(f_roll,10*log10(Pxx_roll),'LineWidth',1.5,'DisplayName','Roll')
xlabel('Frequency (Hz)')
xlim([min(f_pitch) max(f_pitch)])
ylabel('PSD (dB re 1 rad^2 Hz^-^1)')
title(sprintf('Welch’s Power Spectral Density (PSD) for pitch and roll'))
set(gca,'TickDir','out')
legend
box on; grid on

%% Compute and plot Spectrogram using short-time Fourier transform

if license('test','signal_toolbox')
    [~,F_angle_offaxis,~,p_angle_offaxis] = spectrogram(angle_offaxis_psd,hamming(2048),1024,2048,fs,'yaxis'); % angle off-axis
    [~,F_pitch,~,p_pitch] = spectrogram(angle_p_r,hamming(2048),1024,2048,fs,'yaxis'); % pitch
    [~,F_roll,~,p_roll] = spectrogram(angle_r_r,hamming(2048),1024,2048,fs,'yaxis'); % roll
    %                     spectrogram(data,window,noverlap,nfft,sample rate)
else
    [B_angle_offaxis,F_angle_offaxis,~] = spectrogram_tp(angle_offaxis_psd,2048,fs,2048,1024); % angle off-axis
    p_angle_offaxis = abs(B_angle_offaxis/max(max(abs(B_angle_offaxis)))).^2; % spectrogram values to PSD
    
    [B_pitch,F_pitch,~] = spectrogram_tp(angle_p_r,2048,fs,2048,1024); % pitch
    p_pitch = abs(B_pitch/max(max(abs(B_pitch)))).^2; 
    
    [B_roll,F_roll,~] = spectrogram_tp(angle_r_r,2048,fs,2048,1024); % roll
    p_roll = abs(B_roll/max(max(abs(B_roll)))).^2;
end

% Spectrogram for angle-offaxis
figure
set(gcf,'Position',[50 50 ps(3)*0.5 ps(4)*0.4])
imagesc(date_n,F_angle_offaxis,10*log10(p_angle_offaxis))
xlabel('Date')
ylabel('Frequency (Hz)')
title(sprintf('Spectrogram for angle off-axis'))
datetick('x',datetick_id)
set(gca,'ydir','normal')
set(gca,'TickDir','out')
axis tight;
c = colorbar;
c.Label.String = 'dB re 1 rad^2 Hz^-^1';
c.Label.FontSize = 10;
c.TickDirection = 'out';
colormap(jet)

% Spectrogram for pitch
figure
set(gcf,'Position',[50 50 ps(3)*0.5 ps(4)*0.4])
subplot(2,1,1)
imagesc(date_n,F_pitch,10*log10(p_pitch))
xlabel('Date')
ylabel('Frequency (Hz)')
title(sprintf('Spectrogram for pitch'))
datetick('x',datetick_id)
set(gca,'ydir','normal')
set(gca,'TickDir','out')
axis tight;
c = colorbar;
c.Label.String = 'dB re 1 rad^2 Hz^-^1';
c.Label.FontSize = 10;
c.TickDirection = 'out';
colormap(jet)

% Spectrogram for roll
subplot(2,1,2)
imagesc(date_n,F_roll,10*log10(p_roll))
xlabel('Date')
ylabel('Frequency (Hz)')
title(sprintf('Spectrogram for roll'))
datetick('x',datetick_id)
set(gca,'ydir','normal')
set(gca,'TickDir','out')
axis tight;
c = colorbar;
c.Label.String = 'dB re 1 rad^2 Hz^-^1';
c.Label.FontSize = 10;
c.TickDirection = 'out';
colormap(jet)
end