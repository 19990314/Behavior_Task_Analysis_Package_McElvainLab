% Define the two input files
baselineFile = "\\moorelaboratory.dts.usc.edu\Shared\Shuting\P1-SNr\B3_cohort_3_baseline_bahavior\stats_and_analysis\grid\grid_speed_stat_baseline.xlsx";
postinjectionFile = "\\moorelaboratory.dts.usc.edu\Shared\Shuting\P1-SNr\B5_cohort_3_post_injection_bahavior\stats_and_analysis\grid\grid_speed_stat_baseline.xlsx";
% Main script to generate both baseline and post-injection figures

% Generate baseline figure and calculate averages
fprintf('\n=== BASELINE ===\n');
generateSpeedSlipFigure(baselineFile, 'Baseline', 'speed_and_slipping_across_day_baseline.png');

% Generate post-injection figure and calculate averages
fprintf('\n=== POST-INJECTION ===\n');
generateSpeedSlipFigure(postinjectionFile, 'Post-Injection', 'speed_and_slipping_across_day_postinjection.png');

disp('Both figures generated successfully!');

%% Main plotting function
function generateSpeedSlipFigure(inputFile, titlePrefix, outputFile)
    % Load the table
    T = readtable(inputFile);
    
    % Convert ANIMALID to categorical
    T.ANIMALID = categorical(T.ANIMALID);
    
    % Convert ExperimentDay to numeric if it's not already
    if iscell(T.ExperimentDay)
        T.ExperimentDay = cellfun(@str2double, T.ExperimentDay);
    elseif ischar(T.ExperimentDay) || isstring(T.ExperimentDay)
        T.ExperimentDay = str2double(T.ExperimentDay);
    end
    
    % Ensure MedianSpeedcmps is numeric
    if iscell(T.MedianSpeedcmps)
        T.MedianSpeedcmps = cell2mat(T.MedianSpeedcmps);
    end
    
    % Ensure SlipsCount is numeric
    if iscell(T.SlipsCount)
        T.SlipsCount = cell2mat(T.SlipsCount);
    end
    
    % Unique animals and days
    animals = unique(T.ANIMALID, 'stable');
    days = unique(T.ExperimentDay);
    numAnimals = numel(animals);
    
    % Calculate and print average speeds for days 3-5
    fprintf('\nAverage MedianSpeedcmps for Days 3-5:\n');
    fprintf('%-15s %-15s %-20s\n', 'ANIMALID', 'Injection', 'Avg Speed (cm/s)');
    fprintf('%s\n', repmat('-', 1, 50));
    
    for i = 1:numAnimals
        mask = T.ANIMALID == animals(i);
        animalData = T(mask, :);
        
        % Filter for days 3-5
        dayMask = animalData.ExperimentDay >= 3 & animalData.ExperimentDay <= 5;
        speedsDay3to5 = animalData.MedianSpeedcmps(dayMask);
        
        % Calculate average
        if ~isempty(speedsDay3to5)
            avgSpeed = mean(speedsDay3to5, 'omitnan');
            injectionType = char(animalData.Injection(1));
            fprintf('%-15s %-15s %-20.2f\n', char(animals(i)), injectionType, avgSpeed);
        else
            fprintf('%-15s %-15s %-20s\n', char(animals(i)), char(animalData.Injection(1)), 'No data');
        end
    end
    fprintf('\n');
    
    % Slip colormap: white → blue → red
    slipMap = [
        1.00 1.00 1.00;   % 0 slips – white
        0.60 0.80 1.00;   % 1 slip  – light blue
        0.20 0.40 0.90;   % 2 slips – deep blue
        0.90 0.40 0.60;   % 3 slips – light red
        0.80 0.10 0.10    % 4 slips – dark red
    ];
    maxSlip = max(T.SlipsCount);
    
    % Generate mouse colors
    mouseColors = generateMouseColors(T, numAnimals);
    
    % Prepare figure
    figure; hold on;
    legendHandles = gobjects(0);
    legendLabels = strings(0);
    
    % Plot each animal's curve and dots
    for i = 1:numAnimals
        mask = T.ANIMALID == animals(i);
        dayVals = T.ExperimentDay(mask);
        speedVals = T.MedianSpeedcmps(mask);
        slipVals = T.SlipsCount(mask);
        
        % Sort by day
        [dayVals, sortIdx] = sort(dayVals);
        speedVals = speedVals(sortIdx);
        slipVals = slipVals(sortIdx);
        
        % Line for mouse
        hLine = plot(dayVals, speedVals, '-', ...
            'Color', mouseColors(i,:), ...
            'LineWidth', 1.8);
        legendHandles(end+1) = hLine;
        
        % Get the injection type for this animal
        animalIdx = find(mask, 1);
        
        % Colored dots for slips
        for j = 1:numel(dayVals)
            slipColor = slipMap(slipVals(j)+1, :);
            scatter(dayVals(j), speedVals(j), ...
                110, slipColor, 'filled', ...
                'MarkerEdgeColor', 'k', 'LineWidth', 1);
        end
    end
    legendLabels = string(["sc09(SNr-DTA)","sc10(SNr-DTA)","sc11(SNr-DTA)","sc12(SNr-DTA)","sc13(Ctrl)","sc14(Ctrl)","sc15(Ctrl)"])

    % Dummy scatter plots for slip legend
    for k = 0:maxSlip
        hDot = scatter(NaN, NaN, 70, slipMap(k+1,:), ...
            'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1.2);
        legendHandles(end+1) = hDot;
        if k == 1
            legendLabels(end+1) = '1 slip';
        else
            legendLabels(end+1) = sprintf('%d slips', k);
        end
    end
    
    % Axis and title
    xlabel('Experiment Day', 'FontSize', 13);
    ylabel('Median Speed (cm/s)', 'FontSize', 13);
    dayTicks = unique(T.ExperimentDay);
    dayTicks = dayTicks(:)';   % ensure row vector
    xticks(dayTicks);
    title(sprintf('[%s] Grid Task: Speed and Slipping Counts', titlePrefix), 'FontSize', 14);
    set(gca, 'FontSize', 12, 'FontName', 'Arial');
    box off;
    grid on;
    
    % Final unified legend
    legend(legendHandles, legendLabels, ...
        'Location', 'northeast', 'FontSize', 11, 'Box', 'on', 'EdgeColor', 'k');
    
    % Save figure
    print(gcf, outputFile, '-dpng', '-r300');
    fprintf('Figure saved: %s\n', outputFile);
end

%% Helper function to generate mouse colors
function mouseColors = generateMouseColors(T, numAnimals)
    % Base colors (RGB)
    nPath = sum(T.Injection == "SNr-DTA");
    nCtrl = sum(T.Injection == "Ctrl");
    
    % Count unique animals per group
    uniquePath = sum(unique(T.ANIMALID(T.Injection == "SNr-DTA")) ~= "");
    uniqueCtrl = sum(unique(T.ANIMALID(T.Injection == "Ctrl")) ~= "");
    
    basePath = [0.80 0.20 0.20];   % red family
    baseCtrl = [0.20 0.35 0.75];   % blue family
    
    % Helper to generate shades
    makeShades = @(base,n) ...
        (1 - linspace(0.10, 0.65, n)') .* base + ...
         linspace(0.10, 0.65, n)'  .* [1 1 1];
    
    mouseColors = zeros(numAnimals, 3);
    
    % Assign shades based on injection type
    pathIdx = 0;
    ctrlIdx = 0;
    
    animals = unique(T.ANIMALID, 'stable');
    
    for i = 1:numAnimals
        mask = T.ANIMALID == animals(i);
        injectionType = T.Injection(find(mask, 1));
        
        if injectionType == "SNr-DTA"
            pathIdx = pathIdx + 1;
            if uniquePath > 0
                shades = makeShades(basePath, uniquePath);
                mouseColors(i,:) = shades(pathIdx,:);
            end
        elseif injectionType == "Ctrl"
            ctrlIdx = ctrlIdx + 1;
            if uniqueCtrl > 0
                shades = makeShades(baseCtrl, uniqueCtrl);
                mouseColors(i,:) = shades(ctrlIdx,:);
            end
        end
    end
    
    % Fallback for any unassigned colors
    unassigned = sum(mouseColors, 2) == 0;
    if any(unassigned)
        mouseColors(unassigned,:) = lines(sum(unassigned));
    end
end

%% Helper function
function s = pluralize(n)
    if n == 1
        s = '';
    else
        s = 's';
    end
end
