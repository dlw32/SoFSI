%% SEFWRITE Converts data into Servotest *.sef format

%   Inputs:
%   filename    - Output filename (string)
%   loggingrate - Sampling rate (float)
%   names       - Channel names (char array)
%   scales      - Scale factors (array)
%   units       - Units for each channel (char array)
%   matrix      - Data matrix (samples x channels)
%   comments    - File description (string)

function sefwrite(filename, loggingrate, names, scales, units, matrix, comments)

% Input validation
if nargin < 7
    comments = '';
end

% Get rid of trailing spaces in names and units
names_width = min(20, size(names, 2));
units_width = min(10, size(units, 2));
names = names(:, 1:names_width);
units = units(:, 1:units_width);

names = nospace(names, names_width);
units = nospace(units, units_width);

% Open file for writing
fid = fopen(filename, 'w');
if fid == -1
    error('Failed to open file for writing: %s', filename);
end

cleanup = onCleanup(@() fclose(fid)); % Ensure file gets closed

% Write file identifier
writeFileIdentifier(fid);

% Get matrix dimensions
[samples, channels] = size(matrix);

% Write header section
descriptionSize = length(comments);
numEntries = 4 + (descriptionSize > 0);
headerInfo = createHeaderInfo(fid, numEntries, samples, channels, descriptionSize);

% Write main header
fwrite(fid, flipud(rot90(headerInfo)), 'long');
fwrite(fid, 0, 'long'); % List terminator

% Write core data
fwrite(fid, samples, 'int64');
fwrite(fid, loggingrate, 'float32');

if descriptionSize > 0
    writestring(fid, comments);
end

% Write channel information
fwrite(fid, channels, 'int');

% Write channel pointers
writeChannelPointers(fid, channels);

% Write channel details
channeloffset = writeChannelDetails(fid, channels, names, units, scales);

% Write actual data
datastart = ftell(fid);
updateHeaderPosition(fid, datastart);

% Scale and write data matrix
matrix = matrix ./ scales'; % Vectorized scaling
fwrite(fid, matrix', 'float');

fprintf('Successfully wrote data to: %s\n', filename);
end

function writeFileIdentifier(fid)
    str = 'Servotest Extensible Format';
    for c = str
        fwrite(fid, [c 0], 'char');
    end
    fwrite(fid, [0 0], 'char'); % Extra blanks needed by format
end

function headerInfo = createHeaderInfo(fid, numEntries, samples, channels, descriptionSize)
    headerInfo = zeros(1, 4);
    thispos = ftell(fid) + (16 * numEntries) + 4;
    
    % Samples entry
    headerInfo(1, :) = [101, thispos, 0, 101 + thispos];
    thispos = thispos + 8;
    
    % Sample rate entry
    headerInfo(2, :) = [102, thispos, 0, 102 + thispos];
    thispos = thispos + 4;
    
    % Description entry (if present)
    i = 3;
    if descriptionSize > 0
        headerInfo(i, :) = [1, thispos, 0, 1 + thispos];
        thispos = thispos + (4 + (descriptionSize * 2));
        i = i + 1;
    end
    
    % Channels entry
    headerInfo(i, :) = [4, thispos, 0, 4 + thispos];
    thispos = thispos + 16 + (16 * channels);
    
    % Data entry
    headerInfo(i+1, :) = [103, 0, 0, 103];
end

function writeChannelPointers(fid, channels)
    pos = ftell(fid) + (channels * 8);
    channelPositions = pos + ((0:channels-1) * 52);
    fwrite(fid, channelPositions, 'int64');
end

function channeloffset = writeChannelDetails(fid, channels, names, units, scales)
    channeloffset = ftell(fid) + (((16 * 3) + 4) * channels);
    [~, namelen] = size(names);
    [~, unitslen] = size(units);
    
    for j = 1:channels
        % Create and write channel list
        channellist = [
            500, channeloffset, 0, 500 + channeloffset;
            501, channeloffset + (4 + namelen * 2), 0, 501 + channeloffset + (4 + namelen * 2);
            502, channeloffset + (4 + namelen * 2) + (4 + unitslen * 2), 0, 502 + channeloffset + (4 + namelen * 2) + (4 + unitslen * 2)
        ];
        
        fwrite(fid, flipud(rot90(channellist)), 'long');
        fwrite(fid, 0, 'long');
        
        channeloffset = channeloffset + (4 + namelen * 2) + (4 + unitslen * 2) + 4;
    end
    
    % Write channel data
    for j = 1:channels
        writestring(fid, names(j,:));
        writestring(fid, units(j,:));
        fwrite(fid, scales(j), 'float');
    end
end

function updateHeaderPosition(fid, datastart)
    datahoffset = 56;
    fseek(fid, datahoffset, 'bof');
    fwrite(fid, [103, datastart, 0, datastart + 103], 'long');
    fseek(fid, datastart, 'bof');
end

function writestring(fid, str)
    [~, len] = size(str);
    fwrite(fid, len, 'int32');
    for i = 1:len
        fwrite(fid, [str(i) 0], 'char');
    end
end

function newnames = nospace(names, lim)
    dnames = double(names);
    [nchans, nchars] = size(dnames);
    dzeros = zeros(nchans, lim);
    
    for i = 1:nchans
        for j = nchars:-1:1
            if dnames(i,j) == 32
                dnames(i,j) = 0;
            else
                break
            end
        end
    end
    
    dzeros(:, 1:min(nchars, lim)) = dnames;
    newnames = char(dzeros);
end