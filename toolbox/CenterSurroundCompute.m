classdef CenterSurroundCompute < handle
%CenterSurroundCompute  Compute center/surround responses via RFGFs.
%
% Stores snapshot parameters and RFGFs handle, and computes receptive-field
% responses on stacked spectra extracted from a run-to-failure member 
% table.

    properties (SetAccess = private)
        paramsSnapshot ParametersSnapshot
        rfgfs ReceptiveFieldGainFunctions
    end

    properties (Dependent)
        samplingFrequency double
        sfrfsParams SFRFsParameters
        rfgfsTable table
        operatingConditions table
    end

    methods
        function obj = CenterSurroundCompute(args)
            arguments
                args.snapshotParameters ParametersSnapshot
                args.rfgfs ReceptiveFieldGainFunctions
            end
            obj.paramsSnapshot = args.snapshotParameters;
            obj.rfgfs = args.rfgfs;
        end

        function val = get.samplingFrequency(obj)
            val = obj.paramsSnapshot.samplingFrequency;
        end

        function val = get.sfrfsParams(obj)
            val = obj.rfgfs.frequencyBands.sfrfsParams;
        end

        function val = get.rfgfsTable(obj)
            val = obj.rfgfs.gainFunctionsTable;
        end

        function val = get.operatingConditions(obj)
            val = obj.rfgfs.frequencyBands.operatingConditions;
        end

        function [contrast, centerResponse, surroundResponse, ...
            centerMask, surroundMask, contrastMask] = ...
            compute(obj, args)
        %compute Compute center, surround, and contrast responses.
        %
        %   [contrast, centerResponse, surroundResponse, ...
        %       centerMask, surroundMask, contrastMask] = ...
        %       compute(Name=Value)
        %
        % Computes receptive-field responses by applying spectral masks to 
        % stacked spectra and evaluating a configurable response function. 
        % A contrast response is then derived via a
        % configurable contrast mapping.
        %
        % Selection (choose one):
        %   - row
        %   - faultType + selection
        %
        % Name-Value:
        %   memberTable  - Run-to-failure member table.
        %   spectralColumn
        %                - FFT column in memberTable.
        %   row          - Row in gainFunctionsTable.
        %   faultType    - Fault type to resolve group.
        %   selection    - OperatingConditionSelection.
        %   receptiveFieldResponseFunction
        %                - Handle: r = fcn(X, f).
        %   contrastMapping
        %                - Handle or empty (default).
        %
        % Outputs:
        %   centerResponse
        %                - Response of center-masked spectra.
        %   surroundResponse
        %                - Response of surround-masked spectra.
        %   contrast     - Response obtained via the contrast mapping.
        %   centerMask   - Center gain mask over frequency.
        %   surroundMask - Surround gain mask over frequency.
        %   contrastMask - DoG-like gain: centerMask - k*surroundMask.

            arguments
                obj
                args.memberTable table {mustBeNonempty}
                args.spectralColumn (1,1) string

                args.row double = []
                args.faultType (1,1) string = ""
                args.selection OperatingConditionSelection = ...
                    OperatingConditionSelection.empty()

                args.receptiveFieldResponseFunction (1,1) ...
                    function_handle = ...
                    ReceptiveFieldResponseFunctions.integralAbs()

                args.contrastMapping function_handle = ...
                    function_handle.empty()
            end

            import tables.GainFunctionsTableSchema
            import structs.FrequencyBankMasksSchema

            gt = obj.rfgfs.gainFunctionsTable;

            f = obj.paramsSnapshot.getFrequencyDomain();
            f = f(:);

            X = CenterSurroundCompute.stackSpectra( ...
                memberTable=args.memberTable, ...
                spectralColumn=args.spectralColumn);

            if numel(f) ~= size(X, 1)
                error(['sfrfs:CenterSurroundCompute:' ...
                       'FreqAxisMismatch'], ...
                    "FrequencyDomain length must match FFT bins.");
            end

            rowIdx = obj.resolveRow( ...
                row=args.row, ...
                faultType=args.faultType, ...
                selection=args.selection);

            kMasksT = GainFunctionsTableSchema.FREQUENCYBANKMASKS;
            masks = gt.(kMasksT){rowIdx};

            kC = FrequencyBankMasksSchema.CENTER;
            kS = FrequencyBankMasksSchema.SURROUND;

            C = masks.(kC)(:);
            S = masks.(kS)(:);

            centerMask = C;
            surroundMask = S;

            faultGroup = obj.faultGroupForRow(gt, rowIdx);
            k = obj.getInhibitionFactorFromFaultGroup(faultGroup);

            contrastMask = C - k .* S;

            Xc = X .* C;
            Xs = X .* S;

            Rc = args.receptiveFieldResponseFunction(Xc, f);
            Rs = args.receptiveFieldResponseFunction(Xs, f);

            centerResponse = Rc;
            surroundResponse = Rs;

            if isempty(args.contrastMapping)
                map = ContrastMappings.difference(k=k);
                contrast = map(Rc, Rs);

            else
                contrast = args.contrastMapping(Rc, Rs);
            end
        end
    end

    methods (Access = private)
        function rowIdx = resolveRow(obj, args)
            arguments
                obj
                args.row double
                args.faultType (1,1) string
                args.selection OperatingConditionSelection
            end

            gt = obj.rfgfs.gainFunctionsTable;

            hasRow = ~isempty(args.row);
            hasKey = (args.faultType ~= "") && ~isempty(args.selection);

            if hasRow == hasKey
                error(['sfrfs:CenterSurroundCompute:' ...
                       'SelectionRequired'], ...
                    "Specify row, or faultType and selection.");
            end

            if hasRow
                rowIdx = args.row;
                obj.validateRow(rowIdx, height(gt));
                return
            end

            faultGroup = obj.faultTypeToGroup(args.faultType);

            try
                rowIdx = FaultConditionSelector.selectRow( ...
                    gt, ...
                    faultGroup=faultGroup, ...
                    selection=args.selection);
            catch ME
                error(['sfrfs:CenterSurroundCompute:' ...
                       'RowResolutionFailed'], ...
                    "Failed to resolve row: %s", ME.message);
            end

            obj.validateRow(rowIdx, height(gt));
        end

        function validateRow(~, row, nRows)
            badRow = ~isscalar(row) || ~isfinite(row) || row <= 0 || ...
                (row ~= floor(row));
            if badRow
                error(['sfrfs:CenterSurroundCompute:' ...
                       'InvalidRow'], ...
                    "row must be a positive integer scalar.");
            end
            if row > nRows
                error(['sfrfs:CenterSurroundCompute:' ...
                       'RowIndexOutOfRange'], ...
                    "row exceeds table height.");
            end
        end

        function fg = faultTypeToGroup(obj, faultType)
            fb = obj.rfgfs.frequencyBands;

            if isempty(fb) || ~isprop(fb, "faultTypeGroups")
                error(['sfrfs:CenterSurroundCompute:' ...
                       'FaultTypeGroupsMissing'], ...
                    "frequencyBands.faultTypeGroups mapping is missing.");
            end

            m = fb.faultTypeGroups;

            if isa(m, "containers.Map")
                if ~isKey(m, faultType)
                    error(['sfrfs:CenterSurroundCompute:' ...
                           'FaultTypeUnknown'], ...
                        "Unknown faultType: %s", faultType);
                end
                fg = m(faultType);
                return
            end

            if isa(m, "function_handle")
                fg = m(faultType);
                return
            end

            error(['sfrfs:CenterSurroundCompute:' ...
                   'FaultTypeGroupsUnsupported'], ...
                "faultTypeGroups must be a containers.Map or function.");
        end

        function fg = faultGroupForRow(~, gt, rowIdx)
            import tables.GainFunctionsTableSchema
            kFG = GainFunctionsTableSchema.FAULTGROUP;

            if ~ismember(kFG, string(gt.Properties.VariableNames))
                error(['sfrfs:CenterSurroundCompute:' ...
                       'MissingFaultGroupColumn'], ...
                    "FaultGroup column missing in gainFunctionsTable.");
            end

            fg = gt.(kFG)(rowIdx);

            if isempty(fg) || ~isscalar(fg) || ~isfinite(fg)
                error(['sfrfs:CenterSurroundCompute:' ...
                       'FaultGroupUnavailable'], ...
                    "FaultGroup value invalid at the selected row.");
            end
        end

        function k = getInhibitionFactorFromFaultGroup(obj, faultGroup)
            fb = obj.rfgfs.frequencyBands;
            if isempty(fb)
                error(['sfrfs:CenterSurroundCompute:' ...
                       'MissingFrequencyBands'], ...
                    "frequencyBands not available on rfgfs.");
            end

            faultType = obj.resolveFaultTypeName(fb, faultGroup);

            p = fb.sfrfsParams.getParamsForFaultType(faultType);
            if ~isfield(p, "inhibitionFactor")
                error(['sfrfs:CenterSurroundCompute:' ...
                       'MissingInhibitionFactor'], ...
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
                    error(['sfrfs:CenterSurroundCompute:' ...
                           'FaultGroupKeyMissing'], ...
                        "FaultGroup not present in map.");
                end
                faultType = m(faultGroup);
                return
            end

            if isstruct(m)
                key = matlab.lang.makeValidName(string(faultGroup));
                if ~isfield(m, key)
                    error(['sfrfs:CenterSurroundCompute:' ...
                           'FaultGroupFieldMissing'], ...
                        "FaultGroup not present in struct.");
                end
                faultType = m.(key);
                return
            end

            error(['sfrfs:CenterSurroundCompute:' ...
                   'FaultGroupToTypeNameUnsupported'], ...
                "Unsupported faultGroupToTypeName type.");
        end
    end

    methods (Static, Access = private)
        function X = stackSpectra(args)
            arguments
                args.memberTable table {mustBeNonempty}
                args.spectralColumn (1,1) string
            end

            col = char(args.spectralColumn);

            if ~ismember(col, args.memberTable.Properties.VariableNames)
                error(['sfrfs:CenterSurroundCompute:' ...
                       'MissingColumn'], ...
                    "Spectral column '%s' not found.", col);
            end

            c = args.memberTable.(col);

            if ~iscell(c) || isempty(c)
                error(['sfrfs:CenterSurroundCompute:' ...
                       'InvalidColumn'], ...
                    "Column '%s' must be a nonempty cell array.", col);
            end

            if ~all(cellfun(@(x) isnumeric(x) && ~isempty(x), c))
                error(['sfrfs:CenterSurroundCompute:' ...
                       'InvalidCells'], ...
                    "Column '%s' must contain numeric FFT vectors.", col);
            end

            ref = size(c{1});
            if ~all(cellfun(@(x) isequal(size(x), ref), c))
                error(['sfrfs:CenterSurroundCompute:' ...
                       'SizeMismatch'], ...
                    "FFT vectors in '%s' have inconsistent sizes.", col);
            end

            X = [c{:}];
        end
    end
end
