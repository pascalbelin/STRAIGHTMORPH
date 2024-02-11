function mObject = SetAnchors(mObject)

% SetAnchors User Interface - 1st March 2009
%
% Allow an user to manually define time and frequency anchors
% used for subsequent morphing operations
%
% Designed by Julien Rouger
% Voice Neurocognition Laboratory
% Department of Psychology, University of Glasgow

fs = mObject.samplingFrequency;
tFrame = mObject.frameUpdateInterval;

[nrow,ncolumn]=size(mObject.spectrogram);
timeSpan = [0 (ncolumn-1)*tFrame];
dBsgram = 20*log10(mObject.spectrogram);
maxSgramdB = max(max(dBsgram));

lv = 8; wv = (lv + log(abs(hilbert(mObject.waveform))))/lv; wv(wv < 0) = 0;
t = 0:(ncolumn-1);
w = wv(1 + round(t * (length(wv) - 1) / (ncolumn - 1)));

nTimeAnchors = 0;
FMax = 8000;

but = 27;
while but == 27
    Time = -1;

    % Display spectrogram and temporal envelope
    fig = figure('Name', [mObject.name '- time span 0-' num2str(timeSpan(2),10) ' (ms) ' datestr(now)], 'MenuBar', 'none');
    pause(0.01); jf=get(gcf,'JavaFrame'); set(jf,'Maximized',1);
    imagesc(timeSpan, [0 FMax],max(dBsgram,maxSgramdB-70));
    hold on; plot(t * tFrame, FMax - 0.2 * FMax * w, 'w');
    axis('xy');

    % Set full screen mode with minimal margins
    pause(0.5);
    h = get(gca, 'TightInset') + [0.01 0.01 0.01 0.01]; o = get(gca, 'OuterPosition');
    set(gca, 'Position', [h(1) h(2) 1 - h(1) - h(3) 1 - h(2) - h(4)]);

    % Select time & frequency anchors
    xy = [];
    n = 1;
    but = 1;
    while but < 4
        [xi,yi,but] = ginput(1);

        % Frequency anchor
        if but == 1
            if Time >= 0 && Time <= (ncolumn-1)*tFrame && yi >=0 && yi <= FMax
                % Display frequency anchor
                hold on; plot(Time,yi,'ow', 'MarkerSize', 7, 'LineWidth', 4);
                hold on; plot(Time,yi,'ok', 'MarkerSize', 9, 'LineWidth', 2);
                
                % Record frequency anchor
                nFrequencyAnchors = nFrequencyAnchors + 1;
                FrequencyAnchors(nTimeAnchors, nFrequencyAnchors) = yi;
            end;

            % Time anchor
        elseif but == 3
            if xi >= 0 && xi <= (ncolumn-1)*tFrame
                % Display time axis
                hold on; plot([xi xi], [0 FMax], 'w');hold on; plot([xi xi], [0 FMax], 'k:');
                
                % Display local maxima
                sample = mObject.spectrogram(:,round(xi));
                nmax = 0;
                for i = 2:length(sample) - 1
                    if sample(i) > sample(i - 1) && sample(i) > sample(i + 1)
                        nmax = nmax + 1; Fmax(nmax) = (i - 1) / (length(sample) - 1) * FMax; Amax(nmax) = sample(i);
                    end;
                end;
                [Amax, idx] = sort(Amax, 'descend');
                Ymax = Fmax(idx(1:min(length(idx), 10))); Xmax = Ymax; Xmax(:) = xi;
                hold on; plot(Xmax, Ymax, 'ok');
                
                % Record time anchor
                Time = xi;
                nTimeAnchors = nTimeAnchors + 1;
                nFrequencyAnchors = 0;
                TimeAnchors(nTimeAnchors) = Time;
                FrequencyAnchors(nTimeAnchors, 1) = 0;
            end;
        end;
    end;

    if but == 27
        close(fig);
    end;
end;

FrequencyAnchors(FrequencyAnchors == 0) = Inf;
[TimeAnchors, idx] = sort(TimeAnchors);
FrequencyAnchors = FrequencyAnchors(idx, :);
for n = 1:nTimeAnchors
    FrequencyAnchors(n, :) = sort(FrequencyAnchors(n, :));
end;
FrequencyAnchors(FrequencyAnchors == Inf) = 0;

mObject.anchorTimeLocation = TimeAnchors';
mObject.anchorFrequency = FrequencyAnchors;
