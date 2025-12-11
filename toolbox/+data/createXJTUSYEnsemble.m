function ensemble = createXJTUSYEnsemble(args)
%CREATEXJTUSYENSEMBLE Create a fileEnsembleDatastore for the XJTU-SY 
% dataset.
%
%   ensemble = data.createXJTUSYEnsemble(Name,Value)
%
%   Loads the XJTU-SY run-to-failure bearing dataset, processes each 
%   bearing's vibration snapshots, and creates a fileEnsembleDatastore 
%   compatible with MATLAB's Predictive Maintenance Toolbox.
%
%   Name-Value Pair Arguments:
%     "datasetFolder" - Path to the root of the unzipped XJTU-SY dataset. 
%                       If not specified, a dialog will prompt the user.
%     "outputFolder"  - Path where .mat files for each ensemble member will 
%                       be saved. If not specified, a dialog will prompt.
%     "progressMode"  - Progress indicator mode. Options:
%                         "text" (default) - Text progress bar in 
%                                            MATLAB interpreter.
%                         "gui"            - Graphical waitbar 
%                                            (for GUIs/Live Scripts).
%                         "none"           - No progress updates.
%
%   OUTPUT:
%     ensemble      - fileEnsembleDatastore object referencing the 
%                    processed data.
%
%   REFERENCE:
%     This dataset is available thanks to the following work:
%     Biao Wang, Yaguo Lei, Naipeng Li, Ningbo Li,
%     "A Hybrid Prognostics Approach for Estimating Remaining Useful Life
%     of Rolling Element Bearings",
%     IEEE Trans. Reliability, vol. 69, no. 1, pp. 401-412, 2020.
%     DOI: <a href="https://doi.org/10.1109/TR.2018.2882682">10.1109/TR.2018.2882682</a>.
%     Dataset: <a href="https://github.com/WangBiaoXJTU/xjtu-sy-bearing-datasets">
%     https://github.com/WangBiaoXJTU/xjtu-sy-bearing-datasets</a>
%
%   EXAMPLE:
%     % Create an ensemble with dialogs for folders and GUI progress bar
%     ensemble = data.createXJTUSYEnsemble("progressMode","gui");
%     % Or specify folders directly
%     ensemble = data.createXJTUSYEnsemble(...
%       "datasetFolder","XJTU-SY_Bearing_Datasets", ...
%       "outputFolder","ensemble_datastore");
%     % Preview the first few rows
%     preview(ensemble)
%
%   SEE ALSO:
%     fileEnsembleDatastore, readtable, save, load
%

    arguments
        args.datasetFolder (1,1) string = ""
        args.outputFolder (1,1) string = ""
        args.progressMode (1,1) string ...
            {mustBeMember( ...
            args.progressMode, {'text', 'none', 'gui'})} = "text"
    end

    if args.datasetFolder == ""
        folder = uigetdir(pwd, 'Select input dataset folder');
        if folder == 0
            error(...
            'sfrfs:data:createXJTUSYEnsemble:InputFolderNotSelected', ...
            'No input folder selected.');
        end
        datasetFolder = string(folder);
    elseif ~isfolder(args.datasetFolder)
        error(...
            'sfrfs:data:createXJTUSYEnsemble:InputFolderDoesNotExist', ...
            'The input folder "%s" does not exist.', args.datasetFolder);
    else
        datasetFolder = args.datasetFolder;
    end
    
    if args.outputFolder == ""
        folder = uigetdir(pwd, 'Select output folder');
        if folder == 0
            error(...
            'sfrfs:data:createXJTUSYEnsemble:OutputFolderNotSelected', ...
            'No output folder selected.');
        end
        outputFolder = string(folder);
    else
        outputFolder = args.outputFolder;
    end

    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end

    % XJTU-SY parameters
    speeds = [35.0, 37.5, 40.0];
    loads = [12.0, 11.0, 10.0];
    operating_conditions = ["35Hz12kN", "37.5Hz11kN", "40Hz10kN"];
    bearing_labels = compose(...
        "Bearing%d_%d", repelem(1:3,5)', repmat((1:5)',3,1));

    paths = strings(size(bearing_labels));
    conditions = strings(size(bearing_labels));
    for i = 1:3
        for j = 1:5
            idx = (i-1)*5 + j;
            paths(idx) = fullfile(...
                datasetFolder, ...
                operating_conditions(i), ...
                bearing_labels(idx));
            conditions(idx) = operating_conditions(i);
        end
    end

    % Dictionaries for speed/load per condition
    conditions_speeds = dictionary(operating_conditions, speeds);
    conditions_loads = dictionary(operating_conditions, loads);
    bearings_paths = dictionary(bearing_labels, paths);
    bearings_conditions = dictionary(bearing_labels, conditions);

    % Ensemble vars
    dataVariables = ["HorizontalAcceleration", "VerticalAcceleration"];
    independentVariables = ["Label", "SnapshotIndex"];
    conditionVariables = ["Speed", "Load", "Lifetime"];
    allVars = [independentVariables, conditionVariables, dataVariables];
    varTypes = repmat({'double'}, 1, numel(allVars));
    varTypes(strcmp(allVars, "Label")) = {'string'};
    varTypes(ismember(allVars, dataVariables)) = {'cell'};

    counts = countSnapshotFiles(bearing_labels, bearings_paths);
    totalFiles = sum(counts);
    currentFile = 0;
    if strcmp(args.progressMode, 'gui')
        h = waitbar(0,'Processing...             ','WindowStyle','normal');
        % Increase waitbar width and height slightly to avoid cropping
        figPos = get(h,'Position');  % [left bottom width height]
        figPos(3) = max(600, figPos(3));  % width
        figPos(4) = max(100, figPos(4));  % height
        set(h,'Position',figPos)
        
    elseif strcmp(args.progressMode, 'text')
        lastLen = 0;
    end

    % process each member (individual bearing)
    % processing is episodic we don't sort the table to save computation
    for bearing_label = bearing_labels'
        speed = conditions_speeds(bearings_conditions(bearing_label));
        load = conditions_loads(bearings_conditions(bearing_label));
        bearing_path = bearings_paths(bearing_label);
        snapshot_files = dir(fullfile(bearing_path, '*.csv'));
        lifetime = numel(snapshot_files);

        nSnapshots = length(snapshot_files);
        ensembleMemberTable = table(...
            'Size', [nSnapshots, numel(allVars)], ...
            'VariableTypes', varTypes,...
            'VariableNames', allVars);

        for k = 1:nSnapshots
            file = snapshot_files(k);
            snapshot_index = ...
                str2double(regexp(file.name, '\d+', 'match', 'once'));
            snapshot_table = readtable(fullfile(bearing_path, file.name));
            acc_horizontal = snapshot_table.Horizontal_vibration_signals;
            acc_vertical = snapshot_table.Vertical_vibration_signals;

            ensembleMemberTable.Label(k) = bearing_label;
            ensembleMemberTable.SnapshotIndex(k) = snapshot_index;
            ensembleMemberTable.Speed(k) = speed;
            ensembleMemberTable.Load(k) = load;
            ensembleMemberTable.Lifetime(k) = lifetime;
            ensembleMemberTable.HorizontalAcceleration{k} = acc_horizontal;
            ensembleMemberTable.VerticalAcceleration{k} = acc_vertical;

            currentFile = currentFile + 1;
            if strcmp(args.progressMode, 'gui')
                message = sprintf(...
                    'Processing... %.1f%%', currentFile/totalFiles*100);
                waitbar(currentFile/totalFiles, h,message);
            elseif strcmp(args.progressMode, 'text')
                lastLen = printProgressBar(...
                    currentFile, totalFiles, 60, lastLen);
            end
        end

        save(fullfile(outputFolder, bearing_label + ".mat"), ...
            'ensembleMemberTable', '-v7.3');
    end

    ensemble = data.getXJTUSYEnsemble(outputFolder);

end

% progress bar
function lastLen = printProgressBar(current, total, barWidth, lastLen)
    if nargin < 3, barWidth = 40; end
    if nargin < 4, lastLen = 0; end
    progress = min(max(current / total, 0), 1);
    numBars = min(barWidth, max(0, round(barWidth * progress)));
    if current > 0 && numBars == 0
        numBars = 1;
    end
    numSpaces = barWidth - numBars;
    % Use Unicode blocks for filled and empty
    filledChar = '█';
    emptyChar = '░';
    barStr = [...
        repmat(filledChar, 1, numBars), repmat(emptyChar, 1, numSpaces)];
    msg = sprintf(...
        '[%s] %d/%d (%.1f%%)', barStr, current, total, 100*progress);

    if lastLen > 0
        fprintf(repmat('\b', 1, lastLen));
    end
    fprintf('%s', msg);
    lastLen = length(msg);
    if current >= total
        fprintf('\n');
    end
end

% helper to count files
function counts = countSnapshotFiles(bearing_labels, bearings_paths)
    counts = zeros(size(bearing_labels));
    for i = 1:length(bearing_labels)
        pattern = fullfile(bearings_paths(bearing_labels(i)), '*.csv');
        files = dir(pattern);
        counts(i) = numel(files);
    end
end


