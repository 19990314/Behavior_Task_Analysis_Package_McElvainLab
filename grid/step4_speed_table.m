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
    
    % Store first 5 characters of filename and speed median
    fileShortNames{end+1,1} = fileName(1:min(7, end));  % handle very short names
    speedMedians(end+1,1) = medianSpeed;
end

% Convert to table
T = table(fileShortNames, speedMedians, ...
    'VariableNames', {'FilePrefix', 'MedianSpeed pixels/frame'});

% Display
disp(T)
writetable(T, fullfile(project_folder, 'grid_speed_stat.xlsx'));