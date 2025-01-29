%% SEFWRITE Converts data into Servotest *.sef format
function sefwrite(filename, loggingrate, names, scales, units, matrix, comments)

% Get rid of char(32) at the end of each name
names_width=min([20 size(names,2)]);
units_width=min([10 size(units,2)]);
names=names(:,1:names_width);
units=units(:,1:units_width);

names=nospace(names,names_width);
units=nospace(units,units_width);

disp(['Writing: ', filename]);
disp('...');

%open the file
fid=fopen(filename,'w');

% Write the header file
str='Servotest Extensible Format';
[~, length] = size(str);

for i=1:length
   %output two character for wide character format
   count =fwrite(fid,str(i),'char');
   count =fwrite(fid,0,'char');
end
%for some reason the ID has an extra blank
fwrite(fid,0,'char');
fwrite(fid,0,'char');

%   Write the header information:
%       SampleRate
%       NumberOfSamples
%       NumberOfChannels
%       Description
%       DataPointer

% Description
[~,DescriptionSize]=size(comments);
if DescriptionSize > 0
    NumberOfEntries = 5;
else
   NumberOfEntries = 4;
end

header=zeros(1,4);
thispos = ftell(fid) + (16*NumberOfEntries) + 4; % allow for list terminator
i=1;

[samples, channels] = size(matrix);

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

% Flip and rotate header to get the right order
% Write the header
fwrite(fid, flipud(rot90(header)), 'long');

% List terminator
fwrite(fid,0,'long');

% Number of samples
[samples,channels] = size(matrix);
fwrite(fid, samples,'int64');
%sample rate
fwrite(fid, loggingrate, 'float32');

% Ddescription (if required)
if DescriptionSize > 0
   writestring(fid,comments);
end

% Channels
fwrite(fid, channels, 'int');

% Pointer list to channel information
pos=ftell(fid)+(channels * 8);
for i=1:channels
   fwrite(fid,pos+((i-1)* 52),'int64');
end

% Channel pointer
channeloffset = ftell(fid) + (((16 * 3)+4) * channels); %add list terminator
channellist=zeros(1,4);
c = 1;
for j=1:channels
   % Channel name
   channellist(c,1)=500;
   channellist(c,2)=channeloffset;
   channellist(c,4)=channellist(c,1)+channellist(c,2);
   [~,channelnamelen] = size(names);
   channeloffset = channeloffset+(4+ (channelnamelen *2));
   c=c+1;

   % Channel units
   channellist(c,1)=501;
   channellist(c,2)=channeloffset;
   channellist(c,4)=channellist(c,1)+channellist(c,2);
   [~,channelunitslen] = size(units);
   channeloffset = channeloffset+(4+ (channelunitslen *2));
   c=c+1;

   % Channel scales
   channellist(c,1)=502;
   channellist(c,2)=channeloffset;
   channellist(c,4)=channellist(c,1)+channellist(c,2);
   channeloffset = channeloffset + 4;

   % Write channel headers
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

% Data
datastart=ftell(fid);

% Go back and write the header position
fseek(fid,datahoffset,'bof');
fwrite(fid,103,'long');
fwrite(fid,datastart,'long');
fwrite(fid,0,'long');
fwrite(fid,datastart+103,'long');

% Go to data point
fseek(fid,datastart,'bof');

% Write the data
% De-scale the data
for i = 1:channels
   matrix(:,i) = matrix(:,i) / scales(i) ;
end

% Save the whole matrix in one go
fwrite(fid,matrix','float');

fclose(fid);

disp('Done');
disp('');

end
%% Subfunctions

% WRITESTRING outputs a string in wide character format and specifies length at the start
function writestring(fid,str)
[~, length] = size(str);
% Output twice the length (wide character format)
count = fwrite(fid,length,'int32');
    for i=1:length
       % Output two character for wide character format
       count =fwrite(fid,str(i),'char');
       count =fwrite(fid,0,'char');
    end
end

% NEWNAMES gets rid of char(32) at the end of each name
function newnames=nospace(names,lim)
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
end
