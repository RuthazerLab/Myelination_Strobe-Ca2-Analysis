clear all;
close all;
%{
procROITrace.m
(for Vanessa's strobe data)
produces data plots from neuropil data for all 8 frequencies
-raw dfof trace (includes standard stimuli, no detrending)
-spectrograms (calculated using detrended data)
-power plots (calculated using detrended data)
%}

%input root folder
%rootfolder = 'D:\Zahraa\Taddata-2020';
rootfolder = 'E:\Taddata_Sync\Taddata-2020';
rootfolder = 'E:\CoconutTree\M1\Data\Taddata-2020';

savedetrend = 0;    %save detrended trace as mat file (will replace any existing file)
readdetrend = 1;    %read detrended trace from a file

%fill in experiment info (uncomment the relevant experiment id#)

date = '20200627';
animal = 'Bodhi';
idlist = [1239 1220 1255 1313 1331 1348 1405 1425];

date = '20200628';
animal = 'Chanda';
idlist = [1907	1927	1946	2004	2023	2106	2124	2144];

date = '20200628';
animal = 'Deva';
idlist = [2540	2600	2619	2638	2659	2720	2738	2757];



summary = 1;    %generate summary plots of all 8 trials (need to input all 8 trials)
savesumimg = 0; %save summary image of all 8 trials

%select detrending method
%note: polynomial detrending will only work for 2019a and later
detrending = 'poly';   %polynomial
%detrending = 'hp';   %highpass filter
% detrending = 'none'; %no detrending

%dfof/detrending parameters
basepctl = 20;  %base percentile for dfof
polydeg = 4;    %degree for polynomial detrending
hpf = 0.003;    %highpass filter frequency


%format for saving images
format = 'jpeg';
resolution = '-r300';

%some just in case options, don't need to touch these
showindividual = 0; %show plots for individual freqs
loadxls = 0;    %load data from xls file
saveimg = 0;    %save plots for individual freqs
namelist = {'spontaneous';'16s';'8s';'4s';'2s';'1s';'0.5s';'0.25s'};

%--------------------
procfolder = [rootfolder '\Proc_' date];

fullnamelist = {'spont';'16s';'8s';'4s';'2s';'1s';'0.5s';'0.25s'};
if summary
    dftraces = cell(1,8);
    dataframes = cell(1,8);
    strobetraces = cell(1,8);
    stroberatios = zeros(8,1);
    stimratios = zeros(8,1);
    T=table(fullnamelist,stroberatios,stimratios);
end


for countnames=1:length(namelist)
    name = [animal ' ' namelist{countnames}];
    disp(name);
    id = num2str(idlist(countnames));
    
    experiment = ['Exp_' id];
    metafolder = fullfile(procfolder,['strobeROI_' date]);
    metaname = ['metadata_' experiment '.mat'];
    outfolder = fullfile(procfolder,'results');
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
        
        if savedetrend
            save(detrendfile, 'strobetrace', 'detrending');
        end

        
    end
    
    
    %compare response amplitude in first vs last 60 secs of strobe
    pw_early = mean(strobetrace(1:60*15));
    pw_late = mean(strobetrace((length(strobetrace)-60*15+1):length(strobetrace)));
    stroberatio = pw_late/pw_early;
    disp(['Strobe rundown: ' num2str(stroberatio)]);
    
    %compare early vs late response to standard stims
    standtime = round((dataframe.pre(5)-dataframe.pre(1))*1.25);
    standearly = dfoftrace(dataframe.pre(1):(dataframe.pre(1)+standtime));
    standlate = dfoftrace(dataframe.post(1):(dataframe.post(1)+standtime));
    stimratio = mean(standlate)/mean(standearly);
    disp(['Stim rundown: ' num2str(stimratio)]);
    
    
    %% Figure 1: dfof trace with timings marked
    if showindividual
        img1 = figure(1);
        %set(img1,'position',[100 200 600 600]);
        subplot(3,1,1)
        plot(dfoftrace);
        xlim([1,length(dfoftrace)]);
        hold on;
        ylim([-0.02 0.06]);
        title({name;['rundown (late/early): standard stim= ' num2str(stimratio) '  strobe = ' num2str(stroberatio)]});
        xpoint = dataframe.strobestart;
        plot([xpoint xpoint],ylim,'r');
        xpoint = dataframe.strobeend;
        plot([xpoint xpoint],ylim,'r');
        for i=1:5
            xpoint = dataframe.pre(i);
            plot([xpoint xpoint],ylim,'k');
            xpoint = dataframe.post(i);
            plot([xpoint xpoint],ylim,'k');
        end
        hold off;
        %%
        
        
        %run time freq analyses
        %%
        subplot(3,1,3)
        pspectrum(strobetrace,Fs,'spectrogram','MinThreshold',-120,'FrequencyResolution',0.2);
        %pspectrum(strobetrace,Fs,'spectrogram','MinThreshold',-120,'TimeResolution',32);
        caxis([-110,-30]);
        ax = gca;
        ax.YScale = 'log';
        yticks([1/16,1/8,1/4,1/2,1,2,4,8]);
        
        %ylim([1,8]);
        %caxis([-70,-60]);
        
        
        subplot(3,1,2)
        pspectrum(strobetrace,Fs,'power');
        set(gca, 'XScale', 'log')
        hold on;
        freqs = [1/16 1/8 1/4 1/2 1 2 4];
        for i=1:length(freqs)
            xpoint = freqs(i);
            plot([xpoint xpoint],ylim,'r');
        end
        xticks(freqs);
        
        hold off;
        
        if saveimg
            if ~exist(outfolder,'dir')
                mkdir(outfolder);
            end
            outimg = [name '.jpg'];
            print(img1, fullfile(outfolder,outimg), ['-d' format],resolution);
        end
        
    end
    
    if summary
        dftraces{countnames} = dfoftrace;
        T.stroberatios(countnames) = stroberatio;
        T.stimratios(countnames) = stimratio;
        dataframes{countnames} = dataframe;
        strobetraces{countnames} = strobetrace;
    end   
    
end

%% generate summary plots

if summary
    
    %%
    img2 = figure(2);
    set(img2,'position',[105 50 600 700]);
    for i=1:8
        subtightplot(8,1,i,[0.03,0.1])
        dfoftrace = dftraces{i};
        dataframe = dataframes{i};
        
        
        plot(dfoftrace);
        xlim([1,length(dfoftrace)]);
        hold on;
        ylim([-0.02 0.06]);
        if i==1
            title({[animal ' neuropil'];fullnamelist{i}});
        else
            title(fullnamelist{i});
        end
        xpoint = dataframe.strobestart;
        plot([xpoint xpoint],ylim,'r');
        xpoint = dataframe.strobeend;
        plot([xpoint xpoint],ylim,'r');
        for j=1:5
            xpoint = dataframe.pre(j);
            plot([xpoint xpoint],ylim,'k');
            xpoint = dataframe.post(j);
            plot([xpoint xpoint],ylim,'k');
        end
        ax = gca;
        
        framenums = 1:length(ftimes);
        nminticks = floor(length(ftimes)/(Fs*60));
        minticks = (1:nminticks).*(Fs*60);
        xticks(minticks);
        minticklabels = cell(nminticks);
        for k=1:nminticks
            minticklabels{k} = num2str(k);
        end
        
        if i==8
            xticklabels(minticklabels);
            xlabel('Time (minutes)');
        else
            xticklabels({}); % remove x-axis
        end               
        hold off;
    end
    
    %%   
    img3 = figure(3);
    set(img3,'position',[110 50 600 700]);    
    for i=1:8
        subtightplot(8,1,i,[0.03,0.1])
        %pspectrum(strobetraces{i},Fs,'spectrogram','MinThreshold',-120,'FrequencyResolution',0.2);
        pspectrum(strobetraces{i},Fs,'spectrogram','MinThreshold',-120,'TimeResolution',20);
        caxis([-110,-30]);
        ax = gca;
        ax.YScale = 'log';
        yticks([1/16,1/2,4]);
        axis tight
        if i==1
            title({[animal ' neuropil'];fullnamelist{i}});
        else
            title(fullnamelist{i});
        end
        
        if i~=8
            ax.XAxis.Visible = 'off'; % remove x-axis
        end        
    end
    %%
    img4 = figure(4);
    set(img4,'position',[115 50 600 700]);
    for i=1:8
        subtightplot(8,1,i,[0.03,0.1])
        pspectrum(strobetraces{i},Fs,'power');
        set(gca, 'XScale', 'log')
        hold on;
        freqs = [1/16 1/8 1/4 1/2 1 2 4];
        ylim([-80 -40]);
        for j=1:length(freqs)
            xpoint = freqs(j);
            plot([xpoint xpoint],ylim,'r');
        end
        if i==1
            title({[animal ' neuropil'];fullnamelist{i}});
        else
            title(fullnamelist{i});
        end        
        
        if i~=8
            xticklabels({}); % remove x-axis
            xlabel('');
        else
            xticks(freqs);
        end 
        ylabel('');
        
        hold off;
    end
        
    img5 = figure(5);
    set(img5,'position',[120 50 600 700]);
    for i=1:8
        subtightplot(8,1,i,[0.03,0.1])
        dfoftrace = strobetraces{i};
        dataframe = dataframes{i};        
        
        plot(dfoftrace);
        xlim([1,length(dfoftrace)]);
        hold on;
        ylim([-0.02 0.06]);
        if i==1
            title({[animal ' neuropil'];fullnamelist{i}});
        else
            title(fullnamelist{i});
        end

        ax = gca;
        
        framenums = 1:length(dfoftrace);
        nminticks = floor(length(dfoftrace)/(Fs*60));
        minticks = (1:nminticks).*(Fs*60);
        xticks(minticks);
        minticklabels = cell(nminticks);
        for k=1:nminticks
            minticklabels{k} = num2str(k);
        end
        
        if i==8
            xticklabels(minticklabels);
            xlabel('Time (minutes)');
        else
            xticklabels({}); % remove x-axis
        end               
        hold off;
    end
        
        

    %%
    
    if savesumimg
        outimg = ['summary_trace_' animal '_neuropil.jpg'];
        print(img2, fullfile(outfolder,outimg), ['-d' format],resolution);
        outimg = ['summary_spect_' animal '_neuropil.jpg'];
        print(img3, fullfile(outfolder,outimg), ['-d' format],resolution);
        outimg = ['summary_power_' animal '_neuropil.jpg'];
        print(img4, fullfile(outfolder,outimg), ['-d' format],resolution);
    end
end

%%

