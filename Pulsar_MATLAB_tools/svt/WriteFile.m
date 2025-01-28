function WriteFile(filename, loggingrate, names, scales, units, matrix, comments)
% WriteFile(filename, loggingrate, names, scales, units, matrix, comments)
%
% filename should have the extension '.sbf', '.sbr', '.sef' or '.mat'

extension= filename(length(filename)-2:length(filename));

switch(lower(extension))

case('sbf')
   sbfsave(filename, loggingrate,names,scales,units,comments,matrix,5);
case('sbr')
   sbrsave(filename, loggingrate,names,scales,units,comments,matrix,5);
case('mat')
   matsave(filename, loggingrate,names,scales,units,comments,matrix,1);
case('sef')
   sefsave(filename, loggingrate,names,scales,units,comments,matrix,1);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sbfsave(filename,loggingrate,names,scales,units,comments,matrix,version)
%%%%%%%%
%
%       Function :      sbfsave.m
%       Description:    save data in sbf format
%
%
%%%%%%%%

if nargin < 8

   version = 5;                    % Force to version 5 format in no version specified

end

if filename == 0 ; return; end

max_path                        = 260;
max_descr_size_v2               = 256;
maxlen_signalname               = 20;
maxlen_units                    = 10;
max_channels                    = 16;
full_scale_int                  = 30000;
maxlen_identifier               = 28;
maxlen_channel_description      = 50;

length_channelmap_struct = maxlen_channel_description + maxlen_signalname + 2;

[NumberOfSamples, NumberOfChannels] = size(matrix);

if NumberOfChannels > max_channels; NumberOfChannels =max_channels; servodisp('WARNING: Too many channels to save to SBF format.');end

if version == 3

   data_data_offset        = 2206;

   max_actuators           = 8;

   no_channels_in_file     = 16;                   % Depicts final size of data written to disk

elseif version == 4

   data_data_offset        = 3072;

   max_actuators           = 8;

   no_channels_in_file     = 2^(ceil(log10(NumberOfChannels)/log10(2)));           % Must be  2,4, 8 or 16
   if no_channels_in_file == 1; no_channels_in_file =2; end

elseif version == 5

   data_data_offset        = 3584;

   max_actuators           = 16;

   no_channels_in_file     = 2^(ceil(log10(NumberOfChannels)/log10(2)));           % Must be  2,4, 8 or 16
   if no_channels_in_file == 0; no_channels_in_file =2; end

end

HeaderSize      = data_data_offset;


% Clear the necessary fixed dimension arrays;

ParentFilePath  =zeros(1,max_path);

Description1    =zeros(1,max_descr_size_v2);
Description2    =zeros(1,max_descr_size_v2);
Description3    =zeros(1,max_descr_size_v2);

ChannelMappingSt=zeros(length_channelmap_struct,max_actuators);

file_identifier = 'Servotest Binary Format File';

if length(cd) > max_path

   comment_length = max_path;
else
   comment_length = length(cd);

end

cd_dir = cd;

ParentFilePath(1,1:comment_length)        = cd_dir(1,1:comment_length);

DataLoggedTime  = 0;

if length(comments) > max_descr_size_v2

   comment_length = max_descr_size_v2;
else
   comment_length = length(comments);

end

if exist(comments)
    Description1(1,1:comment_length)      = comments(1,1:comment_length);
end

% Setup names array
ChannelNameArrayT = char(zeros(maxlen_signalname,max_channels));

[array_length,array_width] = size(names);

if array_length > max_channels
   array_length = max_channels;
end
if array_width > maxlen_signalname
   array_width = maxlen_signalname;
end

ChannelNameArrayT(1:array_width,1:array_length)= names(1:array_length,1:array_width)';
% Take the TRANSPOSE

% Setup scales array

ScaleArry = ones(max_channels,1);

array_length = length(scales);

if array_length > max_channels
   array_length = max_channels;
end

ScaleArry(1:array_length,1)     = scales(1:array_length,1);


% Setup units array

UnitsArryT = char(zeros(maxlen_units,max_channels));

[array_length,array_width] = size(units);

if array_length > max_channels
   array_length = max_channels;
end
if array_width > maxlen_units
   array_width = maxlen_units;
end

UnitsArryT(1:array_width,1:array_length) = units(1:array_length,1:array_width)';


NumberOfActs    = 0;                                            % LOCKS UP REPLAY IF OTHER THAN 0

npts            = 1024;                                         % no.of points per frame
indep           = fix(NumberOfSamples/loggingrate);             % no. of indep. frames
repet           = 1;                                            %
nfram           = fix(NumberOfSamples/npts);                    % Total no. frames in history
ptblk           = 2048;                                         % no. of points per demultiplexor block

% Convert from Engineering units to integer +/- 30000

matrix_op = zeros(no_channels_in_file,NumberOfSamples);        % Needs to be like this to save to disk

for i=1:NumberOfChannels

   matrix_op(i,:)= round(matrix(:,i)'./scales(i,1)*full_scale_int);

   max_val = max(matrix_op(i,:));
   min_val = min(matrix_op(i,:));

   if max_val > full_scale_int || min_val < -full_scale_int

      servodisp( ' ');
      servodisp( ' *******');
      servodisp([' WARNING : Data limiting on channel ',num2str(i)])

      servodisp( ' *******');
      servodisp( ' ');
   end

   if (max_val - min_val) < 600                           % Check if less than +/- 2%

      servodisp([' WARNING: Data resolution is ',dispnumb((max_val - min_val)/2/full_scale_int*100,3,2),' %  on channel ',num2str(i)]);
   end
end
fid_veh = fopen(filename,'w');

fwrite(fid_veh,file_identifier ,'char');
fwrite(fid_veh,version ,'short');
fwrite(fid_veh,ParentFilePath ,'char');
fwrite(fid_veh,DataLoggedTime ,'long');
fwrite(fid_veh,Description1 ,'char');
fwrite(fid_veh,Description2 ,'char');
fwrite(fid_veh,Description3 ,'char');
fwrite(fid_veh,loggingrate ,'float');
fwrite(fid_veh,HeaderSize,'short');
fwrite(fid_veh,NumberOfSamples,'long');
fwrite(fid_veh,NumberOfChannels,'short');
fwrite(fid_veh,ChannelNameArrayT,'char');
fwrite(fid_veh,ScaleArry ,'float');
fwrite(fid_veh,UnitsArryT,'char');
fwrite(fid_veh,NumberOfActs ,'short');

fwrite(fid_veh,ChannelMappingSt,'char');

fwrite(fid_veh, npts,'short');
fwrite(fid_veh,indep,'short');
fwrite(fid_veh,repet,'short');
fwrite(fid_veh,nfram,'short');
fwrite(fid_veh,ptblk,'short');

if version == 4 || version == 5

   fwrite(fid_veh,0,'short');                               % NOT raw data (i.e. DONT need what follows)

   fwrite(fid_veh,zeros(max_channels,1) ,'float');
   fwrite(fid_veh, ones(max_channels,1) ,'float');          % X   terms
   fwrite(fid_veh,zeros(max_channels,1) ,'float');          % X^2 terms
   fwrite(fid_veh,zeros(max_channels,1) ,'float');
   fwrite(fid_veh,zeros(max_channels,1) ,'float');
   fwrite(fid_veh,zeros(max_channels,1) ,'float');
   fwrite(fid_veh,zeros(max_channels,1) ,'float');

   fwrite(fid_veh,no_channels_in_file,'short');             % Must be 2,4,8 or 16, possible confusion with NumberOfChannels (above)

   current_position = ftell(fid_veh);

   padding = fix(data_data_offset - current_position)/2;

   fwrite(fid_veh,zeros(padding+2,1),'short');              % Write past data storage boundary

end


fseek(fid_veh,data_data_offset,'bof');

count = fwrite(fid_veh,matrix_op ,'short');


if count ~= NumberOfSamples*no_channels_in_file

   servodisp(' WARNING: DATA TRUNCATED! (Hard disk could be FULL)');
   servodisp(['  Data to be    saved : ',sprintf('%8i',NumberOfSamples*no_channels_in_file)]);
   servodisp(['  Data actually saved : ',sprintf('%8i',count)]);

end

file_pos = ftell(fid_veh);

servodisp(['  File Size : ',sprintf('%2.6f',file_pos/1e6),' Mbytes.']);

current_dir = cd;

if isempty(findstr(filename,'\'))
    % filename contains path
   servodisp([' Data written to file : ',current_dir,'\',filename, ' on disk ']);
else
   servodisp([' Data written to file : ',filename, ' on disk ']);
end
fclose(fid_veh);

%_______________________________________________________________________________________________________________

function sbrsave(filename,loggingrate,names,scales,units,comments,matrix,version)
%
% save data in SBR format

if nargin < 8

   version = 5;                    % Force to version 5 format in no version specified

end

if filename == 0 ; return; end

max_path                        = 260;
max_descr_size_v2               = 256;
maxlen_signalname               = 20;
maxlen_units                    = 10;
max_channels                    = 16;
full_scale_int                  = 30000;
maxlen_identifier               = 28;
maxlen_channel_description      = 50;

length_channelmap_struct = maxlen_channel_description + maxlen_signalname + 2;

[NumberOfSamples, NumberOfChannels] = size(matrix);

% disp([' Number Of Samples SAVED : ',sprintf('%8i',NumberOfSamples)]);

if NumberOfChannels > max_channels; NumberOfChannels =max_channels; servodisp('WARNING: Too many channels to save to SBR format.');end

if version == 3

   data_data_offset        = 2206;

   max_actuators           = 8;

   % no_channels_in_file     = 2^(ceil(log10(NumberOfChannels)/log10(2)));          % Must be  2,4, 8 or 16
   % if no_channels_in_file == 1; no_channels_in_file =2; end
   no_channels_in_file     = 8;

elseif version == 4

   data_data_offset        = 3072;

   max_actuators           = 8;

   no_channels_in_file     = 2^(ceil(log10(NumberOfChannels)/log10(2)));           % Must be  2,4, 8 or 16
   if no_channels_in_file == 1; no_channels_in_file =2; end


elseif version == 5

   data_data_offset        = 3584;

   max_actuators           = 16;

   no_channels_in_file     = 2^(ceil(log10(NumberOfChannels)/log10(2)));           % Must be  2,4, 8 or 16
   if no_channels_in_file == 0; no_channels_in_file =2; end

end

if NumberOfChannels > max_actuators; NumberOfChannels = max_actuators; servodisp('WARNING: Too many channels to save to required SBR format.');end

HeaderSize      = data_data_offset;


% Clear the necessary fixed dimension arrays;

ParentFilePath  =zeros(1,max_path);

Description1    =zeros(1,max_descr_size_v2);
Description2    =zeros(1,max_descr_size_v2);
Description2(1:31) = 'SBR file generated from MATLAB.';
Description3    =zeros(1,max_descr_size_v2);

file_identifier = 'Servotest Binary Format File';

if length(cd) > max_path

   comment_length = max_path;
else
   comment_length = length(cd);

end

cd_dir = cd;

ParentFilePath(1,1:comment_length)        = cd_dir(1,1:comment_length);

DataLoggedTime  = 0;

if length(comments) > max_descr_size_v2

   comment_length = max_descr_size_v2;
else
   comment_length = length(comments);

end

if exist(comments)
    Description1(1,1:comment_length)      = comments(1,1:comment_length);
end

% Setup names array

ChannelNameArrayT = char(zeros(maxlen_signalname,max_channels));

[array_length,array_width] = size(names);

if array_length > max_channels
   array_length = max_channels;
end
if array_width > maxlen_signalname
   array_width = maxlen_signalname;
end

ChannelNameArrayT(1:array_width,1:array_length)= names(1:array_length,1:array_width)';
% Take the TRANSPOSE
% Setup Channel Mapping Array

ChannelMappingSt=char(zeros(max_actuators,maxlen_channel_description+2+maxlen_signalname));

if array_length > max_actuators
   array_length = max_actuators;
end

for i=1:NumberOfChannels

   ChannelMappingSt(i,maxlen_signalname+1) = i;
   ChannelMappingSt(i,1:length(['Drive Signal ',num2str(i)])) = ['Drive Signal ',num2str(i)];

end

ChannelMappingSt(1:array_length,maxlen_signalname+3:maxlen_signalname+2+array_width)= names(1:array_length,1:array_width);

% Setup scales array

ScaleArry = ones(max_channels,1);

array_length = length(scales);

if array_length > max_channels
   array_length = max_channels;
end

ScaleArry(1:array_length,1)     = scales(1:array_length,1);


% Setup units array

UnitsArryT = char(zeros(maxlen_units,max_channels));

[array_length,array_width] = size(units);

if array_length > max_channels
   array_length = max_channels;
end
if array_width > maxlen_units
   array_width = maxlen_units;
end

UnitsArryT(1:array_width,1:array_length) = units(1:array_length,1:array_width)';

NumberOfActs    =  no_channels_in_file;

npts            = 1024;                                         % no.of points per frame
indep           = fix(NumberOfSamples/loggingrate);             % no. of indep. frames
repet           = 1;                                            %
nfram           = fix(NumberOfSamples/npts);                    % Total no. frames in history
ptblk           = 2048;                                         % no. of points per demultiplexor block

% Convert from Engineering units to integer +/- 30000

matrix_op = zeros(no_channels_in_file,NumberOfSamples);

for i=1:NumberOfChannels

   matrix_op(i,:)= round(matrix(:,i)'./scales(i,1)*full_scale_int);

   max_val = max(matrix_op(i,:));
   min_val = min(matrix_op(i,:));

   if max_val > full_scale_int | min_val < -full_scale_int

      servodisp( ' ');
      servodisp( ' *****************************************************************');
      servodisp([' WARNING : Data in channel ',num2str(i),' exceeds full scale.'])
      servodisp( ' *****************************************************************');
      servodisp( ' ');
   end

   if (max_val - min_val) < 600                           % Check if less than +/- 2%

      servodisp([' WARNING: Data resolution is ',dispnumb((max_val - min_val)/2/full_scale_int*100,3,2),' %  on channel ',num2str(i)]);
   end
end

fid_veh = fopen(filename,'w');

fwrite(fid_veh,file_identifier ,'char');
fwrite(fid_veh,version ,'short');
fwrite(fid_veh,ParentFilePath ,'char');
fwrite(fid_veh,DataLoggedTime ,'long');
fwrite(fid_veh,Description1 ,'char');
fwrite(fid_veh,Description2 ,'char');
fwrite(fid_veh,Description3 ,'char');
fwrite(fid_veh,loggingrate ,'float');
fwrite(fid_veh,HeaderSize,'short');
fwrite(fid_veh,NumberOfSamples,'long');
fwrite(fid_veh,NumberOfChannels,'short');
fwrite(fid_veh,ChannelNameArrayT,'char');
fwrite(fid_veh,ScaleArry ,'float');
fwrite(fid_veh,UnitsArryT,'char');
fwrite(fid_veh,NumberOfActs ,'short');

fwrite(fid_veh,ChannelMappingSt','char');

fwrite(fid_veh, npts,'short');
fwrite(fid_veh,indep,'short');
fwrite(fid_veh,repet,'short');
fwrite(fid_veh,nfram,'short');
fwrite(fid_veh,ptblk,'short');

if version == 4 || version == 5

   fwrite(fid_veh,0,'short');                               % NOT raw data (i.e. DONT need what follows)

   fwrite(fid_veh,zeros(max_channels,1) ,'float');
   fwrite(fid_veh, ones(max_channels,1) ,'float');          % X   terms
   fwrite(fid_veh,zeros(max_channels,1) ,'float');          % X^2 terms
   fwrite(fid_veh,zeros(max_channels,1) ,'float');
   fwrite(fid_veh,zeros(max_channels,1) ,'float');
   fwrite(fid_veh,zeros(max_channels,1) ,'float');
   fwrite(fid_veh,zeros(max_channels,1) ,'float');

   fwrite(fid_veh,no_channels_in_file,'short');             % Must be 2,4,8 or 16, possible confusion with NumberOfChannels (above)

   current_position = ftell(fid_veh);

   padding = fix(data_data_offset - current_position)/2;

   fwrite(fid_veh,zeros(padding+2,1),'short');              % Write past data storage boundary


end

fseek(fid_veh,data_data_offset,'bof');

count = fwrite(fid_veh,matrix_op,'short');

if count ~= NumberOfSamples*no_channels_in_file

   servodisp(' WARNING: DATA TRUNCATED! (Hard disk could be FULL)');
   servodisp(['  Data to be    saved : ',sprintf('%8i',NumberOfSamples*no_channels_in_file)]);
   servodisp(['  Data actually saved : ',sprintf('%8i',count)]);

end

file_pos = ftell(fid_veh);

servodisp(['  File Size : ',sprintf('%2.6f',file_pos/1e6),' Mbytes.']);

current_dir = cd;

servodisp([' Data written to file : ',filename, ' on disk ']);

fclose(fid_veh);

%___________________________________________________________________________________________________________

function matsave(filename,loggingrate,names,scales,units,comments,matrix,version)
%%%%%%%%
%
%       Function :      matsave.m
%       Description:    save data in mat format
%
%
%%%%%%%%

if filename == 0 ; return; end

save(filename,'loggingrate', 'names', 'scales', 'units', 'comments', 'matrix');

%___________________________________________________________________________________________________________

function sefsave(filename1,loggingrate,names,scales,units,comments,matrix,version)

%%%%%%%%%%%%%%%%%%%
%
%   Function :      sefsave
%
%   Descrption :    Outputs the data in Servotest Extensible File Format
%
%%%%%%%%%%%%%%%%%%%

% Get rid of char(32) at the end of each name
names_width=min([20 size(names,2)]);
units_width=min([10 size(units,2)]);
names=names(:,1:names_width);
units=units(:,1:units_width);

names=nospace(names,names_width);
units=nospace(units,units_width);

servodisp('-------------------------------------------------');
servodisp('     Writing Servotest Extensible File Format    ');
servodisp('                                                 ');
servodisp([' Filename : ', filename1]);
servodisp('                                                 ');
servodisp('                Please Wait...                   ');

%open the file
fid=fopen(filename1,'w');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   write the header file
%
str='Servotest Extensible Format';
[dummy, length] = size(str);

for i=1:length
   %output two character for wide character format
   count =fwrite(fid,str(i),'char');
   count =fwrite(fid,0,'char');
end
%for some reason the ID has an extra blank
fwrite(fid,0,'char');
fwrite(fid,0,'char');
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Write the header information
%
%   We have the following information to write
%       SampleRate
%       NumberOfSamples
%       NumberOfChannels
%       Description
%       DataPointer

%Description
[dummy,DescriptionSize]=size(comments);
if DescriptionSize > 0
    NumberOfEntries = 5;
else
   NumberOfEntries = 4;
end

header=zeros(1,4);
thispos = ftell(fid) + (16*NumberOfEntries) + 4; % allow for list terminator
i=1;

[samples,channels] = size(matrix);

% Samples
header(i,1)=101;
header(i,2)=thispos;
header(i,4)=header(i,1)+header(i,2);
thispos = thispos+8; % 64 bit integer
i=i+1;

% Sample rate
header(i,1)=102;
header(i,2)=thispos;
header(i,4)=header(i,1)+header(i,2);
thispos = thispos+4; % 32 bit floating point
i=i+1;


if DescriptionSize > 0
   header(i,1)=1;
   header(i,2)=thispos;
   header(i,4)=header(i,1)+header(i,2);
   % Add a long string length and allow for wide characters
   thispos = thispos + (4 + (DescriptionSize * 2));
   i=i+1;

end

% Channels
header(i,1)=4;
header(i,2)=thispos;
header(i,4)=header(i,1)+header(i,2);
thispos = thispos+16+(16 * channels); % integer followed by list of channel pointers
i=i+1;


% Data
% we need to remeber where we are so that we can write the correct offset
datahoffset = (i-1)*16 + 56;
header(i,1)=103;
header(i,2)=0;
header(i,4)=header(i,1)+header(i,2);


%flip and rotate header to get the right order
% Write the header
fwrite(fid, flipud(rot90(header)), 'long');

%list terminator
fwrite(fid,0,'long');

%Number of samples
[samples,channels] = size(matrix);
fwrite(fid, samples,'int64');
%sample rate
fwrite(fid, loggingrate, 'float32');

%description (if required)
if DescriptionSize > 0
   writestring(fid,comments);
end

%channels
fwrite(fid, channels, 'int');

% pointer list to channel information
pos=ftell(fid)+(channels * 8);
for i=1:channels
   fwrite(fid,pos+((i-1)* 52),'int64');
end

%channel pointer
channeloffset = ftell(fid) + (((16 * 3)+4) * channels); %add list terminator
channellist=zeros(1,4);
c = 1;
for j=1:channels
   % channel name
   channellist(c,1)=500;
   channellist(c,2)=channeloffset;
   channellist(c,4)=channellist(c,1)+channellist(c,2);
   [dummy,channelnamelen] = size(names);
   channeloffset = channeloffset+(4+ (channelnamelen *2));
   c=c+1;

   % channel units
   channellist(c,1)=501;
   channellist(c,2)=channeloffset;
   channellist(c,4)=channellist(c,1)+channellist(c,2);
   [dummy,channelunitslen] = size(units);
   channeloffset = channeloffset+(4+ (channelunitslen *2));
   c=c+1;

   % channel scales
    channellist(c,1)=502;
   channellist(c,2)=channeloffset;
   channellist(c,4)=channellist(c,1)+channellist(c,2);
   channeloffset = channeloffset + 4;

   %write channel headers
    %chanout = flipud(rot90(channellist));
    fwrite(fid,flipud(rot90(channellist)),'long');
   fwrite(fid,0,'long');
   c=1;
   channellist=zeros(1,4);


end


for j=1:channels
   writestring(fid,names(j,:));
   writestring(fid,units(j,:));
   fwrite(fid,scales(j),'float');
end

%data
datastart=ftell(fid);

%go back and write the header position
fseek(fid,datahoffset,'bof');
fwrite(fid,103,'long');
fwrite(fid,datastart,'long');
fwrite(fid,0,'long');
fwrite(fid,datastart+103,'long');

%go to data point
fseek(fid,datastart,'bof');

%write the data
% we need to de-scale the data
for i = 1:channels
   matrix(:,i) = matrix(:,i) / scales(i) ;
end

% for i = 1:samples
%   fwrite(fid,matrix(i,:),'float');
% end

% We now save the whole matrix in one go - VB, March 2002.
fwrite(fid,matrix','float');

fclose(fid);

servodisp('                                                 ');
servodisp('                   Complete                      ');
servodisp('-------------------------------------------------');

function writestring(fid,str)

%%%%%%%%%%%%%%%%%
%
%   Function :      WriteString
%
%   Description :   Outputs a string in wide character format and specifies length at the start
%
%%%%%%%%%%%%%%%%%

[dummy, length] = size(str);

%output twice the length (wide character format)
count = fwrite(fid,length,'int32');

for i=1:length
   %output two character for wide character format
   count =fwrite(fid,str(i),'char');
   count =fwrite(fid,0,'char');
end

function newnames=nospace(names,lim)
% Get rid of char(32) at the end of each name
dnames=double(names);
[nchans,nchars]=size(dnames);
dzeros=zeros(nchans,lim);
for i=1:nchans
    for j=nchars:-1:1
        if dnames(i,j)==32
            dnames(i,j)=0;
        else
            break;
        end
    end
end
dzeros(:,1:min(nchars,lim))=dnames;
newnames=char(dzeros);
