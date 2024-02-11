function mObject = executeSTRAIGHTanalysisM(mObject,optionalParameters);
%   STRAIGHT analysis for mObject
%   mObject = executeSTRAIGHTanalysisM(mObject,optionalParameters);
%

%   Designed and coded by Hideki Kawahara
%   26/Feb./2005
%   Copyright(c) 2005, Hideki Kawahara

x = mObject.waveform;
fs = mObject.samplingFrequency;
if nargin>1
    [f0raw,ap,prmF0] = exstraightsource(x,fs,optionalParameters);
    [n3sgram,analysisParamsSp]=exstraightspec(x,f0raw,fs,optionalParameters);
else
    [f0raw,ap,prmF0] = exstraightsource(x,fs);
    [n3sgram,analysisParamsSp]=exstraightspec(x,f0raw,fs);
end;
mObject.F0 = f0raw;
mObject.spectrogram = n3sgram;
mObject.aperiodicityIndex = ap;
mObject.frameUpdateInterval = prmF0.F0frameUpdateInterval; 
mObject.F0extractionConditions = prmF0;
mObject.SpectrumExtractionConditions = analysisParamsSp;
