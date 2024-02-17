% STRAIGHTMORPH tutorial
% February 2024
% Team Neural Bases of Communication, Institut de Neurosciences de la
% Timone, CNRS & Aix-Marseille Université, Marseille, France
% Contact: pascal.belin@univ-amu.fr
% Based on Legacy STRAIGHT written by Hideki Kawahara
% and additional functions written by Julien Rouger

clear all; close all
cd ('C:\AMUBOX\PROGRAMS\STRAIGHTMORPH\TUTORIAL\'); % insert your own path

%% Extracting mObjects -- ExtractMObject.m

mObject=ExtractMObject('Bonjour_ET.wav') 
mObject=ExtractMObject('W33eh.wav')
% by default the mObject is saved as a .mat with the same name as the .wav

% inspecting the mObject
displayMobject(mObject, 'waveform') % displays the waveform
displayMobject(mObject, 'anchorFrequency') % displays the smoothed spectrogram along with spectro-temporal anchors
figure; plot(mObject.F0) % plots the f0 contour

% resynthesizing the mObject
sy=executeSTRAIGHTsynthesisM(mObject); % resynthesis of mObject waveform
sy=.95*sy/max(abs(sy)); % normalise at 95% peak amplitude
sound(sy,mObject.samplingFrequency); % listening to the resynthesized sound 

%% Morphing 2 mObjects 

% define mobjects to interpolate 
mobjs=cell(1,2);
load 6_pleasure.mat; mobjs{1,1}=mObject;
load 6_anger.mat; mobjs{1,2}=mObject;
% load M48eh.mat; mobjs{1,1}=mObject;
% load W33eh.mat; mobjs{1,2}=mObject;

% define mRates 
m=[0.5 0.5]; % weight of 50% for each voice 
mRates.F0=m; 
mRates.spectralamplitude=m;
mRates.aperiodicity=m;
mRates.time=m;
mRates.frequency=m;

% execute interpolation
mObjectM=voicemultimorph(mobjs,mRates);

% synthesize mObjectM
sy=executeSTRAIGHTsynthesisM(mObjectM); 
sy=.95*sy/max(abs(sy)); % normalise
sound(sy,mObject.samplingFrequency);
mObjectM.waveform=sy; % add newly generated waveform to the MobjectM 
audiowrite('M48W33Average.wav',sy,mObject.samplingFrequency);
save M48W33Average.mat mObjectM % save MObjectM if necessary

% inspect new mObjectM
displayMobject(mObjectM, 'waveform') % displays the waveform
displayMobject(mObjectM, 'anchorFrequency') % displays the smoothed spectrogram along with spectro-temporal anchors
figure; plot(mObjectM.F0) % 

%% generate continuum
SY=[];
for k=[1.5:-0.25:-0.5]
    %k= [1:-.1:0]       % 11 step continuum  
    % k=[.95:-.15:.05] %  7 step continuum of Figure 3
    % k=[1.5:-0.1:-0.5] % 19 step continuum including caricatures
    w=[k 1-k]; % 
    mRates.F0=w; mRates.spectralamplitude=w;
    mRates.aperiodicity=w; mRates.frequency=w;
    mRates.time=w; % mRates.time=[0.5 0.5] to set all stimuli of the continuum to the same duration
    mObjectM=voicemultimorph(mobjs,mRates);
    displayMobject(mObjectM, 'anchorFrequency')
    sy=executeSTRAIGHTsynthesisM(mObjectM);
    sy=.95*sy/max(abs(sy)); % normalise
    SY=[SY;sy; zeros(mObject.samplingFrequency/5,1)]; % append with 200ms pause
end
sound(SY,mObject.samplingFrequency); % play Continuum
audiowrite('Continuum_Pleasure-Anger.wav',SY,mObject.samplingFrequency);

%% morphing N mObjects 

% load 16 mObjects and listen to them
mobjs=cell(1,16);
figure; hold on 
for k=1:16
    if k>9 S=''; else S='0'; end
    load (['FemaleVoicesmObj-F',S,num2str(k),'.mat']);
    mobjs{1,k}=mObject;
    subplot(4,4,k); displayMobject(mObject, 'anchorFrequency')
    sound(mObject.waveform, mObject.samplingFrequency) 
    pause(0.5)
end

% generate N-Average
we=ones(1,16)/16; % average rate
mRates.F0=we;
mRates.spectralamplitude=we;
mRates.aperiodicity=we;
mRates.frequency=we;
mRates.time=we;

% execute interpolation
mObjectM=voicemultimorph(mobjs,mRates);

sy=executeSTRAIGHTsynthesisM(mObjectM); 
sy=.95*sy/max(abs(sy)); % normalise
sound(sy,mObject.samplingFrequency);
audiowrite('16FAverage.wav',SY,mObject.samplingFrequency);
figure; displayMobject(mObjectM, 'anchorFrequency')
figure; plot(mObjectM.F0)

%% generate continuum between mObject1 and N-Average
SY=[];
for k=[1.5:-.25:-0.5]       % continuum with caricatures and 'anti-voices'
    w=[k*ones(1,16)/16]+(1-k)*[1 zeros(1,15)]   
    mRates.F0=w; 
    mRates.spectralamplitude=w;
    mRates.aperiodicity=w; 
    mRates.frequency=w;
    mRates.time=w; % mRates.time=ones(1,16)/16 to set all stimuli of the continuum to the average duration
    
    mObjectM=voicemultimorph(mobjs,mRates);
    sy=executeSTRAIGHTsynthesisM(mObjectM);
    sy=.95*sy/max(abs(sy)); % normalise
    SY=[SY;sy; zeros(mObject.samplingFrequency/5,1)]; % append with 200ms pause
end
sound(SY,mObject.samplingFrequency); % play Continuum
audiowrite('Continuum_F01-16FAverage.wav',SY,mObject.samplingFrequency);

%% generate random stimuli
SY=[];
a=2.5; % dispersion parameter variation between 1-a and 1+a
NStim=20; % number of generated stimuli

for k=1:NStim
    wr=ones(1,16)*(1+a)-rand(1,16)*2*a
    wr=wr/sum(wr); %weights around 1/16 with sum 1
   
    mRates.F0=wr;
    mRates.spectralamplitude=wr;
    mRates.aperiodicity=wr; 
    mRates.frequency=wr;    
    mRates.time=ones(1,16)/16; % duration of all stimuli set to average
    
    mObjectM=voicemultimorph(mobjs,mRates);
    sy=executeSTRAIGHTsynthesisM(mObjectM);
    sy=.95*sy/max(abs(sy)); % normalise
    SY=[SY;sy; zeros(mObject.samplingFrequency/5,1)]; % append with 200ms pause
end

sound(SY,mObject.samplingFrequency); % play 20 random Hellos
audiowrite('20 Random Hellos.wav',SY,mObject.samplingFrequency);


