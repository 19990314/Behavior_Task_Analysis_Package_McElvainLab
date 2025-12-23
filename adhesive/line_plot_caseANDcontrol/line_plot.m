%% Adhesive removal task
% Get data ready:
% 1. file name: remove_time_across_days.csv
% 2. table with columns:
% ID | Day | Trial1 | Trial2 | Group
% Group is the experimental label, eg "Ctrl" or "SNr-DTA" in my case

clear; clc;

%% -------------------- Load data --------------------
workDir = fileparts(mfilename('fullpath'));
%time_label = "recognition";
time_label = "removal";
fileName = time_label + '_time_across_days.csv';
yaxis_label = time_label + " time (s)";

data = readtable(fullfile(workDir, fileName));
%% -------------------- Preprocessing --------------------
mouseIDs = unique(data.ID, 'stable');
nMice    = numel(mouseIDs);
% Ensure Group is string
data.Group = string(data.Group);
legendLabels = strings(nMice,1);

for i = 1:nMice
    idx = strcmp(data.ID, mouseIDs(i));
    legendLabels(i) = unique(data.Group(idx), 'stable');
end

% Base colors (RGB)
nPath = min(3, nMice);
nCtrl = min(2, max(nMice - nPath, 0));
basePath = [0.80 0.20 0.20];   % red family
baseCtrl = [0.20 0.35 0.75];   % blue family
% data.Group = "Path" or "Ctrl"
isPath = data.Group == "SNr-DTA";
isCtrl = data.Group == "Ctrl";

% Helper to generate shades by mixing with white/black (stable & print-safe)
makeShades = @(base,n) ...
    (1 - linspace(0.10, 0.65, n)') .* base + ...
     linspace(0.10, 0.65, n)'  .* [1 1 1];

colors = zeros(nMice,3);

% Assign shades
if nPath > 0
    colors(1:nPath,:) = makeShades(basePath, nPath);
end
if nCtrl > 0
    colors(nPath+(1:nCtrl),:) = makeShades(baseCtrl, nCtrl);
end

% If you have more mice than 5, fill remaining with distinct default colors
if nMice > (nPath + nCtrl)
    colors(nPath+nCtrl+1:end,:) = lines(nMice - (nPath + nCtrl));
end

%% -------------------- Figure setup --------------------
figure('Color','w', 'Units','inches', 'Position',[1 1 6.5 4.5]);
hold on;

lw  = 2.0;   % line width
ms  = 6;     % marker size

%% -------------------- Plot per mouse --------------------
hLegend = gobjects(nMice,1);   % store one handle per mouse

for i = 1:nMice
    idx = strcmp(data.ID, mouseIDs(i));
    d   = data.Day(idx);

    if nnz(idx) == 0
        warning("No rows found for mouse %s", string(mouseIDs(i)));
    elseif numel(unique(data.ID(idx))) ~= 1
        warning("Indexing mixed IDs for i=%d", i);
    end

    % Trial 1 (solid) — keep handle
    hLegend(i) = plot(d, data.Trail1(idx), ...
        '--S', ...
        'Color', colors(i,:), ...
        'LineWidth', lw-1, ...
        'MarkerSize', ms, ...
        'MarkerFaceColor', colors(i,:));

    % Trial 2 (dashed) — DO NOT store handle
    plot(d, data.Trail2(idx), ...
        '-o', ...
        'Color', colors(i,:), ...
        'LineWidth', lw, ...
        'MarkerSize', ms, ...
        'MarkerFaceColor', 'w');
end

%% -------------------- Axes formatting --------------------
xlabel('Experimental Day', 'FontSize', 12, 'FontWeight','bold');
ylabel(yaxis_label, 'FontSize', 12, 'FontWeight','bold');
dayTicks = unique(data.Day);
dayTicks = dayTicks(:)';   % ensure row vector

xticks(dayTicks);

set(gca, ...
    'FontSize', 11, ...
    'LineWidth', 1.2, ...
    'Box', 'off', ...
    'TickDir', 'out', ...
    'TickLength', [0.015 0.015]);

grid on;
set(gca,'GridAlpha',0.15);

%% -------------------- Legend --------------------
legend(hLegend, legendLabels, 'Location','eastoutside', 'FontSize',10);

%% -------------------- Text Annotation --------------------
annotation('textbox', [0.15 0.82 0.3 0.1], ...
    'String', {'Solid: baseline', ...
               'Dashed: post-injection'}, ...
    'EdgeColor','none', ...
    'FontSize',10);

title('Adhesive Removal Task', ...
      'FontSize', 13, ...
      'FontWeight', 'bold');

%% -------------------- Export --------------------
% Recommended formats for journals
%exportgraphics(gcf, fullfile(workDir, 'adhesive_removal_time.pdf'), 'ContentType','vector');
exportgraphics(gcf, fullfile(workDir, time_label + '_time.png'), 'ContentType','vector');
