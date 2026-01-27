% Define folder (change if needed)
project_folder = uigetdir([], 'Select Folder Containing mat files');
matFiles = dir(fullfile(project_folder, '*centroid.mat'));

% Initialize cell array for output
fileShortNames = {};
speedMedians = [];

for i = 1:length(matFiles)
    fileName = matFiles(i).name;
    fullPath = fullfile(project_folder, fileName);
    
    % Load file
    data = load(fullPath);
    
    % Check if 'speed' variable exists and is a vector
    if isfield(data, 'speed') && isnumeric(data.speed) && isvector(data.speed)
        medianSpeed = median(data.speed, 'omitnan');  % omit NaNs
    else
        warning('File %s does not contain a valid ''speed'' variable.', fileName);
        medianSpeed = NaN;
    end
    
    % Store first 7 characters of filename and speed median
    fileShortNames{end+1,1} = fileName(1:min(7, end));  % handle very short names
    speedMedians(end+1,1) = medianSpeed;
end

% Convert to table
T = table(fileShortNames, speedMedians, ...
    'VariableNames', {'FilePrefix', 'MedianSpeedPixels'});

% Add ANIMALID column (first 4 chars of FilePrefix)
ANIMALID = cellfun(@(x) x(1:min(4, length(x))), T.FilePrefix, 'UniformOutput', false);
T = addvars(T, ANIMALID, 'After', 'FilePrefix');

% Add Experiment day column (last char of FilePrefix)
ExperimentDay = cellfun(@(x) x(end), T.FilePrefix, 'UniformOutput', false);
T = addvars(T, ExperimentDay, 'After', 'ANIMALID');

% Load pixels_per_cm_output.xlsx and match with FilePrefix
pixelsFile = fullfile(project_folder, 'pixels_per_cm_output.xlsx');
if isfile(pixelsFile)
    pixelsTable = readtable(pixelsFile);
    
    % Initialize PixelsPerCm column with NaN
    PixelsPerCm = nan(height(T), 1);
    
    % Match FilePrefix to VideoName (removing _grid.mp4 extension)
    for i = 1:height(T)
        % Create the expected VideoName
        expectedVideoName = [T.FilePrefix{i} '_grid.mp4'];
        
        % Find matching row in pixelsTable
        matchIdx = find(strcmp(pixelsTable.VideoName, expectedVideoName), 1);
        
        if ~isempty(matchIdx)
            PixelsPerCm(i) = pixelsTable.PixelsPerCm(matchIdx);
        else
            warning('No match found for FilePrefix: %s', T.FilePrefix{i});
        end
    end
    
    % Add PixelsPerCm column to table
    T = addvars(T, PixelsPerCm, 'After', 'ExperimentDay');
else
    error('File pixels_per_cm_output.xlsx not found in the selected directory.');
end

% Add MedianSpeedcmps column: (MedianSpeedPixels * 30) / PixelsPerCm
MedianSpeedcmps = (T.MedianSpeedPixels * 30) ./ T.PixelsPerCm;
T = addvars(T, MedianSpeedcmps);

% Get unique ANIMALIDs
uniqueAnimalIDs = unique(T.ANIMALID);

% Create a map to store injection labels for each ANIMALID
injectionMap = containers.Map();

% Ask user to label each unique ANIMALID
for i = 1:length(uniqueAnimalIDs)
    animalID = uniqueAnimalIDs{i};
    
    % Create input dialog
    choice = questdlg(['Select injection type for ANIMALID: ' animalID], ...
        'Injection Label', ...
        'SNr-DTA', 'Ctrl', 'SNr-DTA');
    
    % Handle case where user closes dialog
    if isempty(choice)
        choice = 'SNr-DTA';  % default
    end
    
    % Store in map
    injectionMap(animalID) = choice;
end

% Create Injection column based on ANIMALID
Injection = cell(height(T), 1);
for i = 1:height(T)
    Injection{i} = injectionMap(T.ANIMALID{i});
end

% Add Injection column to table
T = addvars(T, Injection, 'After', 'ANIMALID');

% Add empty SlipsCount column
SlipsCount = nan(height(T), 1);
T = addvars(T, SlipsCount);

% Display
disp(T)

% Write to Excel
writetable(T, fullfile(project_folder, 'grid_speed_stat_baseline.xlsx'));
disp('Output file saved successfully!');