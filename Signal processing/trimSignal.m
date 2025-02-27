function [trimmedSignal] = trimSignal(signal, fs, varargin)
% TRIMSIGNAL Trims a signal to remove near-zero padding and adds 3 seconds
% of zeros before and after the detected signal.
%
% Inputs:
%   signal - The input signal vector to be trimmed
%   fs - Sampling frequency in Hz
%   varargin - Optional parameters:
%     'method' - Method for threshold determination:
%                'percentile' (default): Uses a percentile of the signal amplitude
%                'stdev': Uses standard deviation of the background
%                'moving': Uses a moving average to detect signal onset/offset
%                'energy': Uses short-time energy function
%                'manual': Uses a manually specified threshold
%     'threshold' - For manual method, the threshold value
%     'percentile' - For percentile method, which percentile to use (default: 95)
%     'window' - For moving methods, the window length in seconds (default: 0.1)
%     'bg_percent' - Percentage of signal start to use as background (default: 10)
%
% Output:
%   trimmedSignal - The trimmed signal with 3 seconds of zeros added before and after

% Parse inputs
p = inputParser;
addRequired(p, 'signal');
addRequired(p, 'fs', @isnumeric);
addParameter(p, 'method', 'percentile', @ischar);
addParameter(p, 'threshold', [], @isnumeric);
addParameter(p, 'percentile', 95, @isnumeric);
addParameter(p, 'window', 0.1, @isnumeric);
addParameter(p, 'bg_percent', 10, @isnumeric);
parse(p, signal, fs, varargin{:});

method = p.Results.method;
manualThreshold = p.Results.threshold;
percentileVal = p.Results.percentile;
windowSec = p.Results.window;
bgPercent = p.Results.bg_percent;

% Make sure signal is a column vector for consistent processing
isRowVector = isrow(signal);
signal = signal(:);

% Calculate the number of samples for 3 seconds
padLength = round(3 * fs);

% Determine threshold based on selected method
switch lower(method)
    case 'percentile'
        % Use a percentile of the absolute signal values
        threshold = prctile(abs(signal), percentileVal);
        
    case 'stdev'
        % Use standard deviation of the estimated background
        bgLength = round(length(signal) * bgPercent/100);
        % Assume first bgLength samples are background
        background = signal(1:bgLength);
        bgStd = std(background);
        % Set threshold as 5 sigma above background
        threshold = 5 * bgStd;
        
    case 'moving'
        % Use moving average to find transition points
        windowLength = round(windowSec * fs);
        movingAvg = movmean(abs(signal), windowLength);
        % Get baseline from first portion of the signal
        bgLength = round(length(signal) * bgPercent/100);
        baselineLevel = mean(movingAvg(1:bgLength));
        % Set threshold to 3x the baseline
        threshold = 3 * baselineLevel;
        % Replace signal with the moving average for detection
        detectionSignal = movingAvg;
        
    case 'energy'
        % Short-time energy function
        windowLength = round(windowSec * fs);
        energyFunc = zeros(size(signal));
        for i = 1:length(signal) - windowLength
            frame = signal(i:i+windowLength-1);
            energyFunc(i) = sum(frame.^2) / windowLength;
        end
        % Get baseline from first portion
        bgLength = round(length(signal) * bgPercent/100);
        baselineEnergy = mean(energyFunc(1:bgLength));
        % Set threshold to 20x the baseline energy
        threshold = 20 * baselineEnergy;
        % Replace signal with energy function for detection
        detectionSignal = energyFunc;
        
    case 'manual'
        % Use manually specified threshold
        if isempty(manualThreshold)
            error('For manual method, you must provide a threshold value');
        end
        threshold = manualThreshold;
        
    otherwise
        error('Unknown threshold method: %s', method);
end

% Default to using the original signal for detection
if ~exist('detectionSignal', 'var')
    detectionSignal = abs(signal);
end

% Find indices where signal exceeds threshold
signalIndices = find(detectionSignal > threshold);

% If no values exceed threshold, return the original signal
if isempty(signalIndices)
    warning('No signal detected above threshold. Returning original signal.');
    trimmedSignal = signal;
    if isRowVector
        trimmedSignal = trimmedSignal';
    end
    return;
end

% Get start and end points of actual signal
startIdx = max(1, signalIndices(1));
endIdx = min(length(signal), signalIndices(end));

% Extract the actual signal
actualSignal = signal(startIdx:endIdx);

% Create the trimmed signal with 3 seconds zero padding on each side
trimmedSignal = [zeros(padLength, 1); actualSignal(:); zeros(padLength, 1)];

% Make sure the output has the same orientation as the input
if isRowVector
    trimmedSignal = trimmedSignal';
end

% Visualize the detection
figure;
subplot(2,1,1);
plot(signal); hold on;
plot([startIdx, endIdx], [signal(startIdx), signal(endIdx)], 'ro', 'MarkerSize', 10);
title('Original Signal with Detection Points');

subplot(2,1,2);
plot(trimmedSignal);
title('Trimmed Signal with Zero Padding');

end