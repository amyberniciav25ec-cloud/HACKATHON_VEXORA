
clc;
clear;
close all;

folder = fullfile(pwd,'data');
resultsFolder = fullfile(pwd,'results');

if ~exist(resultsFolder,'dir')
    mkdir(resultsFolder);
end

%% Load Real ECG Signal

fid = fopen(fullfile(folder,'100.dat'),'rb');

if fid == -1
    error('Cannot open 100.dat. Check the data folder.');
end

bytes = fread(fid,inf,'uint8=>double');
fclose(fid);

count = floor(length(bytes)/3);
bytes = bytes(1:3*count);

b1 = bytes(1:3:end);
b2 = bytes(2:3:end);
b3 = bytes(3:3:end);

s1 = b1 + bitand(b2,15)*256;
s2 = b3 + bitshift(bitand(b2,240),4);

s1(s1 >= 2048) = s1(s1 >= 2048)-4096;
s2(s2 >= 2048) = s2(s2 >= 2048)-4096;

ecgA = zeros(1,2*count);
ecgA(1:2:end) = s1;
ecgA(2:2:end) = s2;

ecg = ecgA(1:2:end);

fs = 360;

%% Select First 10 Seconds

N = min(length(ecg),10*fs);
x = ecg(1:N);
t = (0:N-1)/fs;

%% Display Input ECG Waveform

figure('Name','Input ECG Waveform','NumberTitle','off');
plot(t,x,'b');
xlabel('Time (seconds)');
ylabel('ECG Amplitude (digital units)');
title('Input ECG Waveform - MIT-BIH Record 100');
grid on;

%% Smooth ECG Signal

y = conv(x,ones(1,7)/7,'same');

%% Detect Peaks

threshold = mean(y)+0.8*std(y);
detected = [];

for i = 2:N-1
    if y(i)>threshold && ...
       y(i)>=y(i-1) && y(i)>y(i+1)

        if isempty(detected) || ...
           i-detected(end)>=round(0.30*fs)
            detected(end+1) = i;
        end
    end
end

%% Load Reference Annotations

fid = fopen(fullfile(folder,'100.atr'),'rb');

if fid == -1
    error('Cannot open 100.atr. Check the data folder.');
end

a = fread(fid,inf,'uint8=>double');
fclose(fid);

annSamples = [];
annTypes = [];
sampleCount = 0;
i = 1;

while i+1 <= length(a)

    word = a(i+1)*256+a(i);
    i = i+2;

    code = floor(word/1024);
    interval = mod(word,1024);

    if code == 0 && interval == 0
        break;
    end

    if code == 59
        if i+3 > length(a)
            break;
        end

        skipValue = a(i+1)*256+a(i) + ...
                    (a(i+3)*256+a(i+2))*65536;

        if skipValue >= 2^31
            skipValue = skipValue-2^32;
        end

        sampleCount = sampleCount+skipValue;
        i = i+4;
        continue;
    end

    sampleCount = sampleCount+interval;

    if code == 63
        i = i+interval+mod(interval,2);
        continue;
    end

    if code > 0 && code < 50
        annSamples(end+1) = sampleCount;
        annTypes(end+1) = code;
    end
end

%% Select Normal Reference Beats

ref = annSamples(annTypes==1);
ref = ref(ref>=0 & ref<N)+1;

%% Compare Detected Peaks With Reference Beats

matched = false(size(ref));
used = false(size(detected));

for k = 1:length(ref)

    if isempty(detected)
        break;
    end

    [distance,j] = min(abs(detected-ref(k)));

    if distance <= round(0.15*fs) && ~used(j)
        matched(k) = true;
        used(j) = true;
    end
end

TP = sum(matched);
FN = length(ref)-TP;
FP = length(detected)-sum(used);

sensitivity = 100*TP/max(TP+FN,1);
precision = 100*TP/max(TP+FP,1);
F1 = 2*sensitivity*precision/max(sensitivity+precision,eps);

%% Calculate RR Intervals and Heart Rate

if length(detected)>=2
    rr = diff(detected)/fs;
    heartRate = 60./rr;
    meanHR = 60/mean(rr);
    rrVariation = std(rr);
else
    rr = [];
    heartRate = [];
    meanHR = NaN;
    rrVariation = NaN;
end


%% Complete ECG Demo Window

figure('Name','ECG Project Demo','NumberTitle','off');

subplot(2,2,1);
plot(t,x,'b');
title('1. Input ECG Signal');
xlabel('Time (seconds)');
ylabel('Amplitude');
grid on;

subplot(2,2,2);
plot(t,y,'b');
hold on;
plot(t,threshold*ones(size(t)),'k--');
title('2. Smoothed ECG Signal');
xlabel('Time (seconds)');
ylabel('Amplitude');
legend('Smoothed ECG','Detection Threshold');
grid on;

subplot(2,2,3);
plot(t,x,'b');
hold on;
plot(t(detected),x(detected),'rx','MarkerSize',8);

if ~isempty(ref)
    plot(t(ref),x(ref),'go','MarkerSize',6);
end

title('3. Detected Heartbeats');
xlabel('Time (seconds)');
ylabel('Amplitude');
legend('Input ECG','Detected Peaks','Reference Beats');
grid on;

subplot(2,2,4);

if ~isempty(rr)
    plot(t(detected(2:end)),rr,'o-');
    title('4. RR Interval Analysis');
    xlabel('Time (seconds)');
    ylabel('RR Interval (seconds)');
    grid on;
else
    title('4. RR Interval Analysis');
    text(0.2,0.5,'Not enough detected peaks');
end

sgtitle('ECG Signal Abnormality Analysis');

saveas(gcf,fullfile(resultsFolder,'Complete_ECG_Demo.png'));


%% Display ECG and Detected Peaks

figure('Name','Real ECG Analysis','NumberTitle','off');

plot(t,x,'b');
hold on;

plot(t(detected),x(detected),'rx','MarkerSize',8);

if ~isempty(ref)
    plot(t(ref),x(ref),'go','MarkerSize',6);
end

xlabel('Time (seconds)');
ylabel('ECG Amplitude (digital units)');
title('MIT-BIH Record 100: ECG Peak Detection');
legend('ECG Signal','Detected Peaks','Reference Normal Beats');
grid on;

saveas(gcf,fullfile(resultsFolder,'Real_ECG_Peak_Detection.png'));

%% Plot RR Intervals

if ~isempty(rr)
    figure('Name','Real ECG RR Intervals','NumberTitle','off');
    plot(t(detected(2:end)),rr,'o-');
    xlabel('Time (seconds)');
    ylabel('RR Interval (seconds)');
    title('Real ECG RR Interval Analysis');
    grid on;

    saveas(gcf,fullfile(resultsFolder,'Real_ECG_RR_Intervals.png'));
end

%% Print Results

fprintf('\n======= REAL ECG ANALYSIS =======\n');
fprintf('Record: MIT-BIH 100\n');
fprintf('Sampling frequency: %d Hz\n',fs);
fprintf('Analysis duration: %.2f seconds\n',N/fs);
fprintf('Reference normal beats: %d\n',length(ref));
fprintf('Detected peaks: %d\n',length(detected));
fprintf('True positives: %d\n',TP);
fprintf('False positives: %d\n',FP);
fprintf('False negatives: %d\n',FN);
fprintf('Sensitivity: %.2f%%\n',sensitivity);
fprintf('Precision: %.2f%%\n',precision);
fprintf('F1 score: %.2f%%\n',F1);
fprintf('Estimated mean heart rate: %.2f BPM\n',meanHR);
fprintf('RR interval variation: %.4f seconds\n',rrVariation);
fprintf('=================================\n');



% ECG Insight: Display all four graphs in one window

fs = 360;
t = (0:length(x)-1)/fs;
binarySignal = double(y > threshold);

figure('Name','ECG Insight - Four Graphs', ...
    'NumberTitle','off');

% Graph 1: Original ECG
subplot(2,2,1);
plot(t,x);
xlim([0 5]);
title('Original ECG Signal');
xlabel('Time (seconds)');
ylabel('Amplitude');
grid on;

% Graph 2: Filtered ECG
subplot(2,2,2);
plot(t,y);
xlim([0 5]);
title('Filtered ECG Signal');
xlabel('Time (seconds)');
ylabel('Amplitude');
grid on;

% Graph 3: Threshold Detection
subplot(2,2,3);
plot(t,binarySignal);
xlim([0 5]);
ylim([-0.2 1.2]);
title('Threshold Detection');
xlabel('Time (seconds)');
ylabel('Output (0 or 1)');
grid on;

% Graph 4: Candidate Beat Detection
subplot(2,2,4);
plot(t,y);
hold on;
plot(t(peakIndices),y(peakIndices),'ro');
yline(threshold,'--');
xlim([0 5]);
title('Candidate Beat Detection');
xlabel('Time (seconds)');
ylabel('Amplitude');
legend('Filtered ECG','Candidate peaks','Threshold');
grid on;
