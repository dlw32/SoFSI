%% CONVERT2SEF Convert acceleration time histories to Servotest .sef format from .txt or .csv input. Will handle multiple files.

%{
Usage:
Type convert2sef and enter the required information when prompted. Or
provide input when calling function using:

convert2sef('InputRate', 512, 'NumChannels', 3)

sefwrite.m must be in the current MATLAB path.
%}

function convert2sef(varargin)

    % Create input parser
    p = inputParser;
    
    % Add optional parameters with validation
    addParameter(p, 'NumChannels', [], @(x) isnumeric(x) && ~isnan(x));
    addParameter(p, 'InputRate', [], @(x) isnumeric(x) && ~isnan(x));
       
    % Parse inputs
    parse(p, varargin{:});
    
    % Get parsed inputs
    num_channels = p.Results.NumChannels;
    inputrate = p.Results.InputRate;
    
    % Prompt if not provided
    if isempty(inputrate)
        inputrate = input('Enter the sample rate of the input data: ');
        if isempty(inputrate) || ~isnumeric(inputrate) || isnan(inputrate)
            error('Invalid input. Please enter a numeric value for the sample rate.');
        end
    end
    if isempty(num_channels)
        num_channels = input('Enter number of channels: ');
        if isempty(num_channels) || ~isnumeric(num_channels) || isnan(num_channels)
            error('Invalid input. Please enter a numeric value for the number of channels.');
        end
    end
    % Default output sample rate is 512 - modify this if needed.
    loggingrate = 512;
    % A default 3 second tail is added before and after data.
    tailsecs = 3; 

    % Dynamic channel configuration
    names = cell(1, num_channels);
    scales = ones(1, num_channels);
    units = cell(1, num_channels);

    % Get channel names
    for i = 1:num_channels
        names{i} = input(['Enter name for channel ' num2str(i) ': '], 's');
    end

    % Get channel units
    for i = 1:num_channels
        units{i} = input(['Enter units for channel ' num2str(i) ': '], 's');
    end

    % Convert to character array for WriteFile compatibility
    names = char(names);
    units = char(units);

    % Generate comments
    comments = ['SEF input file generated using convert2sef.m on ', char(datetime)];

    % Select files for conversion
    [FNin, folder] = uigetfile('*.*', 'Select input files', 'MultiSelect', 'on');

    % Normalize file selection to cell array
    if ~iscell(FNin)
        if FNin == 0
            disp('User closed file selection interface');
            return
        end
        FNsave{1} = fullfile(folder, FNin);
    else
        FNsave = fullfile(folder, FNin);
    end

%% Generate .sef file for each selected file
    for r = 1:length(FNsave)
        FN = FNsave{r};
        
        % Remove file extension from filename
        FNd = double(FN);
        FNnoext = char(FNd(1:max(find(FNd==46)-1)));
        %SN = matlab.lang.makeValidName(FNnoext);

        % Read the file and detect header lines
        fid = fopen(FNsave{r}, 'r');
        header_lines = 0;
        
        % Attempt to detect header lines by trying to convert first line to numbers
        while ~feof(fid)
            line = fgetl(fid);
            try
                test_data = str2num(line); %#ok<ST2NM>
                
                if isempty(test_data)
                    header_lines = header_lines + 1;
                else
                    break;
                end
            catch
                header_lines = header_lines + 1;
            end
        end
        
        % Reset file pointer to beginning
        fseek(fid, 0, 'bof');
        
        % Skip header lines
        for i = 1:header_lines
            fgetl(fid);
        end
        
        % Read data, skipping previously identified header lines
        data = readmatrix(FN, 'NumHeaderLines', header_lines);
        fclose(fid);

        % Resample data to selected sample rate
        data = resample(data, loggingrate, inputrate);

        % Add tails before and after data
        tail = zeros(tailsecs*loggingrate, size(data, 2));
        matrix = [tail; data; tail];

        % Create full path for output file in the same directory as input file
        filename = fullfile([FNnoext '_target.sef']);
        
        % Write file
        WriteFile(filename, loggingrate, names, scales, units, matrix, comments);
    end
end