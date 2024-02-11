function sy = executeSTRAIGHTsynthesisM(mObject,optionalParameters)
%   STRAIGHT synthesis from mObject
%   sy = executeSTRAIGHTsynthesisM(mObject,optionalParameters);
%

%   Designed and coded by Hideki Kawahara
%   27/Feb./2005
%   Copyright(c) 2005, Hideki Kawahara
%   14/March/2005 bug fix on optional paramters

fs = mObject.samplingFrequency; 
f0raw = mObject.F0;
n3sgram = mObject.spectrogram;
ap = mObject.aperiodicityIndex;
if nargin>1
    [sy,prmS] = exstraightsynth(f0raw,n3sgram,ap,fs,optionalParameters);
else
    [sy,prmS] = exstraightsynth(f0raw,n3sgram,ap,fs);
end;
