%% About figure12
%
% Figure 12 in data descriptor paper using viz_sv.
%
%% Precondition
%
%   o Require viz_sv in the path.
%   o Download viz_sv: https://github.com/CSIRO-Acoustics/Visualize-IMOS-Bioacoustics-data
%   o Download viz_sv: https://github.com/CSIRO-Acoustics/IMOS-Bioacoustics
%   o Written for Matlab R2019b or latest
%
%% Author
%
%   Haris Kunnath <2020-07-06>

%% Read data

try
    data = viz_sv("Z:\Publications\journal-papers\Year2020\Scientific_Data\Data_Descriptor\2.Draft\Figures\Figure12\Supporting_files\Data\IMOS_SOOP-BA_AE_20180818T084717Z_E5WW_FV02_Will-Watch-ES60-38_END-20180822T104611Z_C-20190716T081531Z.nc",[],'noplots','all');
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
t = tiledlayout(5,3); % Requires R2019b or later
% t.Padding = 'none';
% t.TileSpacing = 'compact';
set(gcf,'color','white')
set(gcf,'position',[1071,300,796,980])

depth_bin = ceil(data.depth./100)*100;
[C,~,ic] = unique(depth_bin);
limit = [datenum('2018-08-18 10:00') datenum('2018-08-22 10:00')];

% Title: Sv filtered
ax1 = nexttile(1,[1 3]);
uncorrected_Sv = data.uncorrected_Sv;
uncorrected_Sv(uncorrected_Sv == -999) = NaN;
imagesc(data.time,data.depth,uncorrected_Sv,[min_sv max_sv])
ylabel('Depth (m)')
title('Uncorrected mean \it{S_v}')
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

% Title: Sv corrected
ax2 = nexttile(4,[1 3]);
imagesc(data.time,data.depth,data.abs_Sv,[min_sv max_sv])
title('Corrected mean \it{S_v}')
ylabel('Depth (m)')
set(gca,'TickDir','out')
% set(gca,'TickLength',[0.0200 0.0500])
c = colorbar;
c.Label.String = 'dB re 1 m^2 m^-^3';
% c.Location = 'southoutside';
% c.Label.FontSize = 10;
c.TickDirection = 'out';
ax2.Colormap = EK500cmap;
datetick('x',29)
xlim(limit)

% Title: difference due to secondary correction
ax3 = nexttile(7,[1 3]);
difference = data.uncorrected_Sv - data.abs_Sv;
imagesc(data.time,data.depth,difference,[0 2])
xlabel('Date (UTC)')
ylabel('Depth (m)')
title('Difference in mean \it{S_v}')
set(gca,'TickDir','out')
% set(gca,'TickLength',[0.0200 0.0500])
c = colorbar;
c.Label.String = 'dB re 1 m^2 m^-^3';
% c.Location = 'southoutside';
% c.Label.FontSize = 10;
c.TickDirection = 'out';
try
    ax3.Colormap = cmocean('amp',10);
catch
    warning ('Try using cmocean from: https://au.mathworks.com/matlabcentral/fileexchange/57773-cmocean-perceptually-uniform-colormaps')
    ax3.Colormap = EK500cmap;
end
datetick('x',29)
xlim(limit)

% Title: sound speed
ax4 = nexttile(10,[2 1]);
hold(ax4);
plotx = 1:1:length(C);

soundspeed = cummean(data.soundspeed); % take cummean for figure

% Color for boxplot
n = length(C);
color = cat(2,linspace(0.6,0,n)',linspace(0.8,0.2,n)',linspace(1,0.6,n)');
colorss = flipud(color);

for i = 1:length(plotx)
    ploty = soundspeed(ic==i,:);
    plotyv(:,i) = ploty(:);
    boxchart(plotx(i)*ones(size(plotyv(:,i))), plotyv(:,i),...
        'BoxFaceColor', colorss(i,:),'MarkerStyle','+','MarkerColor','#D95319','orientation','horizontal');
end

xline(1500,'-','Nominal','Color','#77AC30','LineWidth',1.2,'LabelHorizontalAlignment','left','LabelOrientation','aligned');
xlabel({'Cumulative mean','sound speed (m s^{-1})'})
ylabel('Depth (m)')
title ('Mackenzie, 1981')
box on; grid on
set(gca,'YDir','reverse')
set(gca,'TickDir','out')
set(gca,'TickLength',[0.0200 0.0500])
ylim([0 max(plotx)+1])
xlim([1495 1540])

YTickLabel = ax4.YTickLabel;
for i = 1:length(YTickLabel)
    ax4.YTickLabel(i) = {str2double(cell2mat(YTickLabel(i)))*100};
end

% Title: absorption coefficient
ax5 = nexttile(11,[2 1]);
hold(ax5);
plotx = 1:1:length(C);

absorption_linear = 10.^(data.absorption/10); % convert to linear for cummean calculation
abs_cmeanlinear = cummean(absorption_linear); % take cummean for figure
absorption = 10*log10(abs_cmeanlinear); % take log

for i = 1:length(plotx)
    ploty = absorption(ic==i,:);
    plotyv(:,i) = ploty(:);
    boxchart(plotx(i)*ones(size(plotyv(:,i))), plotyv(:,i),...
        'BoxFaceColor', color(i,:),'MarkerStyle','+','MarkerColor','#D95319','orientation','horizontal');
end

xline(0.00974,'-','Nominal','Color','#77AC30','LineWidth',1.2,'LabelHorizontalAlignment','left','LabelOrientation','aligned');
xlim([0.007 0.01])
xlabel({'Cumulative mean','absorption coefficient (dB m^{-1})'})
title('Francois and Garrison, 1982')
box on; grid on
set(gca,'YDir','reverse')
set(gca,'TickDir','out')
set(gca,'TickLength',[0.0200 0.0500])
ax5.XAxis.Exponent = 0; % No exponent label
ylim([0 max(plotx)+1])

YTickLabel = ax5.YTickLabel;
for i = 1:length(YTickLabel)
    ax5.YTickLabel(i) = {str2double(cell2mat(YTickLabel(i)))*100};
end

%Title: Box plot showing percentage correction
ax6 = nexttile(12,[2 1]);
percentage = 100*(10.^(difference/10))-100;
hold(ax6);
plotx = 1:1:length(C);

for i = 1:length(plotx)
    ploty = percentage(ic==i,:);
    plotyv(:,i) = ploty(:);
    boxchart(plotx(i)*ones(size(plotyv(:,i))), plotyv(:,i),'BoxFaceColor', color(i,:),'BoxFaceAlpha',0.5,...
        'MarkerStyle','+','orientation','horizontal');
end

xlabel({'Percentage','correction to mean {\itS_v} (%)'})
title('Percentage correction')
box on; grid on
set(gca,'YDir','reverse')
set(gca,'TickDir','out')
set(gca,'TickLength',[0.0200 0.0500])
ylim([0 max(plotx)+1])
xlim([-5 60])

YTickLabel = ax6.YTickLabel;
for i = 1:length(YTickLabel)
    ax6.YTickLabel(i) = {str2double(cell2mat(YTickLabel(i)))*100};
end

function y = cummean(x,dim)
%CUMMEAN   Average cumulative mean.
%   For vectors, CUMMEAN(X) is the cumulative mean value of the elements in X.
%   For matrices, CUMMEAN(X) is a matrix containing the mean cumulative value of
%   each column.  For N-D arrays, CUMMEAN(X) is the mean cumulative value of the
%   elements along the first non-singleton dimension of X.
%
%   CUMMEAN(X,DIM) takes the cummulative mean along the dimension DIM of X.
%
%   Example: If X = [0 1 2
%                    3 4 5]
%
%   then cummean(X,1) is   [  0   1   2
%                           1.5 2.5 3.5]
%   and cummean(X,2)  is   [  0 0.5   1
%                             3 3.5   4]
%
%   Another example:
%   Calculate the cumulative mean of an uniform random vector
%   in order to estimate its mean (0.5).
%
%   y = rand(100,1);
%   plot(y,'bo:'); hold on; plot(cummean(y),'r-');
%
%   See also CUMSUM, MEAN, MEDIAN, STD, MIN, MAX, COV.

%   Copyright (c) 2001-2015 by Leandro G. Barajas
%   Based on CUMSUM by Mathworks
%   $Revision: 1.1 $  $Date: 03/01/15 11:46:56 $

if nargin==1
    % Determine which dimension CUMSUM./[1:N] will use
    dim = min(find(size(x) ~= 1));
    if isempty(dim), dim = 1; end
end

siz = [size(x) ones(1, dim-ndims(x))];
n = size(x, dim);

% Permute and reshape so that DIM becomes the row dimension of a 2-D array
perm = [dim:max(length(size(x)), dim) 1:dim-1];
x = reshape(permute(x, perm), n, prod(siz)/n);

% Calculate cummulative mean
y = cumsum(x, 1)./repmat([1:n]', 1, prod(siz)/n);

% Permute and reshape back
y = ipermute(reshape(y, siz(perm)), perm);
end
