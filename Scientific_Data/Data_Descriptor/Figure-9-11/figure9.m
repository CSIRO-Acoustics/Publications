%% About figure9
%
% Figure 9 in data descriptor paper using viz_sv.
%
%% Precondition
%
%   o Require viz_sv in the path.
%   o Download viz_sv: https://github.com/CSIRO-Acoustics/Visualize-IMOS-Bioacoustics-data
%   o Download viz_sv: https://github.com/CSIRO-Acoustics/IMOS-Bioacoustics
%
%% Author
%
%   Haris Kunnath <2020-07-05>

%% Read data

try
    data = viz_sv("Z:\Publications\journal-papers\Year2020\Scientific_Data\Data_Descriptor\2.Draft\Figures\Figure9\Supporting_files\Data\IMOS_SOOP-BA_AE_20180818T084717Z_E5WW_FV02_Will-Watch-ES60-38_END-20180822T104611Z_C-20190716T081531Z.nc",[],'noplots','all');
catch
    error('Download IMOS_SOOP-BA_AE_20180818T084717Z_E5WW_FV02_Will-Watch-ES60-38_END-20180822T104611Z_C-20190716T081531Z.nc from AODN Portal')
end

min_sv = -84;
range = 36;
max_sv = min_sv + range;

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

%% Plot data

figure
t = tiledlayout(5,1); % Requires R2019b or later
% t.Padding = 'none';
% t.TileSpacing = 'compact';
set(gcf,'color','white')
set(gcf,'position',[1071,300,796,900])

limit = [datenum('2018-08-18 10:00') datenum('2018-08-22 10:00')]; % for X axis

% Title 1: Calibrated and motion corrected raw data
ax1 = nexttile;
imagesc(data.time,data.depth,data.Svraw,[min_sv max_sv])
ylabel('Depth (m)')
title('Unfiltered mean \it{S_v}')
set(gca,'TickDir','out')
% set(gca,'TickLength',[0.0200 0.0500])
c = colorbar;
c.Label.String = 'dB re 1 m^2 m^-^3';
% c.Location = 'southoutside';
% c.Label.FontSize = 10;
c.TickDirection = 'out';
ax1.Colormap = EK500cmap;
datetick('x',29)
xlim(limit)

% Title 2: SNR
ax2 = nexttile;
imagesc(data.time,data.depth,data.snr,[0 40])
ylabel('Depth (m)')
title('Signal-to-noise ratio')
set(gca,'TickDir','out')
c = colorbar;
c.Label.String = 'dB re 1';
c.TickDirection = 'out';
try
    ax2.Colormap = flipud(cbrewer('div','RdBu',256,'linear'));
catch
    warning ('Try using cbrewer from: https://au.mathworks.com/matlabcentral/fileexchange/34087-cbrewer-colorbrewer-schemes-for-matlab')
    ax2.Colormap = jet;
end
datetick('x',29)
xlim(limit)

% Title 3: Background noise
ax3 = nexttile;
scatter(data.time(~isnan(data.background_noise)), data.background_noise(~isnan(data.background_noise)),10,data.background_noise(~isnan(data.background_noise)),'filled');
ylabel({'Background noise','(dB re 1 W)'})
title('Background noise')
ylim([-180 -150])
set(gca,'TickDir','out')
box on; grid on
c = colorbar;
c.Label.String = 'dB re 1 W';
c.TickDirection = 'out';
try
    ax3.Colormap = cmocean('balance');
catch
    warning ('Try using cmocean from: https://au.mathworks.com/matlabcentral/fileexchange/57773-cmocean-perceptually-uniform-colormaps')
    ax3.Colormap = jet;
end
caxis([-180 -160])
datetick('x',29)
xlim(limit)

% Title 4: Percentage good
ax4 = nexttile;
imagesc(data.time,data.depth,data.pg,[0 100])
ylabel('Depth (m)')
title('Percentage of {\it{S_v}} retained after filtering')
set(gca,'TickDir','out')
c = colorbar;
c.Label.String = 'Percentage (%)';
c.TickDirection = 'out';
try
    ax4.Colormap = flipud(cbrewer('div','RdBu',256,'linear'));
catch
    warning ('Try using cbrewer from: https://au.mathworks.com/matlabcentral/fileexchange/34087-cbrewer-colorbrewer-schemes-for-matlab')
    ax4.Colormap = jet;
end
datetick('x',29)
xlim(limit)

% Title 5: Filtered data
ax5 = nexttile;
uncorrected_Sv = data.uncorrected_Sv;
uncorrected_Sv(uncorrected_Sv == -999) = NaN;
imagesc(data.time,data.depth,uncorrected_Sv,[min_sv max_sv])
xlabel('Date (UTC)')
ylabel('Depth (m)')
title('Filtered mean \it{S_v}')
set(gca,'TickDir','out')
% set(gca,'TickLength',[0.0200 0.0500])
c = colorbar;
c.Label.String = 'dB re 1 m^2 m^-^3';
% c.Location = 'southoutside';
% c.Label.FontSize = 10;
c.TickDirection = 'out';
ax5.Colormap = EK500cmap;
datetick('x',29)
xlim(limit)

%% Statistics for Technical validation section

Svraw = data.Svraw(:,data.time>=datenum('2018-08-18 10:00') & data.time<=datenum('2018-08-22 10:00'));
filtered = uncorrected_Sv(:,data.time>=datenum('2018-08-18 10:00') & data.time<=datenum('2018-08-22 10:00'));
difference = Svraw-filtered;
difference_linear = 10.^(difference/10);
epipelagic = 10*log10(nanmean(difference_linear(3:20,:))); % Epipelagic layer
upper_mesopelagic = 10*log10(nanmean(difference_linear(21:40,:))); % Upper_mesopelagic layer
lower_mesopelagic = 10*log10(nanmean(difference_linear(41:80,:))); % Lower_mesopelagic layer

mean_epi = nanmean(epipelagic)
sd_epi = std(epipelagic,'omitnan')

mean_upper = nanmean(upper_mesopelagic)
sd_upper = std(upper_mesopelagic,'omitnan')

mean_lower = nanmean(lower_mesopelagic)
sd_lower = std(lower_mesopelagic,'omitnan')

SNR = 10.^(data.snr(:,data.time>=datenum('2018-08-18 10:00') & data.time<=datenum('2018-08-22 10:00'))/10);
SNR_epipelagic = 10*log10(nanmean(SNR(3:20,:))); % Epipelagic layer
SNR_upper_mesopelagic = 10*log10(nanmean(SNR(21:40,:))); % Upper_mesopelagic layer
SNR_lower_mesopelagic = 10*log10(nanmean(SNR(41:80,:))); % Lower_mesopelagic layer

SNR_mean_epi = nanmean(SNR_epipelagic)
SNR_sd_epi = std(SNR_epipelagic,'omitnan')

SNR_mean_upper = nanmean(SNR_upper_mesopelagic)
SNR_sd_upper = std(SNR_upper_mesopelagic,'omitnan')

SNR_mean_lower = nanmean(SNR_lower_mesopelagic)
SNR_sd_lower = std(SNR_lower_mesopelagic,'omitnan')

background = data.background_noise(data.time>=datenum('2018-08-18 10:00') & data.time<=datenum('2018-08-22 10:00'));
mean_backround = nanmean(background)
sd_background = std(background,'omitnan')

percentage_good = data.pg(:,data.time>=datenum('2018-08-18 10:00') & data.time<=datenum('2018-08-22 10:00'));
pg_mean_epi = nanmean(nanmean(percentage_good(3:20,:)))
pg_mean_upper = nanmean(nanmean(percentage_good(21:40,:)))
pg_mean_lower = nanmean(nanmean(percentage_good(41:80,:)))
