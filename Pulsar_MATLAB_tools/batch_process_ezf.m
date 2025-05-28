%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Batch process function to automate setup of EZFlows for use in Pulsar
%
% Prerequisites (selected by GUI):
%         - a template .ezf file
%         - a .csv file listing the full file paths of drive files in the
%               format 'fullFilePath\...\Drive_filename.sef'
% 
% The function uses the template .ezf to extract the template filename and
% filepath, then replaces this with the filenames and filepaths in the .csv
% list. 
% 
% The output is a batch of .ezf files with filenames matching the
% input.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function batch_process_ezf()
    
    %% Input selection

    % GUI file selection for template .ezf file
    [ezf_file, ezf_path] = uigetfile('*.ezf', 'Select template .ezf file');
    if isequal(ezf_file, 0)
        fprintf('No template file selected. Exiting.\n');
        return;
    end
    template_ezf = fullfile(ezf_path, ezf_file);
    
    % GUI file selection for CSV file
    [csv_file, csv_path] = uigetfile('*.csv', 'Select CSV file with input names');
    if isequal(csv_file, 0)
        fprintf('No CSV file selected. Exiting.\n');
        return;
    end
    csv_file = fullfile(csv_path, csv_file);
    
    %% Read the template .ezf file
    fprintf('Reading template file: %s\n', template_ezf);
    fid = fopen(template_ezf, 'r');
    if fid == -1
        error('Cannot open template file: %s', template_ezf);
    end
    
    % Read each line in the .ezf file
    template_lines = {};
    line_count = 0;
    while ~feof(fid)
        line = fgetl(fid);
        if ischar(line)
            line_count = line_count + 1;
            template_lines{line_count} = line;
        end
    end
        
    % Join lines with newline
    template_content = strjoin(template_lines, newline);
    fclose(fid);
    
    %% Read CSV file containing input names
    fprintf('Reading CSV file: %s\n', csv_file);
    % Read drive file paths
    input_names = readcell(csv_file, 'Delimiter', ',');
    if isempty(input_names)
        error('No input names found in CSV file');
    end
    fprintf('Found %d input files to process\n', length(input_names));
   
    %% Extract original drive file path and name

    % Extract path of drive file folder
    drive_file_pos = strfind(input_names{1}, 'Drive files\');
    if ~isempty(drive_file_pos)
        drive_file_dir = input_names{1}(1:drive_file_pos + length('Drive files\') - 1);
    end

    % Extract the relative path of original drive file
    start_pos = strfind(template_content, drive_file_dir);
    if ~isempty(start_pos)
        % Calculate position after the search path
        after_path_pos = start_pos + length(drive_file_dir);
        % Find the next '<' symbol after the path
        remaining_content = template_content(after_path_pos:end);
        end_pos = strfind(remaining_content, '<');
        if ~isempty(end_pos)
            % Extract text between path and '<'
            original_drive_file = remaining_content(1:end_pos(1)-1);
        else
            % No '<' found after the path
            original_drive_file = '';
            warning('No < symbol found after the specified path');
        end
    else
        % Path not found
        original_drive_file = '';
        warning('Specified path not found in template_content');
    end
    
    % Extract identifier from original drive file
    drive_pattern = '.*Drive_(.+?)\.sef';
    orig_tokens = regexp(original_drive_file, drive_pattern, 'tokens');
    orig_identifier = orig_tokens{1}{1};

    %% Process new EZF files

    % Process each input name
    for i = 1:length(input_names)
        current_input = input_names{i};
        % Extract identifier from CSV path (text between '\Drive_' and '.sef')
        tokens = regexp(current_input, drive_pattern, 'tokens');
        if isempty(tokens)
            warning('Cannot extract identifier from: %s', current_input);
            continue;
        end
        identifier = tokens{1}{1};  
        fprintf('Processing: %s\n', identifier);
        
        % Start with ezf template content
        new_content = template_content;
        
        % Replace drive file path
        new_content = strrep(new_content, append(drive_file_dir, original_drive_file), current_input);
        
        % Replace identifier pattern
        new_content = strrep(new_content, orig_identifier, identifier);
        
        % Create output filename
        output_filename = sprintf('%s.sef', identifier);
        
        % Write new .ezf file
        fid = fopen(output_filename, 'w');
        if fid == -1
            warning('Cannot create output file: %s', output_filename);
            continue;
        end
        fprintf(fid, '%s', new_content);
        fclose(fid);
        
        fprintf('Created: %s\n', output_filename);
    end
    
    fprintf('\nBatch processing complete! Generated %d .ezf files\n', length(input_names));
end