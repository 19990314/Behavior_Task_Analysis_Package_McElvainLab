% Load table
filename = '/Users/chen/Downloads/adhesive/for_plot_ad_rev_time.xlsx';
T = readtable(filename);

% Define desired mouse order
desiredOrder = {'CTR', 'GPi-DTA', 'SNr-DTA'};
nAnimals = length(desiredOrder);

% Initialize
timeRecognize = zeros(nAnimals, 1);
timeRemoveAfter = zeros(nAnimals, 1);
rawRecognize = cell(nAnimals, 1);
rawRemoveAfter = cell(nAnimals, 1);

% Compute mean + raw per animal
for i = 1:nAnimals
    mouse = desiredOrder{i};
    idx = strcmp(T.ANIMAL_ID, mouse);

    recog = T.Time_to_recognize(idx);
    total = T.Total_time_to_remove(idx);
    removeAfter = total - recog;

    timeRecognize(i) = mean(recog, 'omitnan');
    timeRemoveAfter(i) = mean(removeAfter, 'omitnan');

    rawRecognize{i} = recog;
    rawRemoveAfter{i} = removeAfter;
end

% Prepare data
data = [timeRecognize, timeRemoveAfter];
x = 1:nAnimals;

% Start plot
figure;
hold on;

% Stacked bar
hBar = bar(x, data, 'stacked', 'BarWidth', 0.6);
hBar(1).FaceColor = [0.3 0.6 0.8];   % blue: recognition
hBar(2).FaceColor = [0.9 0.6 0.3];   % orange: removal

% Data points: triangles for recognition, dots for removal
for i = 1:nAnimals
    jitter = (rand(1, numel(rawRecognize{i})) - 0.5) * 0.2;

    % Recognition
    scatter(x(i) + jitter, rawRecognize{i}, ...
        40, '^', ...
        'MarkerEdgeColor', 'k', ...
        'MarkerFaceColor', [0.3 0.6 0.8], ...
        'LineWidth', 1.2);

    % Removal (stacked above recognition)
    scatter(x(i) + jitter, rawRecognize{i} + rawRemoveAfter{i}, ...
        40, 'o', ...
        'MarkerEdgeColor', 'k', ...
        'MarkerFaceColor', [0.9 0.6 0.3], ...
        'LineWidth', 1.2);
end

% Aesthetics
set(gca, 'XTick', x, 'XTickLabel', desiredOrder, 'FontSize', 12, 'FontName', 'Arial');
ylabel('Time Spent (sec)', 'FontSize', 13);
title('Sticker Removal Performance', 'FontSize', 14, 'FontWeight', 'bold');
ylim([0, max(sum(data,2)) * 1.25]);
box off;
grid on;

% Dummy plots for legend
h1 = plot(NaN, NaN, '^', 'MarkerEdgeColor', 'k', ...
    'MarkerFaceColor', [0.3 0.6 0.8], 'LineWidth', 1.2);
h2 = plot(NaN, NaN, 'o', 'MarkerEdgeColor', 'k', ...
    'MarkerFaceColor', [0.9 0.6 0.3], 'LineWidth', 1.2);

% Legend
legend([h1, h2], {'Recognition Time', 'Removal Time'}, ...
    'Location', 'northwest', 'FontSize', 11, ...
    'Box', 'on', 'EdgeColor', 'k');

% Annotation
annotation('textbox', [0.12, 0.01, 0.8, 0.05], 'String', ...
    '*Each bar shows the average time from 4 testing days per mouse.', ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'left', 'FontSize', 10);

% Save
print(gcf, 'adhesive_removal_tri_dot.png', '-dpng', '-r300');