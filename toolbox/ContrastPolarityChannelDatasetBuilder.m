classdef ContrastPolarityChannelDatasetBuilder < handle
%CONTRASTPOLARITYCHANNELDATASETBUILDER Build harmonic contrast and event datasets.
%
% Constructs prognosis-channel datasets from spectral observations of
% bearing runs, with one output row per run and monitored fault family.
%
% The processing combines lifted harmonic receptive-field responses,
% sensor-local center-surround contrast, cross-sensor polarity
% agreement filtering, and temporal polarity event detection.
%
% Public methods:
%   buildFromEnsemble - Process all members of a data ensemble.
%   buildMemberRows   - Build channel rows for one ensemble member.
%
% Static methods:
%   rawContrastNames  - Generate sensor-local contrast column names.
%
% Construction:
%   obj = ContrastPolarityChannelDatasetBuilder( ...
%       liftedGainFunctionsByFamily = liftedFunctions, ...
%       familyNames = ["BPFO", "BPFI", "BSF", "FTF"]);
%
% Each output table row represents one bearing/run and one monitored
% fault-frequency family. The columns are:
%
%   Label, Speed, Load, Lifetime, MonitoredFaultFamily, HarmonicCount
%   Failure_O, Failure_I, Failure_C, Failure_B
%   <SpectralColumn1>_C, <SpectralColumn2>_C
%   AgreementFloor, ResolvedContrast, PolarityReversal
%   OnPositive, OnNegative, OffPositive, OffNegative
%
% The raw contrast column names follow the convention
% <signal>_<representation>_C, for example:
%
%   HorizontalAcceleration_FFT_C
%
% Contrast and event matrices have dimensions T x H, where T is the
% number of observations and H the number of monitored harmonics.
% AgreementFloor is a T x 1 temporal history.
%
% Matrix-valued channels are stored in table cells, preserving
% per-run dimensions without introducing global padding.
%
% buildFromEnsemble returns a structure with fields:
%   Table            - Combined channel table.
%   ChannelNames     - Computed channel names.
%   RawContrastNames - Sensor-local contrast column names.
%   FamilyNames      - Monitored fault-family names.
%   MatrixLayout     - ["snapshot", "harmonic"].
%   SpectralColumns  - Source spectral column names.
%
% The five event channels are logical matrices. PolarityReversal
% indicates a reversal event; OnPositive, OnNegative, OffPositive,
% and OffNegative distinguish signed activity transitions.
%
% See also LiftedHarmonicGainFunctions, LiftedHarmonicResponseCompute,
% ReceptiveFieldResponseFunctions, ContrastMappings,
% ContrastPolarityFilter, PolarityReversalDetector,
% OnOffContrastPolarityDetector.

    properties (Constant)
        ChannelNames = [ ...
            "ResolvedContrast", ...
            "PolarityReversal", ...
            "OnPositive", ...
            "OnNegative", ...
            "OffPositive", ...
            "OffNegative"];

        MatrixLayout = [ ...
            "snapshot", ...
            "harmonic"];
    end

    properties (SetAccess = private)
        familyNames string
        liftedGainFunctionsByFamily cell
        computeByFamily cell
    end

    methods

        function obj = ContrastPolarityChannelDatasetBuilder(args)
            arguments
                args.liftedGainFunctionsByFamily (1,:) cell
                args.familyNames (1,:) string = ...
                    ["BPFO", "BPFI", "BSF", "FTF"]
            end

            if numel(args.liftedGainFunctionsByFamily) ...
                    ~= numel(args.familyNames)
                error( ...
                    "sfrfs:ChannelDatasetBuilder:FamilyMismatch", ...
                    "familyNames and liftedGainFunctionsByFamily " + ...
                    "must have the same length.");
            end

            obj.familyNames = args.familyNames;
            obj.liftedGainFunctionsByFamily = ...
                args.liftedGainFunctionsByFamily;

            obj.computeByFamily = cell(size(args.familyNames));

            for f = 1:numel(args.familyNames)
                lifted = args.liftedGainFunctionsByFamily{f};

                obj.computeByFamily{f} = ...
                    LiftedHarmonicResponseCompute( ...
                        snapshotParameters = ...
                            lifted.snapshotParameters, ...
                        liftedGainFunctions = lifted);
            end
        end

        function dataset = buildFromEnsemble(obj, args)
            arguments
                obj
                args.ensemble
                args.spectralColumns (1,2) string
                args.receptiveFieldResponseFunction ...
                    function_handle = ...
                    ReceptiveFieldResponseFunctions.integralAbs()
                args.receptiveFieldResponseBinder ...
                    function_handle = function_handle.empty()
                args.contrastMapping function_handle = ...
                    ContrastMappings.difference()
                args.quantileLevel (1,1) double = 0.9
                args.riseRate (1,1) double = 1/7
                args.fallRate (1,1) double = 1/49
            end

            reset(args.ensemble);

            rows = cell(args.ensemble.NumMembers, 1);
            row = 0;

            while hasdata(args.ensemble)
                row = row + 1;
                memberTable = read(args.ensemble);

                rows{row} = obj.buildMemberRows( ...
                    memberTable = memberTable, ...
                    spectralColumns = args.spectralColumns, ...
                    receptiveFieldResponseFunction = ...
                        args.receptiveFieldResponseFunction, ...
                    receptiveFieldResponseBinder = ...
                        args.receptiveFieldResponseBinder, ...
                    contrastMapping = args.contrastMapping, ...
                    quantileLevel = args.quantileLevel, ...
                    riseRate = args.riseRate, ...
                    fallRate = args.fallRate);
            end

            channelRuns = vertcat(rows{1:row});

            dataset = struct( ...
                "Table", channelRuns, ...
                "ChannelNames", obj.ChannelNames, ...
                "RawContrastNames", ...
                    obj.rawContrastNames(args.spectralColumns), ...
                "FamilyNames", obj.familyNames, ...
                "MatrixLayout", obj.MatrixLayout, ...
                "SpectralColumns", args.spectralColumns);
        end

        function rows = buildMemberRows(obj, args)
            arguments
                obj
                args.memberTable table
                args.spectralColumns (1,2) string
                args.receptiveFieldResponseFunction ...
                    function_handle = ...
                    ReceptiveFieldResponseFunctions.integralAbs()
                args.receptiveFieldResponseBinder ...
                    function_handle = function_handle.empty()
                args.contrastMapping function_handle = ...
                    ContrastMappings.difference()
                args.quantileLevel (1,1) double = 0.9
                args.riseRate (1,1) double = 1/7
                args.fallRate (1,1) double = 1/49
            end

            nFamilies = numel(obj.familyNames);
            rawNames = obj.rawContrastNames(args.spectralColumns);

            Label = strings(nFamilies, 1);
            Speed = nan(nFamilies, 1);
            Load = nan(nFamilies, 1);
            Lifetime = nan(nFamilies, 1);
            MonitoredFaultFamily = strings(nFamilies, 1);
            HarmonicCount = nan(nFamilies, 1);

            Failure_O = nan(nFamilies, 1);
            Failure_I = nan(nFamilies, 1);
            Failure_C = nan(nFamilies, 1);
            Failure_B = nan(nFamilies, 1);

            RawContrast1 = cell(nFamilies, 1);
            RawContrast2 = cell(nFamilies, 1);
            AgreementFloor = cell(nFamilies, 1);

            ResolvedContrast = cell(nFamilies, 1);
            PolarityReversal = cell(nFamilies, 1);
            OnPositive = cell(nFamilies, 1);
            OnNegative = cell(nFamilies, 1);
            OffPositive = cell(nFamilies, 1);
            OffNegative = cell(nFamilies, 1);

            for f = 1:nFamilies
                [C, tau, CBySensor] = obj.computeResolvedContrast( ...
                    familyIndex = f, ...
                    memberTable = args.memberTable, ...
                    spectralColumns = args.spectralColumns, ...
                    receptiveFieldResponseFunction = ...
                        args.receptiveFieldResponseFunction, ...
                    receptiveFieldResponseBinder = ...
                        args.receptiveFieldResponseBinder, ...
                    contrastMapping = args.contrastMapping, ...
                    quantileLevel = args.quantileLevel, ...
                    riseRate = args.riseRate, ...
                    fallRate = args.fallRate);

                channels = obj.computeChannels(C);

                Label(f) = obj.readString(args.memberTable, "Label");
                Speed(f) = obj.readScalar(args.memberTable, "Speed");
                Load(f) = obj.readScalar(args.memberTable, "Load");
                Lifetime(f) = obj.readScalar(args.memberTable, "Lifetime");

                MonitoredFaultFamily(f) = obj.familyNames(f);
                HarmonicCount(f) = size(C, 2);

                Failure_O(f) = obj.readScalar(args.memberTable, "Failure_O");
                Failure_I(f) = obj.readScalar(args.memberTable, "Failure_I");
                Failure_C(f) = obj.readScalar(args.memberTable, "Failure_C");
                Failure_B(f) = obj.readScalar(args.memberTable, "Failure_B");

                RawContrast1{f} = CBySensor{1};
                RawContrast2{f} = CBySensor{2};
                AgreementFloor{f} = tau(:);

                ResolvedContrast{f} = channels.ResolvedContrast;
                PolarityReversal{f} = channels.PolarityReversal;
                OnPositive{f} = channels.OnPositive;
                OnNegative{f} = channels.OnNegative;
                OffPositive{f} = channels.OffPositive;
                OffNegative{f} = channels.OffNegative;
            end

            rows = table( ...
                Label, ...
                Speed, ...
                Load, ...
                Lifetime, ...
                MonitoredFaultFamily, ...
                HarmonicCount, ...
                Failure_O, ...
                Failure_I, ...
                Failure_C, ...
                Failure_B, ...
                RawContrast1, ...
                RawContrast2, ...
                AgreementFloor, ...
                ResolvedContrast, ...
                PolarityReversal, ...
                OnPositive, ...
                OnNegative, ...
                OffPositive, ...
                OffNegative);

            rows.Properties.VariableNames(11:12) = cellstr(rawNames);
        end

    end

    methods (Static)

        function names = rawContrastNames(spectralColumns)
            arguments
                spectralColumns (1,:) string
            end

            names = spectralColumns + "_C";
        end

    end

    methods (Access = private)

        function [C, tau, CBySensor] = computeResolvedContrast(obj, args)
            arguments
                obj
                args.familyIndex (1,1) ...
                    {mustBeInteger, mustBePositive}
                args.memberTable table
                args.spectralColumns (1,2) string
                args.receptiveFieldResponseFunction function_handle
                args.receptiveFieldResponseBinder function_handle
                args.contrastMapping function_handle
                args.quantileLevel (1,1) double
                args.riseRate (1,1) double
                args.fallRate (1,1) double
            end

            C1 = obj.computeContrastForColumn( ...
                familyIndex = args.familyIndex, ...
                memberTable = args.memberTable, ...
                spectralColumn = args.spectralColumns(1), ...
                receptiveFieldResponseFunction = ...
                    args.receptiveFieldResponseFunction, ...
                receptiveFieldResponseBinder = ...
                    args.receptiveFieldResponseBinder, ...
                contrastMapping = args.contrastMapping);

            C2 = obj.computeContrastForColumn( ...
                familyIndex = args.familyIndex, ...
                memberTable = args.memberTable, ...
                spectralColumn = args.spectralColumns(2), ...
                receptiveFieldResponseFunction = ...
                    args.receptiveFieldResponseFunction, ...
                receptiveFieldResponseBinder = ...
                    args.receptiveFieldResponseBinder, ...
                contrastMapping = args.contrastMapping);

            CBySensor = {C1, C2};

            nSnapshots = size(C1, 1);
            C = zeros(size(C1), "like", C1);
            tau = zeros(nSnapshots, 1);

            for t = 1:nSnapshots
                [~, tau, C(t, :), ~] = ...
                    ContrastPolarityFilter.apply( ...
                        C1(t, :), ...
                        C2(t, :), ...
                        t, ...
                        tau, ...
                        args.quantileLevel, ...
                        args.riseRate, ...
                        args.fallRate);
            end
        end

        function C = computeContrastForColumn(obj, args)
            arguments
                obj
                args.familyIndex (1,1) ...
                    {mustBeInteger, mustBePositive}
                args.memberTable table
                args.spectralColumn (1,1) string
                args.receptiveFieldResponseFunction function_handle
                args.receptiveFieldResponseBinder function_handle
                args.contrastMapping function_handle
            end

            compute = obj.computeByFamily{args.familyIndex};

            if isempty(args.receptiveFieldResponseBinder)
                responses = compute.compute( ...
                    memberTable = args.memberTable, ...
                    spectralColumn = args.spectralColumn, ...
                    receptiveFieldResponseFunction = ...
                        args.receptiveFieldResponseFunction);
            else
                responses = compute.compute( ...
                    memberTable = args.memberTable, ...
                    spectralColumn = args.spectralColumn, ...
                    receptiveFieldResponseBinder = ...
                        args.receptiveFieldResponseBinder);
            end

            C = args.contrastMapping( ...
                responses.Center.', ...
                responses.Surround.');

            C = C.';
        end

        function channels = computeChannels(~, C)

            reversalMap = PolarityReversalDetector.detectAll(C);

            [onMap, offMap] = ...
                OnOffContrastPolarityDetector.detectAll(C);

            channels = struct( ...
                "ResolvedContrast", C, ...
                "PolarityReversal", abs(reversalMap) > 0, ...
                "OnPositive", onMap > 0, ...
                "OnNegative", onMap < 0, ...
                "OffPositive", offMap > 0, ...
                "OffNegative", offMap < 0);
        end

        function value = readScalar(~, memberTable, name)

            if ~ismember(name, string(memberTable.Properties.VariableNames))
                value = NaN;
                return
            end

            value = memberTable.(name)(1);

            if iscell(value)
                value = value{1};
            end

            value = double(value);
        end

        function value = readString(~, memberTable, name)

            if ~ismember(name, string(memberTable.Properties.VariableNames))
                value = missing;
                return
            end

            value = string(memberTable.(name)(1));
        end

    end
end