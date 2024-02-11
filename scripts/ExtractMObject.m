function mObject = ExtractMObject(sPath, optionalParameters);

% ExtractMObject - 19th March 2009
%
% Designed by Julien Rouger
% Voice Neurocognition Laboratory
% Department of Psychology, University of Glasgow
%
% This function will directly compute the source-filter decomposition of a sound.
% It needs user intervention at two stages:
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A) Fundamental frequency (F0) detection

% A time-frequency graph will be displayed, showing the different F0 candidates for each time sample
% The candidates that were selected by the automatic procedure will be highlighted in green.
% If the result of this automatic F0 detection looks correct, without unnecessary interruptions,
% then press Esc. to go to the next processing step.
%
% Otherwise, if the result of the automatic F0 detection looks unsatisfying, click on the figure.
% You now have to define a lower and upper frequency boundaries which will constrain the F0 search range.
% First define the lower boundary, clicking with the left button to add landmarks and with the right button
% to finish the boundary definition. Then do the same for the upper frequency boundary. Matlab will restart
% the F0 detection process, taking into account the frequency constraints you manually defined.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% B) Time and frequency anchors definition
%
% Defining accurately time and frequency anchors is of crucial importance for high-quality morphing.
% Time anchors usually indicate beginning and end of the sound, phoneme temporal boundaries and
% also important formant transition. Frequency anchors usually indicate formant central frequencies.
% The number of time axes should match for all sounds that will be morphed together. The number of frequency
% anchors can be different for different time axes; yet for each time axis, the number of frequency anchors
% has to be consistent across all the sounds.
% 
% First define a time axis by clicking with the right mouse button at the appropriate temporal location.
% Then define frequency anchors on this time axis by clicking with the left button. Click on the right mouse
% button to define a new time axis and press Enter to finish, or Esc. to start again.


%[sDir, sName, sExt, sVersion] = fileparts(sPath);
%[x, fs, bits] = wavread(sPath);
[sDir, sName, ~] = fileparts(sPath);
[x, fs] = audioread(sPath);

mObject.date = datestr(now);
mObject.name = sName;
mObject.dir = sDir;
mObject.maximumFrequencyPoints = 9; % default max frequency anchor points
mObject.creatorInformation = which('ExtractMObject');
mObject.waveform = x;
mObject.samplingFrequency = fs;

if nargin > 1
    [f0raw, ap, prmF0] = exstraightsource(x, fs, optionalParameters);
    [n3sgram, analysisParamsSp]=exstraightspec(x, f0raw, fs, optionalParameters);
else
    [f0raw, ap, prmF0] = exstraightsource(x, fs);
    [n3sgram, analysisParamsSp]=exstraightspec(x, f0raw, fs);
end;
mObject.F0 = f0raw;

if exist('vuv')
    mObject.vuv = vuv;
else
    mObject.vuv = (f0raw ~= 0);
end;

mObject.spectrogram = n3sgram;
mObject.aperiodicityIndex = ap;
mObject.frameUpdateInterval = prmF0.F0frameUpdateInterval;
mObject.F0extractionConditions = prmF0;
mObject.SpectrumExtractionConditions = analysisParamsSp;
mObject = SetAnchors(mObject);
save([sDir, sName], 'mObject');