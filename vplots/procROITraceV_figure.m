clear all;
close all;
%{
procROITrace_figure_z.m
(for Vanessa's strobe data)
produces data plots from neuropil data for a specified frequency
fig.1 is comparison of raw(blue) and detrended(orange) trace
fig.2 is closeup of 1 minute of raw detrended trace with strobe times
    **2 orange lines are scale bars for 1% dfof and 5 secs
fig.3 is a selected figure plot (use matlab figure window manu to save this plot; save 
trace or power plots as pdf, spectrograms as png)
    **in raw trace plot: 2 orange lines are scale bars for 1% dfof and 1 min
%}

%input root folder
rootfolder = 'E:\CoconutTree\M1\Data\Taddata-2020';

%select type of plot to show in fig.3
 plottype = 'trace';   %raw detrended trace (shows strobe period only, 2 orange lines are scale bars for 1% dfof and 1 min)
% plottype = 'spect';   %spectrogram
% plottype = 'power';     %power plot

%fill in experiment info (uncomment the relevant experiment id#)
date = '20200627';
animal = 'Bodhi';
%idnum = 1220;  %Bodhi 1/16Hz
idnum = 1348;  %Bodhi 1Hz

% date = '20200628';
% animal = 'Chanda';
% idnum = 1927; %1/16Hz
% idnum = 2106; %1Hz

% date = '20200628';
% animal = 'Deva';
% idnum = 2600; %1/16Hz
% idnum = 2720; %1Hz

%select detrending method
%note: polynomial detrending will only work for 2019a and later
detrending = 'poly';   %polynomial
 detrending = 'hp';   %highpass filter
% detrending = 'none'; %no detrending

%parameters for zoomed plot
zoomstart = 960;%starting frame of zoomed in trace

%dfof/detrending parameters
basepctl = 20;  %base percentile for dfof
polydeg = 4;    %degree for polynomial detrending
hpf = 0.003;    %highpass filter frequency

savedetrend = 0;    %save detrended trace as mat file (will replace any existing file)
readdetrend = 0;    %read detrended trace from a file
loadxls = 0;    %just in case: kept option to input trace from excel file

%--------------------

id = num2str(idnum);

experiment = ['Exp_' id];
procfolder = [rootfolder '\Proc_' date];
metafolder = fullfile(procfolder,['strobeROI_' date]);
metaname = ['metadata_' experiment '.mat'];
dtfolder = fullfile(procfolder,['detrend_' date]);
detrendname = ['detrend_' experiment '_' detrending '.mat'];
detrendfile = fullfile(dtfolder,detrendname);

if ~exist(dtfolder,'dir')
    mkdir(dtfolder);
end


load(fullfile(metafolder,metaname));

if loadxls
    tracexls = fullfile(procfolder,'traces',['neuropil_' experiment '.xlsx']);
    trace_neuropil = transpose(xlsread(tracexls));
else
    loadname = ['trace_neuropil_' experiment '.mat'];
    load(fullfile(metafolder,loadname));
end


%find capture rate from average spacing in frame time
ftimes_disp = ftimes(2:end);
ftimes_space = ftimes_disp - ftimes(1:(end-1));
Fs = 1/mean(ftimes_space);


rawtrace = trace_neuropil;


%perform dfof: baseline = percentile of response
f0 = prctile(rawtrace,basepctl);
dfoftrace = (rawtrace-f0)/f0;

%cut out strobe trace and detrend
strobetraceraw = dfoftrace(dataframe.strobestart:dataframe.strobeend);

if readdetrend
    load(detrendfile);
else

    if strcmp(detrending,'poly')
        strobetrace = detrend(strobetraceraw,polydeg);
    elseif strcmp(detrending,'hp')
        strobetrace = highpass(strobetraceraw,hpf,Fs);
    else
        strobetrace = strobetraceraw;
    end
    
end

%

img1 = figure(1);
set(img1,'position',[50 400 800 200]);
plot(strobetraceraw);
hold on
plot(strobetrace);
hold off;
framenums = 1:length(ftimes);
nminticks = floor(length(ftimes)/(Fs*60));
minticks = (1:nminticks).*(Fs*60);
xticks(minticks);
minticklabels = cell(nminticks);
for k=1:nminticks
    minticklabels{k} = num2str(k);
end
xticklabels(minticklabels);
xlabel('Time (minutes)');

img2 = figure(2);
set(img2,'position',[75 300 800 200]);
plot(strobetrace(zoomstart:(zoomstart+900)));
hold on;
nticks = ceil(60*setup.strobefreq);
for i=1:nticks
    scatter((i-1)*(1/setup.strobefreq)*Fs,0.03,[],'k','v','filled');
end
plot([920 920],[0.02 0.03]);
plot([920 920+Fs*5],[0.02 0.02]);
hold off;
ylim([-0.02 0.04]);
axis off;

img3 = figure(3);
set(img3,'position',[100 200 800 200]);

if strcmp(plottype,'trace')
    plot(strobetrace);
    hold on
    plot([1000 1000],[0.03 0.04]);
    plot([1000 1900],[0.03 0.03]);
    hold off
    ylim([-0.02 0.04]);
    axis off;
end

if strcmp(plottype,'spect')
    pspectrum(strobetrace,Fs,'spectrogram','MinThreshold',-120,'FrequencyResolution',0.2);
    caxis([-110,-30]);
    ax = gca;
    ax.YScale = 'log';
    yticks([1/16,1/8,1/4,1/2,1,2,4,8]);
end


if strcmp(plottype,'power')
    pspectrum(strobetrace,Fs,'power');
    set(gca, 'XScale', 'log')
    hold on;
    freqs = [1/16 1/8 1/4 1/2 1 2 4];
    for i=1:length(freqs)
        xpoint = freqs(i);
        freqline = plot([xpoint xpoint],ylim,'r');
        freqline.Color(4) = 0.25;
    end
    xticks(freqs);
    
    hold off;
end

if savedetrend
    save(detrendfile, 'strobetrace', 'detrending');
end





%%

