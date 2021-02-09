clear all;
close all;
%{
procROIspecV.m
find power at stim freqs (for neuropil)
%}

rootfolder = 'E:\CoconutTree\M1\Data\Taddata-2020';
% datelist = {'20200627','20200628','20200628'};
% animallist = {'Bodhi','Chanda','Deva'};
% idlist = [1220,1927,2600];  %1/16Hz
% idlist = [1348,2106,2720];  %1Hz

datelist = {'20200627'};
animallist = {'Bodhi'};
idlist = [1220];  %1/16Hz
idlist = [1348];  %1Hz

lowfreq = [0.058 0.066]; %1/16Hz
%lowfreq = [0.05 0.25]
hifreq = [0.9 1.1];      %1Hz

%select detrending method
%note: polynomial detrending will only work for 2019a and later
detrending = 'poly';   %polynomial
%detrending = 'hp';   %highpass filter
% detrending = 'none'; %no detrending

%dfof/detrending parameters
basepctl = 20;  %base percentile for dfof
polydeg = 4;    %degree for polynomial detrending
hpf = 0.003;    %highpass filter frequency

readdetrend = 1;    %read detrended trace from a file
ROIdataset = cell(1,length(animallist));


%--------------------

for countnames=1:length(animallist)
    procfolder = [rootfolder '\Proc_' datelist{countnames}];
    id = num2str(idlist(countnames));    
    experiment = ['Exp_' id];
    metafolder = fullfile(procfolder,['strobeROI_' datelist{countnames}]);
    metaname = ['metadata_' experiment '.mat'];
    outfolder = fullfile(procfolder,'results');
    dtfolder = fullfile(procfolder,['detrend_' datelist{countnames}]);
    detrendname = ['detrend_' experiment '_' detrending '.mat'];
    detrendfile = fullfile(dtfolder,detrendname);
    
    if ~exist(dtfolder,'dir')
        mkdir(dtfolder);
    end
    
    load(fullfile(metafolder,metaname));
    

    loadname = ['trace_neuropil_' experiment '.mat'];
    load(fullfile(metafolder,loadname));
    
    
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
    
    
    
    pw_early = mean(strobetrace(1:60*15));
    pw_late = mean(strobetrace((length(strobetrace)-60*15+1):length(strobetrace)));
    stroberatio = pw_late/pw_early;
    %disp(['Strobe rundown: ' num2str(stroberatio)]);
    
    %compare early vs late response to standard stims
    standtime = round((dataframe.pre(5)-dataframe.pre(1))*1.25);
    standearly = dfoftrace(dataframe.pre(1):(dataframe.pre(1)+standtime));
    standlate = dfoftrace(dataframe.post(1):(dataframe.post(1)+standtime));
    stimratio = mean(standlate)/mean(standearly);
    %disp(['Stim rundown: ' num2str(stimratio)]);
    
    ROIdataset{countnames}.dftraces = dfoftrace;
    ROIdataset{countnames}.T.stroberatios = stroberatio;
    ROIdataset{countnames}.T.stimratios = stimratio;
    ROIdataset{countnames}.dataframes = dataframe;
    ROIdataset{countnames}.strobetraces = strobetrace;
    
    
    
    
end



meanpowers = zeros(5,2);


img4 = figure(4);
set(img4,'position',[105 50 800 200]);

hold on
for countnames=1:length(animallist)
    ROIdata = ROIdataset{countnames};
    pspectrum(ROIdata.strobetraces,Fs,'power');
    [power,pfreqs] = pspectrum(ROIdata.strobetraces,Fs,'power');
    ROIdataset{countnames}.power = power;
    ROIdataset{countnames}.pfreqs = pfreqs;
    
    lowindex = [find(pfreqs>lowfreq(1),1) , find(pfreqs>lowfreq(2),1)-1];
    hiindex = [find(pfreqs>hifreq(1),1) , find(pfreqs>hifreq(2),1)-1];
    
    plow = pow2db(mean(power(lowindex(1):lowindex(2))));
    phi = pow2db(mean(power(hiindex(1):hiindex(2))));   
    meanpowers(countnames,1) = plow;
    meanpowers(countnames,2) = phi;
    
end

set(gca, 'XScale', 'log')
hold on;
freqs = [1/16 1/8 1/4 1/2 1 2 4];
for j=1:length(freqs)
    xpoint = freqs(j);
    plot([xpoint xpoint],ylim,'r');
end

%ylimits = ylim;
ylimits = ylim;
l = fill([lowfreq(1) lowfreq(2) lowfreq(2) lowfreq(1)],[ ylimits(1) ylimits(1) ylimits(2) ylimits(2)],'k');
h = fill([hifreq(1) hifreq(2) hifreq(2) hifreq(1)],[ ylimits(1) ylimits(1) ylimits(2) ylimits(2)],'k');
l.FaceAlpha=0.1;
set(l,'EdgeColor','none')
h.FaceAlpha=0.1;
set(h,'EdgeColor','none')

xticks(freqs);
ylabel('');

hold off;
