%% pulsar-plot takes Pulsar output (as .mat) and plots data
%                                                                         %
% 1. User selects input file in GUI                                       % 
% 2. Choice of plotting all channels or selecting single channel          %
% 3. Figure displayed in new window                                       %
%                                                                         %

%% Select input file via GUI

[FN,path] = uigetfile('*.mat');
if isequal(FN,0)
   disp('User selected Cancel'); % Displays message if interface is closed
else
   disp(['User selected ', fullfile(path,FN)]); % Displays message with file path if file is selected
end

FN = FN(1:end-4); % Removes .mat from filename

%% Load data

s = load(fullfile(path,FN)); % loads .mat file
disp(' ')
disp(['Loaded ', FN])

% Pulsar outputs .mat structure file. When loading, the result (s) is a
% structure within a structure. The next step removes the unnecessary layer
% of structure
s = s.(FN);

tt = timetable(s.matrix,'SampleRate',s.loggingrate);    % creates a timetable with the data
tt = splitvars(tt);                                     % splits the data into individual variables

%% Select channels to plot

% User selection of all channels or individual channel
disp(' ')
disp('Plot options:')
disp('  1. All channels')
disp('  2. Single channel')
plotChoice = input('Select an option (1 or 2): ');

% Single channel selection
if plotChoice == 2
    disp(' ')
    disp('Available channels:')
    numChans = width(tt);
    % Display channel list, removing trailing whitespace
    for k = 1:numChans
        fprintf('  %d. %s\n', k, strtrim(s.names(k,:)));
    end
    disp(' ')
    % User selection of channel
    chanSel = input(sprintf('Select channel number (1-%d): ', numChans));
    while ~isnumeric(chanSel) || chanSel < 1 || chanSel > numChans || floor(chanSel) ~= chanSel
        warning('Invalid selection. Please enter a whole number between 1 and %d.', numChans);
        chanSel = input(sprintf('Select channel number (1-%d): ', numChans));
    end
end

%% Plot data

% Creates figure in new window

disp(' ')
disp('Plotting data...')
figure('Name', [FN ' @ ' num2str(tt.Properties.SampleRate) 'Hz'])
set(gcf,'Visible','on','WindowState','maximized') % forces new maximised window for figure

% Plot all channels
% Loops through each channel to plot data on new tile
if plotChoice == 1
    numChans = width(tt);
    t = tiledlayout("flow");
    for k = 1:numChans % sets number of loop cycles
        nexttile % moves to next tile
        plot(tt.Time,(tt.(k)* s.scales(k))) % plots variable against time
        title(s.names(k,:), 'Interpreter', 'none') % extracts the variable name and applies it to the current plot
        ylabel(s.units(k, :), 'Interpreter', 'none')
    end
    title(t, ['Pulsar output: ', FN ' @ ' num2str(tt.Properties.SampleRate) 'Hz'], 'Interpreter', 'none')
    
% Plot single channel
elseif plotChoice == 2
    plot(tt.Time,(tt.(chanSel) * s.scales(chanSel)))
    title(s.names(chanSel,:), 'Interpreter', 'none')
    ylabel(s.units(chanSel,:), 'Interpreter', 'none')
    title({['Pulsar output: ', FN ' @ ' num2str(tt.Properties.SampleRate) 'Hz']; s.names(chanSel,:)}, 'Interpreter', 'none')
end

disp(' ')
disp('Complete.')