%{
Function to retrieve frame time from ThorSync hdf5 data
Dependencies: LoadSyncEpisode.m  LoadSyncXML.m
Input: folder containing ThorSync files
(namely Episode001.h5 and ThorRealTimeDataSettings.xml)

Update 17.12.7 Added output - time of trigger signal
*first frame in is ~200msec behind trigger
%}

function [frameTime,triggerTime] = GenerateFrameTime(path)

LoadSyncEpisode(path);
frameOutLogical = logical(Frame_Out);
frameOutDiff = diff(frameOutLogical);
risingEdge = find(frameOutDiff>0);
fallingEdge = find(frameOutDiff<0);
len =fallingEdge - risingEdge;
maxLen = max(len);
minLen = min(len);
frameOutDiff = diff(Frame_Out);
if gt(maxLen,1.5*minLen)
    threshold = minLen + (maxLen - minLen)/2;
    frameOutDiff(risingEdge(len>threshold))=0;
end
frameOutDiff = vertcat(0,frameOutDiff);
% z1 = Frame_In & frameOutDiff;
indexes = find(frameOutDiff>0);
frameTime = time(indexes);

if exist('Trigger_IN', 'var')
    trigger = find(Trigger_IN,1);
    frameOut = find(Frame_Out,1);
    if frameOut<trigger
        disp('Warning: Trigger mode was not on! Using time of trigger signal to mark start of experiment')
        triggerTime = time(trigger);
    else
        triggerTime = time(frameOut);
    end
else
    disp('Warning: Trigger signal not on record! Using time of first captured frame as experiment start time');
    frameOut = find(Frame_Out,1);
    triggerTime = time(frameOut);
end

