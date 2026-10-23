classdef ContrastPolarityExplorationDatasetBuilder < handle
%CONTRASTPOLARITYEXPLORATIONDATASETBUILDER Assemble exploratory contrast-polarity data.
%
% An exploratory, intermediate representation: the builder retains
% sensor-local contrasts, agreement-resolved contrast, polarity events,
% and conventional condition indicators. It does NOT infer degradation,
% perform prognosis, select discriminative hypotheses, or learn memories.
%
% One output table row represents one dataset member and one monitored
% bearing-frequency family. Matrix-valued channels remain T_i-by-H_i;
% conventional indicator columns contain T_i-by-1 vectors in cells.
%
% Usage (XJTU-SY configuration from the original script):
%   ds = EnsembleDatastoreRegistry.getEnsemble("XJTU-SY");
%   diagnosisTable = ...; % provide the original XJTU-SY lookup table
%   builder = ContrastPolarityExplorationDatasetBuilder( ...
%       diagnosisTable = diagnosisTable);
%   result = builder.buildFromEnsemble(ds);
%   channelRunsQ95 = result.Table;
%
% By default, buildFromEnsemble computes the dataset without saving it.
% Use saveToFile=true for MAT-file persistence. Without outputFile, the
% filename follows contrast_polarity_family_channel_dataset_Q95_<stamp>.mat
% (with Q95 determined by quantileLevel). A supplied outputFile overrides
% the filename. An existing file is never overwritten implicitly.
%
%   result = builder.buildFromEnsemble(ds, saveToFile = true);
%   result = builder.buildFromEnsemble(ds, saveToFile = true, ...
%       outputFile = "results/contrast_polarity_run.mat");
%
% Session timestamps and execution timings differ between runs. Numerical
% parity with the original Live Script requires identical inputs and configuration.

    properties (SetAccess = private)
        SnapshotParameters
        BearingParameters
        SFRFsParameters
        TemporalColumns (1,:) string
        SpectralColumns (1,:) string
        FamilyNames (1,:) string
        ReceptiveFieldResponseBinder
        ContrastMapping
        QuantileLevel (1,1) double
        RiseRate (1,1) double
        FallRate (1,1) double
        EntropyEpsilon (1,1) double
        DiagnosisTable table
    end

    methods
        function obj = ContrastPolarityExplorationDatasetBuilder(args)
            arguments
                args.snapshotParameters = ParametersSnapshot( ...
                    samplingFrequency = 25600, duration = 1.28, stride = 60)
                args.bearingParameters = ParametersRollingBearings( ...
                    numRollingElements = 8, ballDiameter = 7.92, ...
                    pitchDiameter = 34.55, contactAngle = 0)
                args.sfrfsParameters = ...
                    SFRFsParametersRollingBearings( ...
                    SameForAllFaultTypes = SFRFsParameters.buildSFRFsParameters( ...
                    order = 0, numSidebands = 0, numHarmonics = 1, ...
                    centerMask = SuperGaussianMaskParameters(alpha = 2, beta = 8), ...
                    surroundMask = SuperGaussianMaskParameters(alpha = 6, beta = 2), ...
                    inhibitionFactor = 1))
                args.temporalColumns (1,:) string = ...
                    ["HorizontalAcceleration", "VerticalAcceleration"]
                args.spectralColumns (1,:) string = ...
                    ["HorizontalAcceleration_FFT", "VerticalAcceleration_FFT"]
                args.familyNames (1,:) string = ["BPFO", "BPFI", "BSF", "FTF"]
                args.receptiveFieldResponseBinder = ...
                    ReceptiveFieldResponseFunctions.maskedMeanAbs()
                args.contrastMapping = ContrastMappings.difference()
                args.quantileLevel (1,1) double = 0.95
                args.riseRate (1,1) double = 1/7
                args.fallRate (1,1) double = 1/49
                args.epsEntropy (1,1) double = 1e-12
                args.diagnosisTable table = table()
            end
            if ~isequal(args.familyNames, ["BPFO", "BPFI", "BSF", "FTF"])
                error("sfrfs:ExplorationDataset:Families", ...
                    "This extracted workflow currently supports BPFO, BPFI, BSF, FTF in that order.");
            end
            obj.SnapshotParameters = args.snapshotParameters;
            obj.BearingParameters = args.bearingParameters;
            obj.SFRFsParameters = args.sfrfsParameters;
            obj.TemporalColumns = args.temporalColumns;
            obj.SpectralColumns = args.spectralColumns;
            obj.FamilyNames = args.familyNames;
            obj.ReceptiveFieldResponseBinder = args.receptiveFieldResponseBinder;
            obj.ContrastMapping = args.contrastMapping;
            obj.QuantileLevel = args.quantileLevel;
            obj.RiseRate = args.riseRate;
            obj.FallRate = args.fallRate;
            obj.EntropyEpsilon = args.epsEntropy;
            obj.DiagnosisTable = args.diagnosisTable;
        end

        function result = buildFromEnsemble(obj, ds, args)
            arguments
                obj
                ds
                args.saveToFile (1,1) logical = false
                args.outputFile (1,1) string = ""
            end
            if strlength(args.outputFile) > 0 && ~args.saveToFile
                error("sfrfs:ExplorationDataset:SaveNotEnabled", ...
                    "Set saveToFile=true when specifying outputFile.");
            end
            totalTimer = tic;
            required = ["Label", "SnapshotIndex", "Speed", "Load", "Lifetime", ...
                obj.TemporalColumns, obj.SpectralColumns];
            available = string([ds.IndependentVariables(:); ...
                ds.ConditionVariables(:); ds.DataVariables(:)]);
            missing = setdiff(required, available);
            if ~isempty(missing)
                error("sfrfs:ExplorationDataset:MissingVariables", ...
                    "Missing datastore variables: %s", strjoin(missing, ", "));
            end
            if ~isempty(obj.DiagnosisTable)
                needed = ["Label", "Failure_O", "Failure_I", "Failure_C", "Failure_B"];
                assert(all(ismember(needed, string(obj.DiagnosisTable.Properties.VariableNames))), ...
                    "Diagnosis table must contain Label and Failure_O/I/C/B.");
            end
            ds.SelectedVariables = required;
            reset(ds);
            nMembers = ds.NumMembers;
            rows = cell(nMembers, 1);
            timings = repmat(struct('Label', "", 'Speed', NaN, 'Load', NaN, ...
                'NumSnapshots', NaN, 'H_BPFO', NaN, 'H_BPFI', NaN, ...
                'H_BSF', NaN, 'H_FTF', NaN, 'LiftedSeconds', NaN, ...
                'BuildRowsSeconds', NaN, 'CIsSeconds', NaN, ...
                'DiagnosisSeconds', NaN, 'TotalMemberSeconds', NaN), nMembers, 1);
            memberIdx = 0;
            while hasdata(ds)
                memberTimer = tic;
                memberIdx = memberIdx + 1;
                memberTable = read(ds);
                label = string(memberTable.Label(1));
                speed = double(memberTable.Speed(1));
                load = double(memberTable.Load(1));
                timings(memberIdx).Label = label;
                timings(memberIdx).Speed = speed;
                timings(memberIdx).Load = load;
                timings(memberIdx).NumSnapshots = height(memberTable);

                timer = tic;
                liftedByFamily = obj.liftedByFamily(speed, load);
                timings(memberIdx).LiftedSeconds = toc(timer);
                channelBuilder = ContrastPolarityChannelDatasetBuilder( ...
                    liftedGainFunctionsByFamily = liftedByFamily, ...
                    familyNames = obj.FamilyNames);
                timer = tic;
                memberRows = channelBuilder.buildMemberRows( ...
                    memberTable = memberTable, ...
                    spectralColumns = obj.SpectralColumns, ...
                    receptiveFieldResponseBinder = obj.ReceptiveFieldResponseBinder, ...
                    contrastMapping = obj.ContrastMapping, ...
                    quantileLevel = obj.QuantileLevel, ...
                    riseRate = obj.RiseRate, fallRate = obj.FallRate);
                timings(memberIdx).BuildRowsSeconds = toc(timer);

                timer = tic;
                ci = obj.computeTraditionalCIs(memberTable);
                names = string(fieldnames(ci));
                for k = 1:numel(names)
                    name = names(k);
                    memberRows.(name) = repmat({ci.(char(name))(:)}, height(memberRows), 1);
                end
                timings(memberIdx).CIsSeconds = toc(timer);

                timer = tic;
                if ~isempty(obj.DiagnosisTable)
                    diagRow = obj.DiagnosisTable( ...
                        string(obj.DiagnosisTable.Label) == label, :);
                    if height(diagRow) ~= 1
                        error("sfrfs:ExplorationDataset:DiagnosisLookupFailed", ...
                            "Expected one diagnosis row for %s; found %d.", ...
                            label, height(diagRow));
                    end
                    for name = ["Failure_O", "Failure_I", "Failure_C", "Failure_B"]
                        memberRows.(name) = repmat(diagRow.(name), height(memberRows), 1);
                    end
                end
                timings(memberIdx).DiagnosisSeconds = toc(timer);
                rows{memberIdx} = memberRows;
                H = memberRows.HarmonicCount.';
                timings(memberIdx).H_BPFO = H(1);
                timings(memberIdx).H_BPFI = H(2);
                timings(memberIdx).H_BSF = H(3);
                timings(memberIdx).H_FTF = H(4);
                timings(memberIdx).TotalMemberSeconds = toc(memberTimer);
            end
            if memberIdx == 0
                error("sfrfs:ExplorationDataset:EmptyEnsemble", ...
                    "The ensemble yielded no members.");
            end
            channelRuns = vertcat(rows{1:memberIdx});
            timingTable = struct2table(timings(1:memberIdx));
            totalSeconds = toc(totalTimer);
            timingSummary = table(totalSeconds, ...
                sum(timingTable.LiftedSeconds, "omitnan"), ...
                sum(timingTable.BuildRowsSeconds, "omitnan"), ...
                sum(timingTable.CIsSeconds, "omitnan"), ...
                sum(timingTable.DiagnosisSeconds, "omitnan"), ...
                mean(timingTable.TotalMemberSeconds, "omitnan"), ...
                median(timingTable.TotalMemberSeconds, "omitnan"), ...
                max(timingTable.TotalMemberSeconds), ...
                VariableNames = ["TotalSeconds", "TotalLiftedSeconds", ...
                "TotalBuildRowsSeconds", "TotalCIsSeconds", ...
                "TotalDiagnosisSeconds", "MeanMemberSeconds", ...
                "MedianMemberSeconds", "MaxMemberSeconds"]);
            tag = "Q" + string(round(100 * obj.QuantileLevel));
            stamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
            runTag = tag + "_" + stamp;
            fileName = "contrast_polarity_family_channel_dataset_" + runTag + ".mat";
            if strlength(args.outputFile) > 0
                fileName = args.outputFile;
                [~, ~, extension] = fileparts(fileName);
                if strlength(string(extension)) == 0
                    fileName = fileName + ".mat";
                elseif ~strcmpi(extension, '.mat')
                    error("sfrfs:ExplorationDataset:InvalidExtension", ...
                        "outputFile must have a .mat extension.");
                end
            end
            session = struct("CreatedAt", stamp, "CompletedAt", string(datetime("now")), ...
                "RunTimestamp", stamp, "RunTag", runTag, ...
                "DatasetTag", tag, "OutputFile", fileName, ...
                "OutputVariableName", "channelRuns" + tag, ...
                "MatlabVersion", string(version), "TotalSeconds", totalSeconds);
            parameters = struct("SnapshotParameters", obj.SnapshotParameters, ...
                "BearingParameters", obj.BearingParameters, ...
                "SFRFsParameters", obj.SFRFsParameters, ...
                "TemporalColumns", obj.TemporalColumns, ...
                "SpectralColumns", obj.SpectralColumns, "FamilyNames", obj.FamilyNames, ...
                "QuantileLevel", obj.QuantileLevel, "RiseRate", obj.RiseRate, ...
                "FallRate", obj.FallRate, "EntropyEpsilon", obj.EntropyEpsilon, ...
                "ReceptiveFieldResponseBinder", obj.ReceptiveFieldResponseBinder, ...
                "ContrastMapping", obj.ContrastMapping);
            result = struct("Table", channelRuns, "Parameters", parameters, ...
                "Timing", timingTable, "TimingSummary", timingSummary, ...
                "SessionInfo", session, ...
                "ChannelNames", ContrastPolarityChannelDatasetBuilder.ChannelNames, ...
                "RawContrastNames", ...
                    ContrastPolarityChannelDatasetBuilder.rawContrastNames(obj.SpectralColumns), ...
                "TraditionalCIColumnNames", obj.traditionalCIColumnNames(), ...
                "FamilyNames", obj.FamilyNames, ...
                "MatrixLayout", ContrastPolarityChannelDatasetBuilder.MatrixLayout, ...
                "TemporalColumns", obj.TemporalColumns, ...
                "SpectralColumns", obj.SpectralColumns, ...
                "OutputFile", "", "Saved", false);
            if args.saveToFile
                if isfile(fileName)
                    error("sfrfs:ExplorationDataset:OutputFileExists", ...
                        "Refusing to overwrite existing file: %s", fileName);
                end
                [folder, ~, ~] = fileparts(fileName);
                if strlength(string(folder)) > 0 && ~isfolder(folder)
                    error("sfrfs:ExplorationDataset:OutputFolderMissing", ...
                        "Output directory does not exist: %s", string(folder));
                end
                % Preserve the variable names consumed by earlier scripts:
                % channelRunsQxx, channelRuns, dataset, paramsTable,
                % timingTable, timingSummary and sessionInfo.
                result.OutputFile = fileName;
                result.Saved = true;
                payload = struct();
                payload.(char(session.OutputVariableName)) = channelRuns;
                payload.channelRuns = channelRuns;
                payload.dataset = result;
                payload.paramsTable = result.Parameters;
                payload.timingTable = timingTable;
                payload.timingSummary = timingSummary;
                payload.sessionInfo = session;
                save(char(fileName), "-struct", "payload", "-v7.3");
            end
        end
    end

    methods (Access = private)
        function lifted = liftedByFamily(obj, speed, load)
            sel = OperatingConditionSelection(speed = speed, load = load);
            oc = OperatingConditions(speed, load);
            bfb = BearingFrequencyBands(bearingParams = obj.BearingParameters, ...
                sfrfsParams = obj.SFRFsParameters, operatingConditions = oc);
            faultTypes = SFRFsParametersRollingBearings.faultTypes;
            codes = {BearingFrequencyBands.BPFO_CODE, BearingFrequencyBands.BPFI_CODE, ...
                BearingFrequencyBands.BSF_CODE, BearingFrequencyBands.FTF_CODE};
            lifted = cell(1, numel(codes));
            for j = 1:numel(codes)
                fc = bfb.getCentralFrequency(codes{j}, speed);
                item = LiftedHarmonicGainFunctions( ...
                    snapshotParameters = obj.SnapshotParameters, ...
                    sfrfsParameters = obj.SFRFsParameters, ...
                    faultType = string(faultTypes{j}), selection = sel, ...
                    characteristicFrequencyHz = fc);
                item.compute();
                lifted{j} = item;
            end
        end

        function ci = computeTraditionalCIs(obj, memberTable)
            n = height(memberTable);
            ci = struct();
            rmsStack = zeros(n, numel(obj.TemporalColumns));
            for j = 1:numel(obj.TemporalColumns)
                col = obj.TemporalColumns(j);
                signals = memberTable.(col);
                timeRMS = zeros(n, 1); timeP2P = zeros(n, 1);
                timeCF = zeros(n, 1); timeKurt = zeros(n, 1);
                for i = 1:n
                    x = signals{i};
                    timeRMS(i) = sqrt(mean(x.^2));
                    timeP2P(i) = max(x) - min(x);
                    if timeRMS(i) > 0
                        timeCF(i) = max(abs(x)) / timeRMS(i);
                    else
                        timeCF(i) = 0;
                    end
                    timeKurt(i) = kurtosis(x);
                end
                rmsStack(:, j) = timeRMS;
                ci.(char(col + "_RMS")) = timeRMS;
                ci.(char(col + "_PeakToPeak")) = timeP2P;
                ci.(char(col + "_CrestFactor")) = timeCF;
                ci.(char(col + "_Kurtosis")) = timeKurt;
            end
            ci.MaxRMS = max(rmsStack, [], 2);
            f = obj.SnapshotParameters.getFrequencyDomain(); f = f(:);
            bandwidth = f(end) - f(1);
            rmsStack = zeros(n, numel(obj.SpectralColumns));
            for j = 1:numel(obj.SpectralColumns)
                col = obj.SpectralColumns(j);
                spectra = memberTable.(col);
                specEnergy = zeros(n, 1); specRMS = zeros(n, 1);
                specPeak = zeros(n, 1); specEntropy = zeros(n, 1);
                for i = 1:n
                    X = spectra{i}; Xmag = abs(X(:));
                    specEnergy(i) = trapz(f, Xmag.^2);
                    if bandwidth > 0
                        specRMS(i) = sqrt(specEnergy(i) / bandwidth);
                    else
                        specRMS(i) = 0;
                    end
                    specPeak(i) = max(Xmag);
                    p = Xmag ./ (sum(Xmag) + obj.EntropyEpsilon);
                    specEntropy(i) = -sum(p .* log(p + obj.EntropyEpsilon));
                end
                rmsStack(:, j) = specRMS;
                ci.(char(col + "_SpectralEnergy")) = specEnergy;
                ci.(char(col + "_SpectralRMS")) = specRMS;
                ci.(char(col + "_PeakMagnitude")) = specPeak;
                ci.(char(col + "_SpectralEntropy")) = specEntropy;
            end
            ci.MaxSpectralRMS = max(rmsStack, [], 2);
        end

        function names = traditionalCIColumnNames(obj)
            names = strings(0, 1);
            for col = obj.TemporalColumns
                names(end+1,1) = col + "_RMS";
                names(end+1,1) = col + "_PeakToPeak";
                names(end+1,1) = col + "_CrestFactor";
                names(end+1,1) = col + "_Kurtosis";
            end
            names(end+1,1) = "MaxRMS";
            for col = obj.SpectralColumns
                names(end+1,1) = col + "_SpectralEnergy";
                names(end+1,1) = col + "_SpectralRMS";
                names(end+1,1) = col + "_PeakMagnitude";
                names(end+1,1) = col + "_SpectralEntropy";
            end
            names(end+1,1) = "MaxSpectralRMS";
        end
    end
end
