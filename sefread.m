function [loggingrate, names, units, comments, matrix, ScaleArry, read_error] = sefread(filename)
%% SEFREAD reads Servotest .sef files into MATLAB with debug messages
try % For error handling

    read_error = 1;     % Default to 1
    loggingrate = [];   % Sample rate
    names = {};         % Channel names
    units = {};         % Channel units
    comments = '';      % File comments
    matrix = [];        % Data
    ScaleArry = [];     % Channel scales
    
    fid_veh = fopen(filename, 'r');
    if fid_veh == -1
        error('Failed to open file: %s', filename);
    end
    
    fseek(fid_veh, 56, 'bof');
    disp(['Reading SEF File: ', filename]);
    
    while (~feof(fid_veh))
        datablock = fread(fid_veh, 4, 'long');
        if isempty(datablock) || feof(fid_veh)
            break;
        end
        disp(['Datablock: ', num2str(datablock')]);
        
        switch datablock(1)
            case 0
                break;
            case 1
                % Comments
                comments = char(GetParameterStr(fid_veh, datablock(2)));
                disp(['Comments: ', comments]);
            case 102
                % Sample rate
                loggingrate = GetParameter(fid_veh, datablock(2), 'float32');
                disp(['Logging rate: ', num2str(loggingrate)]);
            case 101
                % No. of samples
                samples = GetParameter(fid_veh, datablock(2), 'int64');
                disp(['Number of samples: ', num2str(samples)]);
            case 4
                % No. of channels
                channels = GetParameter(fid_veh, datablock(2), 'int');
                disp(['Number of channels: ', num2str(channels)]);
                if isempty(channels) || channels <= 0
                    error('Invalid number of channels detected.');
                end
                % Preallocate arrays
                ScaleArry = ones(channels, 1);
                names = cell(channels, 1);
                units = cell(channels, 1);
                
                store = ftell(fid_veh);
                channelptr = datablock(2) + 4;
                for i = 1:channels
                    fseek(fid_veh, channelptr, 'bof');
                    ptrChannels = fread(fid_veh, 1, 'int64');
                    fseek(fid_veh, ptrChannels, 'bof');
                    while (~feof(fid_veh))
                        Chandatablock = fread(fid_veh, 4, 'long');
                        switch Chandatablock(1)
                            case 0
                                break;
                            case 500
                                names{i} = char(GetParameterStr(fid_veh, Chandatablock(2)));
                                disp(['Channel ', num2str(i), ' Name: ', names{i}]);
                            case 501
                                units{i} = char(GetParameterStr(fid_veh, Chandatablock(2)));
                                disp(['Channel ', num2str(i), ' Unit: ', units{i}]);
                        end
                    end
                    channelptr = channelptr + 8;
                end
                fseek(fid_veh, store, 'bof');
            case 103
                if exist('channels', 'var') && exist('samples', 'var')
                    fseek(fid_veh, datablock(2), 'bof');
                    matrix = fread(fid_veh, [channels samples], 'float')';
                    disp('Matrix data read successfully.');
                    read_error = 0;
                else
                    error('Channels or samples not defined before reading matrix.');
                end
            otherwise
                disp(['Unknown datablock type: ', num2str(datablock(1))]);
        end
    end
    
    fclose(fid_veh);
catch ME % Display error message in case of failure
    fprintf('Error reading SEF file: %s\n', ME.message);
end
end

%% Subfunctions with debug messages
function value = GetParameter(fid, offset, type)
    current = ftell(fid);
    fseek(fid, offset, 'bof');
    value = fread(fid, 1, type);
    disp(['GetParameter(', type, ') at offset ', num2str(offset), ': ', num2str(value)]);
    fseek(fid, current, 'bof');
end

function value = GetParameterStr(fid, offset)
    current = ftell(fid);
    fseek(fid, offset, 'bof');
    length = fread(fid, 1, 'int32');
    value = fread(fid, length, 'int16')';
    value(value < 0) = 256 + value(value < 0);
    value = char(value);
    disp(['String parameter at offset ', num2str(offset), ': ', value]);
    fseek(fid, current, 'bof');
end
