classdef RFGFViewer < handle
%RFGFViewer  Embeddable viewer for receptive field gain functions (RFGFs).
%
%   viewer = RFGFViewer(Name=Value, ...)
%   ax = viewer.render(Name=Value, ...)
%
% Constructor configures rendering preferences.
% render() is parameterized by selection:
%   - row
%   - faultType + selection

    properties (SetAccess = private)
        rfgfs ReceptiveFieldGainFunctions
    end

    properties
        parent = []
        % Axes/UIAxes. If empty or invalid, render() creates figure+axes.

        frequencyLimits double = []
        % [fmin fmax] in Hz, or [] for auto.

        showCenter   (1,1) logical = true
        showSurround (1,1) logical = true
        showContrast (1,1) logical = true

        titleText  (1,1) string  = ""
        showTitle  (1,1) logical = true
        showLegend (1,1) logical = true
    end

    methods
        function obj = RFGFViewer(args)
            arguments
                args.rfgfs ReceptiveFieldGainFunctions
                args.parent = []
                args.frequencyLimits double = []
                args.titleText  (1,1) string  = ""
                args.showTitle  (1,1) logical = true
                args.showLegend (1,1) logical = true
            end

            obj.rfgfs = args.rfgfs;
            obj.parent = args.parent;

            obj.frequencyLimits = args.frequencyLimits;
            obj.validateFrequencyLimits(obj.frequencyLimits);

            obj.titleText = args.titleText;
            obj.showTitle = args.showTitle;
            obj.showLegend = args.showLegend;
        end

        function attach(obj, args)
            arguments
                obj
                args.parent
            end
            obj.parent = args.parent;
        end

        function ax = render(obj, args)
            arguments
                obj

                % Selection (choose one): row vs (faulType + selection)
                args.row double = []
                args.faultType (1,1) string = ""
                args.selection OperatingConditionSelection = ...
                    OperatingConditionSelection.empty()

                % Optional rendering options:
                args.parent = []
                args.frequencyLimits double = []
                args.titleText (1,1) string = ""
            end

            gt = obj.rfgfs.gainFunctionsTable;
            if isempty(gt) || height(gt) == 0
                error("sfrfs:viz:RFGFViewer:EmptyGainFunctionsTable", ...
                    "gainFunctionsTable is empty.");
            end

            f = obj.rfgfs.frequencyDomain;
            if isempty(f)
                error("sfrfs:viz:RFGFViewer:EmptyFrequencyDomain", ...
                    "frequencyDomain is empty.");
            end

            [rowIdx, faultGroup] = obj.resolveRowAndFaultGroup( ...
                gt, args.row, args.faultType, args.selection);

            masks = gt.FrequencyBankMasks{rowIdx};
            [c, s] = obj.extractMasks(masks, f);

            k = obj.getInhibitionFactorFromFaultGroup(faultGroup);

            ax = obj.ensureAxes(args.parent);
            cla(ax);
            hold(ax, "on");

            if obj.showCenter
                plot(ax, f, c, ...
                    "LineStyle", "-", ...
                    "LineWidth", 1.5, ...
                    "Color", [0.0 0.6 0.0], ...
                    "DisplayName", "Center");
            end

            if obj.showSurround
                plot(ax, f, -s, ...
                    "LineStyle", "-", ...
                    "LineWidth", 1.5, ...
                    "Color", [0.8 0.0 0.0], ...
                    "DisplayName", "-Surround");
            end

            if obj.showContrast
                contrast = c - k .* s;
                plot(ax, f, contrast, ...
                    "LineStyle", "-", ...
                    "LineWidth", 1.8, ...
                    "Color", [0.0 0.0 0.0], ...
                    "DisplayName", obj.contrastLabel(k));
            end

            xlabel(ax, "Frequency (Hz)");
            ylabel(ax, "Gain");
            grid(ax, "on");

            lim = obj.resolveLimits(f, args.frequencyLimits);
            xlim(ax, lim);

            obj.applyTitle(ax, gt, rowIdx, args.titleText);

            if obj.showLegend
                legend(ax, "show", ...
                    "Location", "southoutside", ...
                    "Orientation", "horizontal");
            else
                legend(ax, "off");
            end

            hold(ax, "off");
        end
    end

    methods (Access = private)
        function [rowIdx, faultGroup] = resolveRowAndFaultGroup( ...
                obj, gt, row, faultType, sel)

            hasRow = ~isempty(row);
            hasKey = (faultType ~= "") && ~isempty(sel);

            if hasRow == hasKey
                error("sfrfs:viz:RFGFViewer:SelectionRequired", ...
                    "Specify row, or faultType and selection.");
            end

            if hasRow
                obj.validateRow(row, height(gt));
                rowIdx = row;
                faultGroup = obj.faultGroupForRow(gt, rowIdx);
                return
            end

            faultGroup = obj.faultTypeToGroup(faultType);

            try
                rowIdx = FaultConditionSelector.selectRow( ...
                    gt, faultGroup=faultGroup, selection=sel);
            catch ME
                error("sfrfs:viz:RFGFViewer:RowResolutionFailed", ...
                    "Failed to resolve row: %s", ME.message);
            end

            obj.validateRow(rowIdx, height(gt));

            % Use table's own FaultGroup for the resolved row, if
            % available, otherwise keep the one we used.
            try
                faultGroup = obj.faultGroupForRow(gt, rowIdx);
            catch
                % If the table lacks the column, keep faultGroup as-is.
            end
        end

        function validateRow(~, row, nRows)
            if ~isscalar(row) || ~isfinite(row) || row <= 0 || ...
                    row ~= floor(row)
                error("sfrfs:viz:RFGFViewer:InvalidRow", ...
                    "row must be a positive integer scalar.");
            end
            if row > nRows
                error("sfrfs:viz:RFGFViewer:RowIndexOutOfRange", ...
                    "row exceeds table height.");
            end
        end

        function [c, s] = extractMasks(~, masks, f)
            if ~isstruct(masks) || ...
                    ~isfield(masks, "CenterFrequencyBankMask") || ...
                    ~isfield(masks, "SurroundFrequencyBankMask")
                error("sfrfs:viz:RFGFViewer:InvalidFrequencyBankMasks", ...
                    "FrequencyBankMasks entry is invalid.");
            end

            c = masks.CenterFrequencyBankMask(:);
            s = masks.SurroundFrequencyBankMask(:);

            if numel(c) ~= numel(f) || numel(s) ~= numel(f)
                error("sfrfs:viz:RFGFViewer:MaskDomainSizeMismatch", ...
                    "Mask length does not match frequency domain.");
            end
        end

        function fg = faultGroupForRow(obj, gt, rowIdx)
            kFG = obj.colName("FAULTGROUP", "FaultGroup");
            if ~ismember(kFG, string(gt.Properties.VariableNames))
                error("sfrfs:viz:RFGFViewer:MissingFaultGroupColumn", ...
                    "FaultGroup column missing.");
            end

            fg = gt.(kFG)(rowIdx);

            if isempty(fg) || ~isscalar(fg) || ~isfinite(fg)
                error("sfrfs:viz:RFGFViewer:FaultGroupUnavailable", ...
                    "FaultGroup value invalid at the selected row.");
            end
        end

        function fg = faultTypeToGroup(obj, faultType)
            fb = obj.rfgfs.frequencyBands;
            if isempty(fb)
                error("sfrfs:viz:RFGFViewer:MissingFrequencyBands", ...
                    "frequencyBands not available on rfgfs.");
            end

            if ~isprop(fb, "faultTypeGroups")
                error("sfrfs:viz:RFGFViewer:FaultTypeGroupsMissing", ...
                    "frequencyBands has no faultTypeGroups mapping.");
            end

            m = fb.faultTypeGroups;

            if isa(m, "containers.Map")
                if ~isKey(m, faultType)
                    error("sfrfs:viz:RFGFViewer:FaultTypeUnknown", ...
                        "Unknown faultType: %s", faultType);
                end
                fg = m(faultType);
                return
            end

            if isa(m, "function_handle")
                fg = m(faultType);
                return
            end

            error("sfrfs:viz:RFGFViewer:FaultTypeGroupsUnsupported", ...
                "faultTypeGroups must be a containers.Map or function.");
        end

        function k = getInhibitionFactorFromFaultGroup(obj, faultGroup)
            fb = obj.rfgfs.frequencyBands;
            if isempty(fb)
                error("sfrfs:viz:RFGFViewer:MissingFrequencyBands", ...
                    "frequencyBands not available on rfgfs.");
            end

            faultType = obj.resolveFaultTypeName(fb, faultGroup);

            p = fb.sfrfsParams.getParamsForFaultType(faultType);
            if ~isfield(p, "inhibitionFactor")
                error("sfrfs:viz:RFGFViewer:MissingInhibitionFactor", ...
                    "inhibitionFactor missing in fault params.");
            end

            k = p.inhibitionFactor;
        end

        function faultType = resolveFaultTypeName(~, fb, faultGroup)
            m = fb.faultGroupToTypeName;

            if isa(m, "function_handle")
                faultType = m(faultGroup);
                return
            end

            if isa(m, "containers.Map")
                if ~isKey(m, faultGroup)
                    error("sfrfs:viz:RFGFViewer:FaultGroupKeyMissing", ...
                        "FaultGroup not present in map.");
                end
                faultType = m(faultGroup);
                return
            end

            if isstruct(m)
                key = matlab.lang.makeValidName(string(faultGroup));
                if ~isfield(m, key)
                    error("sfrfs:viz:RFGFViewer:FaultGroupFieldMissing", ...
                        "FaultGroup not present in struct.");
                end
                faultType = m.(key);
                return
            end

            error("sfrfs:viz:RFGFViewer:FaultGroupToTypeNameUnsupported", ...
                "Unsupported faultGroupToTypeName type.");
        end

        function ax = ensureAxes(obj, overrideParent)
            if obj.isAxes(overrideParent)
                ax = overrideParent;
                obj.parent = ax;
                return
            end

            if obj.isAxes(obj.parent)
                ax = obj.parent;
                return
            end

            fig = figure("Name", "RFGFs Viewer");
            ax = axes(fig);
            obj.parent = ax;
        end

        function tf = isAxes(~, x)
            tf = ~isempty(x) && isgraphics(x) && isvalid(x) && ...
                (isa(x, "matlab.graphics.axis.Axes") || ...
                 isa(x, "matlab.ui.control.UIAxes"));
        end

        function validateFrequencyLimits(~, x)
            if isempty(x)
                return
            end
            if ~isnumeric(x) || ~isreal(x) || any(~isfinite(x(:)))
                error("sfrfs:viz:RFGFViewer:InvalidFrequencyLimits", ...
                    "frequencyLimits must be real and finite, or [].");
            end
            if ~isequal(size(x), [1 2]) || ~(x(1) < x(2))
                error("sfrfs:viz:RFGFViewer:InvalidFrequencyLimits", ...
                    "frequencyLimits must be [min max] with min < max.");
            end
        end

        function lim = resolveLimits(obj, f, override)
            if ~isempty(override)
                obj.validateFrequencyLimits(override);
                lim = override;
                return
            end

            if ~isempty(obj.frequencyLimits)
                lim = obj.frequencyLimits;
                return
            end

            lim = [f(1), f(end) / 2];
        end

        function applyTitle(obj, ax, gt, rowIdx, override)
            if ~obj.showTitle
                title(ax, "");
                return
            end

            if override ~= ""
                title(ax, override);
                return
            end

            if obj.titleText ~= ""
                title(ax, obj.titleText);
                return
            end

            kDesc = obj.colName("DESCRIPTION", "Description");
            kSpd  = obj.colName("SPEED", "Speed");
            kLd   = obj.colName("LOAD", "Load");

            fault = "";
            spd = NaN;
            ld  = NaN;

            if ismember(kDesc, string(gt.Properties.VariableNames))
                fault = string(gt.(kDesc)(rowIdx));
            end
            if ismember(kSpd, string(gt.Properties.VariableNames))
                spd = gt.(kSpd)(rowIdx);
            end
            if ismember(kLd, string(gt.Properties.VariableNames))
                ld = gt.(kLd)(rowIdx);
            end

            if fault ~= "" && ~isnan(spd) && ~isnan(ld)
                title(ax, sprintf( ...
                    "RFGFs - %s, Speed = %.2f Hz, Load = %.2f", ...
                    fault, spd, ld));
            elseif fault ~= ""
                title(ax, "RFGFs - " + fault);
            else
                title(ax, "RFGFs");
            end
        end

        function name = colName(~, schemaField, fallback)
            name = string(fallback);
            try
                ms = tables.FaultConditionTableMetaSchema;
                if isprop(ms, schemaField)
                    name = string(ms.(schemaField));
                end
            catch
                % Optional schema.
            end
        end

        function lbl = contrastLabel(~, k)
            lbl = sprintf("Contrast (c - k*s, k = %.3g)", k);
        end
    end
end
