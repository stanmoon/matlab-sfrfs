classdef ContrastPolarityDegradationExplorer < handle
    %CONTRASTPOLARITYDEGRADATIONEXPLORER Explore stored contrast-polarity representations.
    %
    % ContrastPolarityDegradationExplorer provides an interactive interface
    % for examining the canonical exploration dataset produced by
    % ContrastPolarityExplorationDatasetBuilder.
    %
    % The explorer operates on previously computed representations.
    % It does not reconstruct spectral fault receptive fields, recompute
    % contrast-polarity channels, or infer diagnostic or prognostic states.
    %
    % The interface supports selection by bearing and monitored fault
    % family, snapshot-window navigation, and six complementary views:
    %
    %   DirectObservable
    %   EpistemicSupport
    %   EventDensity
    %   PolarityBalance
    %   HarmonicPolarityTrajectory
    %   HarmonicRelevance
    %
    % Constructor:
    %
    %   explorer = viz.ContrastPolarityDegradationExplorer( ...
    %       datasetTable = channelRunsQ95);
    %
    % Optional parameters:
    %
    %   bearingParameters - Bearing geometry and frequency parameters.
    %   sfrfsParameters   - Spectral fault receptive-field configuration.
    %
    % Display the interactive explorer:
    %
    %   explorer.render();
    %
    % See also ContrastPolarityExplorationDatasetBuilder,
    %          ContrastPolarityChannelDatasetBuilder.

    properties (SetAccess = private)
        datasetTable table
    end

    properties (Access = private)
        fig
        ax
        infoArea

        labelDrop
        familyDrop
        viewDrop
        observableDrop
        eventDrop
        overlayEventDrop
        relevanceModeDrop

        startEdit
        windowEdit
        robustEdit
        renderButton

        bearingParameters
        sfrfsParameters
    end

    properties (Constant, Access = private)
        MetadataNames = [ ...
            "Label", ...
            "Speed", ...
            "Load", ...
            "Lifetime", ...
            "MonitoredFaultFamily", ...
            "HarmonicCount", ...
            "Failure_O", ...
            "Failure_I", ...
            "Failure_C", ...
            "Failure_B"];

        EventNames = [ ...
            "PolarityReversal", ...
            "OnPositive", ...
            "OnNegative", ...
            "OffPositive", ...
            "OffNegative"];

        ViewNames = [ ...
            "DirectObservable", ...
            "EpistemicSupport", ...
            "EventDensity", ...
            "PolarityBalance", ...
            "HarmonicPolarityTrajectory", ...
            "HarmonicRelevance"];
    end

    methods

        function obj = ContrastPolarityDegradationExplorer(args)

            arguments
                args.datasetTable table {mustBeNonempty}
                args.bearingParameters = []
                args.sfrfsParameters = []
            end

            obj.datasetTable = args.datasetTable;
            obj.bearingParameters = args.bearingParameters;
            obj.sfrfsParameters = args.sfrfsParameters;

        end

        function render(obj)

            obj.fig = uifigure( ...
                Name = "Contrast Polarity Degradation Explorer", ...
                Position = [60 40 1700 980]);

            main = uigridlayout(obj.fig, [1 2]);
            main.ColumnWidth = {380, "1x"};
            main.RowHeight = {"1x"};

            controlPanel = uipanel(main, ...
                Title = "Selection");

            grid = uigridlayout(controlPanel, [19 2]);
            grid.ColumnWidth = {115, "1x"};
            grid.RowHeight = repmat({30}, 1, 19);
            grid.Padding = [8 8 8 8];

            uilabel(grid, Text = "Bearing");
            obj.labelDrop = uidropdown(grid, ...
                Items = cellstr(obj.labels()), ...
                ValueChangedFcn = @(~, ~) obj.refreshFamilies());

            uilabel(grid, Text = "Fault family");
            obj.familyDrop = uidropdown(grid, ...
                Items = cellstr(obj.families()));

            uilabel(grid, Text = "View");
            obj.viewDrop = uidropdown(grid, ...
                Items = cellstr(obj.ViewNames), ...
                Value = "DirectObservable", ...
                ValueChangedFcn = @(~, ~) obj.refreshVisibility());

            uilabel(grid, Text = "Observable");
            obj.observableDrop = uidropdown(grid, ...
                Items = cellstr(obj.observableNames()));

            uilabel(grid, Text = "Relevance mode");
            obj.relevanceModeDrop = uidropdown(grid, ...
                Items = ["Absolute", "ImportanceIndex"], ...
                Value = "Absolute");

            uilabel(grid, Text = "Event count");
            obj.eventDrop = uidropdown(grid, ...
                Items = cellstr(obj.EventNames), ...
                Value = "PolarityReversal");

            uilabel(grid, Text = "Event overlay");
            obj.overlayEventDrop = uidropdown(grid, ...
                Items = cellstr(["None", obj.EventNames]), ...
                Value = "None");

            uilabel(grid, Text = "Start snapshot");
            obj.startEdit = uieditfield(grid, "numeric", ...
                Value = 1, ...
                Limits = [1 inf], ...
                RoundFractionalValues = "on");

            uilabel(grid, Text = "Window length");
            obj.windowEdit = uieditfield(grid, "numeric", ...
                Value = 0, ...
                Limits = [0 inf], ...
                RoundFractionalValues = "on");

            uilabel(grid, Text = "Robust prctile");
            obj.robustEdit = uieditfield(grid, "numeric", ...
                Value = 99, ...
                Limits = [1 100]);

            obj.renderButton = uibutton(grid, ...
                Text = "Render", ...
                ButtonPushedFcn = @(~, ~) obj.renderCurrent());
            obj.renderButton.Layout.Row = 11;
            obj.renderButton.Layout.Column = [1 2];

            obj.infoArea = uitextarea(grid, ...
                Editable = "off");
            obj.infoArea.Layout.Row = [12 19];
            obj.infoArea.Layout.Column = [1 2];

            plotPanel = uipanel(main, ...
                Title = "Visualization");

            plotGrid = uigridlayout(plotPanel, [1 1]);
            obj.ax = uiaxes(plotGrid);

            obj.refreshFamilies();
            obj.refreshVisibility();
            obj.renderCurrent();

        end
    end

    methods (Access = private)

        function refreshFamilies(obj)

            label = string(obj.labelDrop.Value);
            rows = obj.datasetTable(obj.datasetTable.Label == label, :);
            fams = unique(rows.MonitoredFaultFamily, "stable");

            obj.familyDrop.Items = cellstr(fams);

            if ~isempty(fams)
                obj.familyDrop.Value = fams(1);
            end
        end

        function refreshVisibility(obj)

            viewName = string(obj.viewDrop.Value);

            obj.observableDrop.Enable = "off";
            obj.eventDrop.Enable = "off";
            obj.overlayEventDrop.Enable = "off";
            obj.relevanceModeDrop.Enable = "off";

            if viewName == "DirectObservable"
                obj.observableDrop.Enable = "on";
                obj.overlayEventDrop.Enable = "on";
            elseif viewName == "HarmonicRelevance"
                obj.observableDrop.Enable = "on";
                obj.relevanceModeDrop.Enable = "on";
            elseif viewName == "EventDensity"
                obj.eventDrop.Enable = "on";
            end
        end

        function renderCurrent(obj)

            row = obj.selectedRow();
            viewName = string(obj.viewDrop.Value);

            cla(obj.ax, "reset");

            switch viewName
                case "DirectObservable"
                    obj.renderDirect(row, string(obj.observableDrop.Value));

                case "EpistemicSupport"
                    obj.renderEpistemicSupport(row);

                case "EventDensity"
                    obj.renderEventDensity(row, string(obj.eventDrop.Value));

                case "PolarityBalance"
                    obj.renderPolarityBalance(row);

                case "HarmonicPolarityTrajectory"
                    obj.renderPolarityTrajectory(row);

                case "HarmonicRelevance"
                    obj.renderHarmonicRelevance( ...
                        row, ...
                        string(obj.observableDrop.Value));
            end

            if viewName ~= "HarmonicRelevance"
                obj.updateInfo(row);
            end
        end

        function renderDirect(obj, row, name)

            X = row.(name){1};

            if isvector(X)
                y = X(:);
                idx = obj.windowIndex(numel(y));

                plot(obj.ax, idx, y(idx), LineWidth = 1.2);
                grid(obj.ax, "on");
                xlabel(obj.ax, "Snapshot index");
                ylabel(obj.ax, name, Interpreter = "none");
                title(obj.ax, name, Interpreter = "none");
                return
            end

            idx = obj.windowIndex(size(X, 1));
            Z = X(idx, :).';

            imagesc(obj.ax, idx, 1:size(Z, 1), Z);
            axis(obj.ax, "tight");
            set(obj.ax, YDir = "normal");

            xlabel(obj.ax, "Snapshot index");
            ylabel(obj.ax, "Harmonic index");
            title(obj.ax, name, Interpreter = "none");

            if obj.isEventName(name)
                colormap(obj.ax, obj.binaryEventColormap());
                clim(obj.ax, [0 1]);
            elseif obj.isContrastLike(name)
                colormap(obj.ax, obj.signedContrastColormap());
                obj.applySignedColorLimits(Z);
            else
                colormap(obj.ax, jet);
            end

            colorbar(obj.ax);

            obj.overlayEvents(row, idx, name);
        end

        function overlayEvents(obj, row, idx, observableName)

            eventName = string(obj.overlayEventDrop.Value);

            if eventName == "None" || ~obj.isContrastLike(observableName)
                return
            end

            E = row.(eventName){1};
            Ew = E(idx, :).';

            [h, tLocal] = find(Ew ~= 0);

            if isempty(h)
                return
            end

            t = idx(tLocal);

            hold(obj.ax, "on");
            plot(obj.ax, t, h, "kx", ...
                LineStyle = "none", ...
                MarkerSize = 5, ...
                LineWidth = 0.8);
            hold(obj.ax, "off");
        end

        function renderEpistemicSupport(obj, row)

            C = row.ResolvedContrast{1};
            idx = obj.windowIndex(size(C, 1));

            supported = sum(C(idx, :) ~= 0, 2);
            censored = size(C, 2) - supported;

            y = [supported, censored];

            b = bar(obj.ax, idx, y, "stacked");
            b(1).FaceColor = [0.20, 0.55, 0.45];
            b(2).FaceColor = [0.88, 0.88, 0.88];

            for k = 1:numel(b)
                b(k).EdgeColor = "none";
            end

            grid(obj.ax, "on");

            xlabel(obj.ax, "Snapshot index");
            ylabel(obj.ax, "Harmonic count");
            title(obj.ax, "Epistemic support count");
            legend(obj.ax, ["supported", "censored"], Location = "best");
        end

        function renderEventDensity(obj, row, eventName)

            E = row.(eventName){1};
            idx = obj.windowIndex(size(E, 1));

            eventCount = sum(E(idx, :) ~= 0, 2);

            bar(obj.ax, idx, eventCount, ...
                FaceColor = [0.35, 0.35, 0.35], ...
                EdgeColor = "none");

            grid(obj.ax, "on");

            yMax = max(eventCount);

            if yMax <= 0 || ~isfinite(yMax)
                ylim(obj.ax, [0 1]);
            else
                ylim(obj.ax, [0 max(1, 1.20 * yMax)]);
            end

            xlabel(obj.ax, "Snapshot index");
            ylabel(obj.ax, "Event count");
            title(obj.ax, "Event count: " + eventName, ...
                Interpreter = "none");
        end

        function renderPolarityBalance(obj, row)

            C = row.ResolvedContrast{1};
            idx = obj.windowIndex(size(C, 1));

            Cw = C(idx, :);

            negativeCount = sum(Cw < 0, 2);
            positiveCount = sum(Cw > 0, 2);
            silentCount = sum(Cw == 0, 2);

            y = [negativeCount, positiveCount, silentCount];

            b = bar(obj.ax, idx, y, "stacked");
            b(1).FaceColor = [0.30, 0.45, 0.80];
            b(2).FaceColor = [0.80, 0.35, 0.30];
            b(3).FaceColor = [0.88, 0.88, 0.88];

            for k = 1:numel(b)
                b(k).EdgeColor = "none";
            end

            grid(obj.ax, "on");

            xlabel(obj.ax, "Snapshot index");
            ylabel(obj.ax, "Harmonic count");
            title(obj.ax, "Polarity composition count");
            legend(obj.ax, ...
                ["negative", "positive", "silent"], ...
                Location = "best");
        end

        function renderPolarityTrajectory(obj, row)

            C = row.ResolvedContrast{1};
            idx = obj.windowIndex(size(C, 1));

            Cw = C(idx, :);

            sPlus = sum(max(Cw, 0), 2);
            sMinus = sum(max(-Cw, 0), 2);

            plot(obj.ax, sPlus, sMinus, "-", ...
                LineWidth = 0.25, ...
                Color = [0.72, 0.72, 0.72]);
            hold(obj.ax, "on");

            scatter(obj.ax, ...
                sPlus, ...
                sMinus, ...
                28, ...
                idx(:), ...
                "filled");

            hold(obj.ax, "off");

            grid(obj.ax, "on");
            axis(obj.ax, "tight");
            colormap(obj.ax, obj.timeColormap());

            cb = colorbar(obj.ax);
            cb.Label.String = "Snapshot index";

            xlabel(obj.ax, "Positive population mass");
            ylabel(obj.ax, "Negative population mass");
            title(obj.ax, "Harmonic polarity trajectory");
        end

        function renderHarmonicRelevance(obj, row, name)

            X = row.(name){1};

            if isvector(X)
                y = X(:);
                idx = obj.windowIndex(numel(y));

                plot(obj.ax, idx, y(idx), LineWidth = 1.2);
                grid(obj.ax, "on");

                xlabel(obj.ax, "Snapshot index");
                ylabel(obj.ax, name, Interpreter = "none");
                title(obj.ax, ...
                    "Temporal observable: " + name, ...
                    Interpreter = "none");

                obj.updateInfo(row);
                return
            end

            if obj.isEventName(name)
                relevance = sum(X ~= 0, 1);
                responseLabel = "Event count";
                indexLabel = "Relative event importance index";
                barColor = [0.35, 0.35, 0.35];
                titleText = "Harmonic event relevance: " + name;
            else
                relevance = sum(abs(X), 1);
                responseLabel = "Accumulated absolute response";
                indexLabel = "Relative contrast importance index";
                barColor = [0.20, 0.55, 0.45];
                titleText = "Harmonic contrast relevance: " + name;
            end

            relevance = relevance(:);
            H = numel(relevance);

            retentionFraction = obj.robustEdit.Value / 100;

            [keepMask, selectedEnergyFraction] = ...
                obj.relevanceRetentionMask(relevance, retentionFraction);

            displayRelevance = relevance;
            displayRelevance(~keepMask) = 0;

            [sortedRelevance, order] = sort(displayRelevance, "descend");

            rankOfHarmonic = nan(H, 1);
            rankOfHarmonic(order) = (1:H).';

            importanceIndex = H - rankOfHarmonic + 1;
            importanceIndex(displayRelevance == 0) = 0;

            mode = string(obj.relevanceModeDrop.Value);

            if mode == "ImportanceIndex"
                yPlot = importanceIndex;
                xLabel = indexLabel;
                plotTitle = titleText + " | importance index | retain " ...
                    + string(obj.robustEdit.Value) + "%";
            else
                yPlot = displayRelevance;
                xLabel = responseLabel;
                plotTitle = titleText + " | retained relevance | retain " ...
                    + string(obj.robustEdit.Value) + "%";
            end

            cla(obj.ax, "reset");

            barh(obj.ax, 1:H, yPlot, ...
                FaceColor = barColor, ...
                EdgeColor = "none");

            set(obj.ax, YDir = "normal");
            grid(obj.ax, "on");

            ylabel(obj.ax, "Harmonic index");
            xlabel(obj.ax, xLabel);

            title(obj.ax, plotTitle, ...
                Interpreter = "none", ...
                FontWeight = "normal");

            ylim(obj.ax, [0.5, H + 0.5]);
            obj.addFrequencyRightAxis(row, H);

            if any(yPlot > 0)
                xlim(obj.ax, [0, 1.1 * max(yPlot)]);
            else
                xlim(obj.ax, [0, 1]);
            end

            shown = nnz(displayRelevance);

            obj.infoArea.Value = cellstr([
                "Observable: " + name
                "Mode: " + mode
                "Retained relevance target: " ...
                    + string(obj.robustEdit.Value) + "%"
                "Retained relevance actual: " ...
                    + string(100 * selectedEnergyFraction) + "%"
                "Top harmonic: " + string(order(1))
                "Top relevance: " + string(sortedRelevance(1))
                "Displayed harmonics: " + string(shown)
                "Nonzero harmonics: " + string(nnz(relevance))
                "Total harmonics: " + string(H)
                "Diagnosis: " + obj.diagnosisSummary(row)
                ]);

        end

        function row = selectedRow(obj)

            label = string(obj.labelDrop.Value);
            family = string(obj.familyDrop.Value);

            mask = obj.datasetTable.Label == label & ...
                obj.datasetTable.MonitoredFaultFamily == family;

            row = obj.datasetTable(mask, :);

            if height(row) ~= 1
                error( ...
                    "sfrfs:Explorer:InvalidSelection", ...
                    "Expected exactly one selected row.");
            end
        end

        function idx = windowIndex(obj, n)

            first = max(1, round(obj.startEdit.Value));

            if obj.windowEdit.Value <= 0
                last = n;
            else
                last = first + round(obj.windowEdit.Value) - 1;
            end

            first = min(first, n);
            last = min(max(first, last), n);

            idx = first:last;
        end

        function updateInfo(obj, row)

            C = row.ResolvedContrast{1};
            H = size(C, 2);

            support = sum(C ~= 0, "all") / numel(C);

            sPlus = sum(max(C(:), 0));
            sMinus = sum(max(-C(:), 0));

            balance = (sPlus - sMinus) / (sPlus + sMinus + eps);

            txt = [
                "Label: " + string(row.Label)
                "Family: " + string(row.MonitoredFaultFamily)
                "Speed: " + string(row.Speed)
                "Load: " + string(row.Load)
                "Lifetime: " + string(row.Lifetime)
                "HarmonicCount: " + string(row.HarmonicCount)
                "EpistemicSupport: " + string(support)
                "PolarityBalance: " + string(balance)
                "Diagnosis: " + obj.diagnosisSummary(row)
                "Matrix shape: T x H = " ...
                    + string(size(C, 1)) + " x " + string(H)
                ];

            obj.infoArea.Value = cellstr(txt);
        end

        function txt = diagnosisSummary(~, row)

            labels = ["O", "I", "C", "B"];

            values = [ ...
                row.Failure_O, ...
                row.Failure_I, ...
                row.Failure_C, ...
                row.Failure_B];

            parts = strings(1, numel(labels));

            for i = 1:numel(labels)

                value = values(i);

                if isnan(value)
                    symbol = "?";
                elseif value == 1
                    symbol = "✓";
                elseif value == 0
                    symbol = "·";
                else
                    error( ...
                        "sfrfs:Explorer:InvalidDiagnosis", ...
                        "Invalid diagnosis annotation for %s.", ...
                        labels(i));
                end

                parts(i) = labels(i) + " " + symbol;
            end

            txt = strjoin(parts, "   ");
        end
        function applySignedColorLimits(obj, Z)

            vals = Z(isfinite(Z));
            vals = abs(vals(vals ~= 0));

            if isempty(vals)
                zMax = 1;
            else
                zMax = prctile(vals, obj.robustEdit.Value);
            end

            if zMax <= 0 || ~isfinite(zMax)
                zMax = 1;
            end

            clim(obj.ax, [-zMax zMax]);
        end

        function tf = isContrastLike(~, name)

            name = string(name);

            tf = contains(name, "ResolvedContrast") ...
                || endsWith(name, "_C") ...
                || contains(name, "Contrast");
        end

        function tf = isEventName(obj, name)
            tf = any(string(name) == obj.EventNames);
        end

        function labels = labels(obj)
            labels = unique(obj.datasetTable.Label, "stable");
        end

        function fams = families(obj)
            fams = unique(obj.datasetTable.MonitoredFaultFamily, "stable");
        end

        function names = observableNames(obj)

            vars = string(obj.datasetTable.Properties.VariableNames);
            names = strings(0, 1);

            for i = 1:numel(vars)
                name = vars(i);

                if any(name == obj.MetadataNames)
                    continue
                end

                value = obj.datasetTable.(name);

                if ~iscell(value)
                    continue
                end

                idx = find(~cellfun(@isempty, value), 1);

                if isempty(idx)
                    continue
                end

                first = value{idx};

                if isnumeric(first) || islogical(first)
                    names(end + 1, 1) = name;
                end
            end
        end

        function cmap = signedContrastColormap(~)

            n = 256;
            blue = [0.100, 0.300, 0.850];
            white = [1.000, 1.000, 1.000];
            red = [0.850, 0.100, 0.100];

            cmap = zeros(n, 3);
            mid = (n + 1) / 2;

            for i = 1:n
                if i <= mid
                    a = (i - 1) / (mid - 1);
                    cmap(i, :) = (1 - a) * blue + a * white;
                else
                    a = (i - mid) / (n - mid);
                    cmap(i, :) = (1 - a) * white + a * red;
                end
            end
        end

        function cmap = binaryEventColormap(~)
            cmap = [
                1.000, 1.000, 1.000
                0.000, 0.000, 0.000];
        end

        function cmap = timeColormap(~)

            n = 256;
            darkBlue = [0.020, 0.060, 0.350];
            cyan = [0.000, 0.850, 0.950];

            a = linspace(0, 1, n).';
            cmap = (1 - a) .* darkBlue + a .* cyan;
        end

        function tf = hasFrequencyContext(obj)

            tf = ~isempty(obj.bearingParameters) ...
                && ~isempty(obj.sfrfsParameters);

        end

        function fc = centralFrequencyForRow(obj, row)

            if ~obj.hasFrequencyContext()
                fc = NaN;
                return
            end

            oc = OperatingConditions(row.Speed, row.Load);

            bfb = BearingFrequencyBands( ...
                bearingParams = obj.bearingParameters, ...
                sfrfsParams = obj.sfrfsParameters, ...
                operatingConditions = oc);

            family = string(row.MonitoredFaultFamily);

            switch family
                case "BPFO"
                    code = BearingFrequencyBands.BPFO_CODE;

                case "BPFI"
                    code = BearingFrequencyBands.BPFI_CODE;

                case "BSF"
                    code = BearingFrequencyBands.BSF_CODE;

                case "FTF"
                    code = BearingFrequencyBands.FTF_CODE;

                otherwise
                    error( ...
                        "sfrfs:Explorer:UnknownFaultFamily", ...
                        "Unknown monitored fault family: %s", ...
                        family);
            end

            fc = bfb.getCentralFrequency(code, row.Speed);

        end

        function addFrequencyRightAxis(obj, row, H)

            if ~obj.hasFrequencyContext()
                return
            end

            fc = obj.centralFrequencyForRow(row);

            if ~isfinite(fc) || fc <= 0
                return
            end

            yyaxis(obj.ax, "right");
            obj.ax.YColor = [0 0 0];

            ylim(obj.ax, fc .* [0.5, H + 0.5]);
            ylabel(obj.ax, "Frequency [Hz]");

            yyaxis(obj.ax, "left");
            obj.ax.YColor = [0 0 0];

        end

        function [keepMask, selectedFraction] = ...
                relevanceRetentionMask(~, relevance, retentionFraction)

            relevance = relevance(:);
            H = numel(relevance);

            keepMask = false(H, 1);
            selectedFraction = 0;

            validMask = isfinite(relevance) & relevance > 0;

            if ~any(validMask)
                return
            end

            positiveRelevance = relevance;
            positiveRelevance(~validMask) = 0;

            total = sum(positiveRelevance);

            if total <= 0 || ~isfinite(total)
                return
            end

            retentionFraction = min(max(retentionFraction, 0), 1);

            [sortedRelevance, order] = sort( ...
                positiveRelevance, ...
                "descend");

            cumulativeFraction = cumsum(sortedRelevance) ./ total;

            crossing = find(cumulativeFraction >= retentionFraction, 1);

            if isempty(crossing)
                crossing = nnz(sortedRelevance > 0);
            end

            selectedOrder = order(1:crossing);
            keepMask(selectedOrder) = true;

            selectedFraction = sum(positiveRelevance(keepMask)) ./ total;

        end

    end
end