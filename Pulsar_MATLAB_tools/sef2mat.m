%%  SEF2MAT Converts Servotest.sef files to .mat.
% Allows for selection of multiple files for batch conversion.

function sef2mat
        
%% Select files for conversion
[FNin,PN,~] = uigetfile({'*.sef','Files to covert (*.sef)'},'Select .sef files for conversion','MultiSelect','on');

% Action if user closes gui
    if FNin==0
        disp('User requested to close file selection dialogue.') 
        disp(' ')
        return
    end

% Ensures FNin is cell array
    if ~iscell(FNin)
        FNin = {FNin};
    end

% Set working directory to match selected files
cd(PN)

%% Convert each selected file to .mat and save in user selected dir

output_dir = uigetdir('','Select a folder to save .mat files');

for r = 1:length(FNin)
    FN = FNin{r};
    FInfo = dir(FN);                      % Creates empty struct array
    FInfo.conversion=append('Converted to .mat format using ',mfilename,' on ', string(datetime));
    dot = max(strfind(FN,'.'));
    FN = FN(1:dot-1);
    FN = matlab.lang.makeValidName(FN);

    % Convert .sef using sefread subfunction
    [loggingrate,names,units,comments,matrix,scales,read_error] = sefread(FNin{r});

    output = struct('sefFileInfo',FInfo,'comments', comments,'loggingrate',loggingrate,'matrix',matrix,'names',char(names),'read_error',read_error,'scales',scales,'units',char(units));
    
    disp(['Writing MAT file : ' output_dir filesep FN '.mat'])

    % Export converted data as .mat file
     if isfile([output_dir filesep FN '.mat']) % prompt for user input re. overwriting files
        answer = questdlg([FN '.mat already exists.'],'File I/O error','Overwrite','Skip','Overwrite');
        switch answer
            case 'Overwrite'
                save(fullfile(output_dir, filesep, FN),'output')
            case 'Skip'
                disp(['User requested to skip overwriting ' FN '.mat'])
            case ''
                disp(['Dialog closed - skip overwriting ' FN '.mat'])
        end
        else
            eval([FN ' = output;']);
            save(fullfile(output_dir, filesep, FN), FN);
     end

    cd(output_dir)
    disp('... done')
    disp(' ')

end
end
