function mObjectM = voicemultimorph(mObjects, mRates)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Not for diffusion - to be used exclusively 
% as part of a formal collaboration with the 
% Voice Neurocognition Laboratory
% University of Glasgow
% Version 12 June 2011
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Voicemultimorph is designed to morph a virtually unlimited number of sounds together.
% All the sounds are processed in a symmetrical way, without any intermediate morphing stages.
%
% 1st parameter mObjects is a cell array of structures containing all the mObjects of the sounds you want to morph.
% 2nd parameter mRates is a structure with 5 fields, each of them being a vector with as many elements as sounds :
%  .F0                : morphing rates vector for fundamental frequency
%  .spectralamplitude : morphing rates vector for spectral amplitude
%  .aperiodicity      : morphing rates vector for aperiodicity index
%  .time              : morphing rates vector for time structure
%  .frequency         : morphing rates vector for frequency structure and formants
%
% Different mRates can be applied for the different sounds or fields.
%
% Default settings are:
% - linear interpolations for time frames
% - logarithmic interpolations for frequency frames
% - logarithmic interpolations for F0
% - logarithmic interpolations for spectral amplitudes
% - linear interpolations for aperiodicity indexes (which are on a dB scale)
%
% Voicemultimorph was developed by Julien Rouger and a wee bit by Marianne Latinus 
% in the Voice Neurocognition Laboratory, University of Glasgow.
% Adapted from the original timeFrequencySTRAIGHTmorphing function 
% developed by Hideki Kawahara (STRAIGHT), Wakayama University.
%



% Check whether the structures are compatible for morphing and creates the morphing object
mObjectM = [];

% Flips mObjects if dimensions are not in the correct order
if size(mObjects, 2) > size(mObjects, 1)
    mObjects = mObjects';
end

for s = 2:size(mObjects, 1)
    if mObjects{s}.samplingFrequency ~= mObjects{1}.samplingFrequency; display('Sampling frequencies are inconsistent. Can''t morph these objects together. '); return; end;
    if mObjects{s}.frameUpdateInterval ~= mObjects{1}.frameUpdateInterval; display('Sampling times are inconsistent. Can''t morph these objects together. '); return; end;
    if length(mObjects{s}.anchorTimeLocation) ~= length(mObjects{1}.anchorTimeLocation); display('Time anchors are inconsistent. Can''t morph these objects together. '); return; end;
end;

mObjectM = createMobject;
m0bjectM.samplingFrequency = mObjects{1}.samplingFrequency;
m0bjectM.frameUpdateInterval = mObjects{1}.frameUpdateInterval;

% Initialisations
NSounds = size(mObjects, 1);
NFrequencies = size(mObjects{1}.spectrogram, 1);
fs = mObjects{1}.samplingFrequency;
df = fs / (2 * (NFrequencies - 1));
dt = mObjects{1}.frameUpdateInterval;

Duration = zeros(NSounds, 1);
Length = zeros(NSounds, 1);
NTimeAnchors = length(mObjects{1}.anchorTimeLocation) + 2;
NFrequencyAnchors = zeros(NTimeAnchors - 2, 1);
TimeAnchors = zeros(NSounds, NTimeAnchors);
FrequencyAnchors = zeros(NSounds, NTimeAnchors - 2, size(mObjects{1}.anchorFrequency, 2));

% Defines time and frequency anchors
for s = 1:NSounds
    Length(s) = size(mObjects{s}.F0, 2);
    Duration(s) = (Length(s) - 1) * dt; % in ms
    TimeAnchors(s, :) = [0; mObjects{s}.anchorTimeLocation; Duration(s)];
    % Cleans every undefined anchor frequency (negative or zero)
    for t = 1:NTimeAnchors - 2
        FrequencyAnchorsAxe = squeeze(mObjects{s}.anchorFrequency(t, :));
        FrequencyAnchorsAxe = FrequencyAnchorsAxe(FrequencyAnchorsAxe > 0);
        FrequencyAnchors(s, t, 1:length(FrequencyAnchorsAxe)) = FrequencyAnchorsAxe;
    end;
end;

% Calculates morphing time anchors using linear interpolation of anchor time points
DurationMorph = 0;
TimeAnchorsMorph = zeros(NTimeAnchors, 1);
for s = 1:NSounds
    DurationMorph = DurationMorph + mRates.time(s) * Duration(s);
    TimeAnchorsMorph = TimeAnchorsMorph + mRates.time(s) * TimeAnchors(s, :)';
end;
TimeAxisMorph = 0:dt:DurationMorph;


% Checks whether frequency anchors with non-zero mRates are compatible
mR = (mRates.time == 0) + (mRates.frequency == 0) + (mRates.F0 == 0) + (mRates.spectralamplitude == 0) + (mRates.aperiodicity == 0);
[smr, imr] = sort(mR);

if (smr(1) == 5)
    display('All your sounds have zero morphing rates in your data. Sorry but I can''t morph anything. '); return;
end;

% Initialises NFrequencyAnchors with the first mObject with non-zero mRates
for t = 1:NTimeAnchors - 2
    NFrequencyAnchors(t) = sum(FrequencyAnchors(imr(1), t, :) > 0);
end;

% Loops over every mObject with non-zero mRates to check for compatibility of frequency anchors
if (smr(2) == 5)
    display('There is only one sound with non-zero morphing rates in your data. Don''t worry I''morphing it anyway. ');
else
    i = 2;
    while (i <= NSounds && smr(i) < 5)
        for t = 1:NTimeAnchors - 2
            if sum(FrequencyAnchors(imr(i), t, :) > 0) ~= NFrequencyAnchors(t)
                display('Frequency anchors are inconsistent. Can''t morph these objects together. '); return; 
            end;
        end;
        i = i + 1;
    end;
end;

% Looks for first and last non-empty frequency anchors axes
ft = 1; while (NFrequencyAnchors(ft) == 0 && ft < NTimeAnchors - 2) ft = ft + 1; end;
lt = NTimeAnchors - 2; while (NFrequencyAnchors(lt) == 0 && lt >= 0) lt = lt - 1; end;

% Calculates morphing frequency anchors using logarithmic interpolation of anchor frequency points
FrequencyAnchorsMorph = zeros(NTimeAnchors - 2, size(mObjects{imr(1)}.anchorFrequency, 2));
FrequencyAnchorsMorph(:, :) = FrequencyAnchors(imr(1), :, :);
F0Morph = zeros(1, length(TimeAxisMorph));
WeighSumF0 = zeros(1, length(TimeAxisMorph));
APMorph = zeros(NFrequencies, length(TimeAxisMorph));
SpectrogramMorph = zeros(NFrequencies, length(TimeAxisMorph));

FrequencyAxis = (df:df:fs / 2);
for t = 1:NTimeAnchors - 2
    NFA = NFrequencyAnchors(t);
    if (NFA > 0)% && mRates.frequency(s) ~= 0)
        FrequencyAnchorAxe = zeros(NFA, 1);
        FrequencyAnchorAxeMorph = zeros(NFA, 1);
        for s = 1:NSounds
            % Only keep strictly positive anchor frequencies since it extracts the logarithm
            FrequencyAnchorAxe(:) = FrequencyAnchors(s, t, 1:NFA);
            FrequencyAnchorAxeMorph = FrequencyAnchorAxeMorph + mRates.frequency(s) * log(FrequencyAnchorAxe);
        end;
        FrequencyAnchorAxeMorph = exp(FrequencyAnchorAxeMorph');
        FrequencyAnchorsMorph(t, 1:NFA) = FrequencyAnchorAxeMorph;
    end;
end;


% Sounds morphing
for s = 1:NSounds

    % Looks for zero mRates values to avoid useless time consuming calculations
    if mRates.F0(s) ~= 0 || mRates.spectralamplitude(s) ~= 0 || mRates.aperiodicity(s) ~= 0
        % Calculates the time map from morphed frame to sound S frame
        TimeMapMorphToS = interp1(TimeAnchorsMorph, TimeAnchors(s, :), TimeAxisMorph);
    end;

    % Looks for zero mRates values to avoid useless time consuming calculations
    if mRates.F0(s) ~= 0
        % Loop initialisation
        F0 = mObjects{s}.F0;
        
        % Parses the morphed time axis
        for t = 1:length(TimeAxisMorph)
            ts = TimeMapMorphToS(t) / dt + 1; itS = min(floor(ts), length(F0)); ktS = ts - itS; itSB = min(itS + 1, length(F0));

            % Morphs the fundamental frequency
            % Uses a logarithmic interpolation between it1 and it1B; keeps the closest value if one out the two equals 0

           
            if (F0(itS) == 0 || F0(itSB) == 0)
		F0S = F0(min(round(ts), length(F0)));
            else
                F0S = exp((1 - ktS) * log(F0(itS)) + ktS * log(F0(itSB)));
            end;

            % Weighted sum is only calculated for non-zero fundamental frequencies
            if (F0S > 0)
                F0Morph(t) = F0Morph(t) + mRates.F0(s) * log(F0S);
                WeighSumF0(t) = WeighSumF0(t) + mRates.F0(s);
            end;
        end;
    end;
        
    % Looks for zero mRates values to avoid useless time consuming calculations
    if mRates.spectralamplitude(s) ~= 0 || mRates.aperiodicity(s) ~= 0
        % Calculates the frequency map from morphed frame to sound S frame
        logFrequencyAnchorsAxesMorphToS = zeros(NTimeAnchors, NFrequencies);
        for t = 1:NTimeAnchors - 2
            NFA = NFrequencyAnchors(t);
            if (NFA > 0)
                FrequencyAnchorAxeS = zeros(NFA, 1);
                FrequencyAnchorAxeS(:) = FrequencyAnchors(s, t, 1:NFA);
                FrequencyAnchorAxeS = [df; FrequencyAnchorAxeS; fs / 2];

                FrequencyAnchorAxeMorph = zeros(NFA, 1);
                FrequencyAnchorAxeMorph(:) = FrequencyAnchorsMorph(t, 1:NFA);
                FrequencyAnchorAxeMorph = [df; FrequencyAnchorAxeMorph; fs / 2];

                logFrequencyAnchorsAxesMorphToS(t + 1, 2:NFrequencies) = interp1(log(FrequencyAnchorAxeMorph), log(FrequencyAnchorAxeS), log(FrequencyAxis));
            end;
        end;

        % If there are some empty frequency axes at the beginning, copy the first non-empty frequency axis
        for t = 1:ft
            logFrequencyAnchorsAxesMorphToS(t, :) = logFrequencyAnchorsAxesMorphToS(ft + 1, :);
        end;

        % If there are some empty frequency axes at the end, copy the last non-empty frequency axis
        for t = lt + 2:NTimeAnchors
            logFrequencyAnchorsAxesMorphToS(t, :) = logFrequencyAnchorsAxesMorphToS(lt + 1, :);
        end;

        % Logarithmic interpolation of frequencies axes between time anchors
        FrequencyMapMorphToS = exp(interp1(TimeAnchorsMorph, logFrequencyAnchorsAxesMorphToS, TimeAxisMorph));
        FrequencyMapMorphToS(:, 1) = 0;

        % Loop initialisation
        Spectrogram = mObjects{s}.spectrogram;
        AperiodicityIndex = mObjects{s}.aperiodicityIndex;
        
        % Parses the morphed time axis
        for t = 1:length(TimeAxisMorph)
            ts = TimeMapMorphToS(t) / dt + 1; itS = min(floor(ts), size(Spectrogram, 2)); ktS = ts - itS; itSB = min(itS + 1, size(Spectrogram, 2));

            % Parses the frequency axis
            for f = 1:NFrequencies
                % Calculates frequencies from the frequency map using linear interpolation (time axis)
                fS = FrequencyMapMorphToS(t, f) / df + 1;

                % Logarithmic correction of the fractionary part, since we are in frequency space
                ifS = floor(fS); kfS = (log(fS) - log(ifS)) / (log(ifS + 1) - log(ifS)); ifSB = min(ifS + 1, length(FrequencyAxis));

                % Morphs the spectral amplitude using a logarithmic interpolation (amplitudes are in N.m-2)
                logAmplitude = (1 - ktS) * ((1 - kfS) * log(Spectrogram(ifS, itS))  + kfS * log(Spectrogram(ifSB, itS)))...
                    + ktS * ((1 - kfS) * log(Spectrogram(ifS, itSB)) + kfS * log(Spectrogram(ifSB, itSB)));

                SpectrogramMorph(f, t) = SpectrogramMorph(f, t) + mRates.spectralamplitude(s) * logAmplitude;

                % Morphs the aperiodicity index using a linear interpolation (amplitudes are in dB)
                APS = (1 - ktS) * ((1 - kfS) * AperiodicityIndex(ifS, itS)  + kfS * AperiodicityIndex(ifSB, itS))...
                    + ktS * ((1 - kfS) * AperiodicityIndex(ifS, itSB) + kfS * AperiodicityIndex(ifSB, itSB));

                APMorph(f, t) = APMorph(f, t) + mRates.aperiodicity(s) * APS;
            end;
        end;
    end;
end;

% Finishes F0 calculation
for t = 1:length(TimeAxisMorph)
    if (WeighSumF0(t) > 0)
        F0Morph(t) = exp(F0Morph(t) ./ WeighSumF0(t));
    else
        F0Morph(t) = 0;
    end;
end;

% Saves everything
mObjectM.samplingFrequency = fs;
mObjectM.F0 = F0Morph;
mObjectM.aperiodicityIndex = APMorph;
mObjectM.spectrogram = exp(SpectrogramMorph); % Takes the exponential of the weighted sum of the amplitudes logarithms
mObjectM.anchorTimeLocation = TimeAnchorsMorph(2:end-1);
mObjectM.anchorFrequency = FrequencyAnchorsMorph;