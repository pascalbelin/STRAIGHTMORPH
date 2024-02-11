function mObject = setAnchorFromRawAnchor(mObject,rawAnchor);
%   Set anchor points using raw anchor information
%   mObject = setAnchorFromRawAnchor(mObject,rawAnchor);

%   Designed and coded by Hideki Kawahara
%   27/Feb./2005
%   Copyright(c) 2005, Hideki Kawahara

TIMINGmARGIN = 10; % threshould for merging location
[dm1,indsrt] = sort(rawAnchor(:,1));
sortedAnchor = rawAnchor(indsrt,1);
sortedFrequency = rawAnchor(indsrt,2);
indexNumber = 1:length(sortedAnchor);

%anchorCandidate = sortedAnchor(diff([-100;sortedAnchor])>TIMINGmARGIN);
anchorIndex = indexNumber(diff([-100;sortedAnchor])>TIMINGmARGIN);
anchorCandidate = sortedAnchor(anchorIndex);
mObject.anchorTimeLocation = anchorCandidate; 
nFrequency = mObject.maximumFrequencyPoints; 

nAnchor = length(anchorCandidate);
anchorIndex(end+1) = length(sortedFrequency) + 1; % Terminator
frequencyAnchor = zeros(nAnchor,nFrequency);

for ii = 1:nAnchor
    anchorT = sortedAnchor(anchorIndex(ii):anchorIndex(ii + 1) - 1);
    anchorF = sort(sortedFrequency(anchorIndex(ii):anchorIndex(ii + 1) - 1));
    frequencyAnchor(ii, 1:length(anchorF)) = anchorF(:);
    mObject.anchorTimeLocation(ii) = mean(anchorT);    
end;
mObject.anchorFrequency = frequencyAnchor;