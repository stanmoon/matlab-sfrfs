classdef LiftedHarmonicGainFunctions < handle
%LiftedHarmonicGainFunctions
%
% Builds center/surround mask banks for selected harmonics of one
% characteristic frequency.

    properties
        liftedGainFunctionsTable table = table.empty
        frequencyDomain double = []
    end

    properties (SetAccess = private)
        snapshotParameters
        sfrfsParameters
        faultType string
        selection
        characteristicFrequencyHz double
        harmonicIndices double
    end

    methods
        function obj = LiftedHarmonicGainFunctions(args)
            arguments
                args.snapshotParameters (1,1) ParametersSnapshot
                args.sfrfsParameters (1,1) SFRFsParametersRollingBearings
                args.faultType (1,1) string
                args.selection (1,1) OperatingConditionSelection
                args.characteristicFrequencyHz (1,1) double ...
                    {mustBePositive}
                args.harmonicIndices (:,1) double ...
                    {mustBeInteger, mustBePositive} = double.empty(0, 1)
            end

            obj.snapshotParameters = args.snapshotParameters;
            obj.sfrfsParameters = args.sfrfsParameters;
            obj.faultType = args.faultType;
            obj.selection = args.selection;
            obj.characteristicFrequencyHz = ...
                args.characteristicFrequencyHz;

            obj.harmonicIndices = obj.resolveHarmonicIndices( ...
                harmonicIndices = args.harmonicIndices, ...
                characteristicFrequencyHz = ...
                    args.characteristicFrequencyHz, ...
                snapshotParameters = args.snapshotParameters);
        end

        function compute(obj)
            f = obj.snapshotParameters.getFrequencyDomain();
            obj.frequencyDomain = f(:);

            p = obj.sfrfsParameters.(obj.faultType);
            centerParams = p.centerMask;
            surroundParams = p.surroundMask;

            alphaC = obj.getHalfWidth(centerParams);
            alphaS = obj.getHalfWidth(surroundParams);

            h = obj.harmonicIndices;
            nH = numel(h);

            CenterFrequencyHz = h .* obj.characteristicFrequencyHz;
            CenterBandHz = cell(nH, 1);
            SurroundBandHz = cell(nH, 1);
            FrequencyBankMasks = cell(nH, 1);

            for i = 1:nH
                fc = CenterFrequencyHz(i);

                centerBand = [fc - alphaC, fc + alphaC];
                surroundBand = [fc - alphaS, fc + alphaS];

                centerMask = FrequencyMask.evaluate( ...
                    obj.frequencyDomain, ...
                    centerBand, ...
                    centerParams);

                surroundMask = FrequencyMask.evaluate( ...
                    obj.frequencyDomain, ...
                    surroundBand, ...
                    surroundParams);

                CenterBandHz{i} = centerBand;
                SurroundBandHz{i} = surroundBand;

                FrequencyBankMasks{i} = struct( ...
                    "CenterMask", centerMask, ...
                    "SurroundMask", surroundMask);
            end

            FaultType = repmat(obj.faultType, nH, 1);
            HarmonicIndex = h;

            obj.liftedGainFunctionsTable = table( ...
                FaultType, ...
                HarmonicIndex, ...
                CenterFrequencyHz, ...
                CenterBandHz, ...
                SurroundBandHz, ...
                FrequencyBankMasks);
        end
    end

    methods (Static)

        function maxHarmonic = computeMaxHarmonicIndex(args)
            arguments
                args.snapshotParameters (1,1) ParametersSnapshot
                args.characteristicFrequencyHz (1,1) double ...
                    {mustBePositive}
            end
    
            f = args.snapshotParameters.getFrequencyDomain();
            f = f(:);
            f = f(isfinite(f));
    
            if isempty(f)
                error( ...
                    "sfrfs:LiftedHarmonicGainFunctions:InvalidFreqDomain", ...
                    "The frequency domain must contain finite values.");
            end
    
            fNyquist = ...
                LiftedHarmonicGainFunctions.getNyquistFrequency( ...
                    args.snapshotParameters, ...
                    f);
    
            nSupport = ...
                LiftedHarmonicGainFunctions.getPositiveSupportSize( ...
                    f, ...
                    fNyquist);
    
            maxByFrequency = floor( ...
                fNyquist / args.characteristicFrequencyHz);
    
            maxByBins = max(nSupport, 0);
    
            maxHarmonic = min(maxByFrequency, maxByBins);
    
            if maxHarmonic < 1
                error( ...
                    "sfrfs:LiftedHarmonicGainFunctions:NoHarmonics", ...
                    "No harmonic lies within the usable frequency support.");
            end
        end
    
    end

    methods (Static, Access = private)

        function harmonicIndices = resolveHarmonicIndices(args)
            arguments
                args.harmonicIndices (:,1) double
                args.characteristicFrequencyHz (1,1) double ...
                    {mustBePositive}
                args.snapshotParameters (1,1) ParametersSnapshot
            end

            f = args.snapshotParameters.getFrequencyDomain();
            f = f(:);
            f = f(isfinite(f));

            if isempty(f)
                error( ...
                    "sfrfs:LiftedHarmonicGainFunctions:InvalidFreqDomain", ...
                    "The frequency domain must contain finite values.");
            end

            fNyquist = ...
                LiftedHarmonicGainFunctions.getNyquistFrequency( ...
                    args.snapshotParameters, ...
                    f);

            nSupport = ...
                LiftedHarmonicGainFunctions.getPositiveSupportSize( ...
                    f, ...
                    fNyquist);

            maxByFrequency = floor( ...
                fNyquist / args.characteristicFrequencyHz);

            maxByBins = max(nSupport, 0);

            maxHarmonic = min(maxByFrequency, maxByBins);

            if maxHarmonic < 1
                error( ...
                    "sfrfs:LiftedHarmonicGainFunctions:NoHarmonics", ...
                    "No harmonic lies within the usable frequency support.");
            end

            if isempty(args.harmonicIndices)
                harmonicIndices = (1:maxHarmonic).';
                return
            end

            harmonicIndices = args.harmonicIndices(:);

            if any(harmonicIndices > maxHarmonic)
                error( ...
                    "sfrfs:LiftedHarmonicGainFunctions:HarmonicRange", ...
                    "Requested harmonics exceed the computable maximum.");
            end
        end

        function fNyquist = getNyquistFrequency(snapshotParameters, f)
            fs = LiftedHarmonicGainFunctions.getSamplingFrequency( ...
                snapshotParameters);

            if isfinite(fs) && fs > 0
                fNyquist = fs / 2;
                return
            end

            fNonnegative = f(f >= 0);

            if isempty(fNonnegative)
                error( ...
                    "sfrfs:LiftedHarmonicGainFunctions:InvalidFreqDomain", ...
                    "The frequency domain has no nonnegative values.");
            end

            fNyquist = max(fNonnegative);
        end

        function fs = getSamplingFrequency(snapshotParameters)
            fs = NaN;

            if isprop(snapshotParameters, "samplingFrequencyHz")
                fs = snapshotParameters.samplingFrequencyHz;
                return
            end

            if isprop(snapshotParameters, "samplingFrequency")
                fs = snapshotParameters.samplingFrequency;
                return
            end

            if isprop(snapshotParameters, "fs")
                fs = snapshotParameters.fs;
                return
            end

            if isprop(snapshotParameters, "Fs")
                fs = snapshotParameters.Fs;
                return
            end

            if ismethod(snapshotParameters, "getSamplingFrequencyHz")
                fs = snapshotParameters.getSamplingFrequencyHz();
                return
            end

            if ismethod(snapshotParameters, "getSamplingFrequency")
                fs = snapshotParameters.getSamplingFrequency();
            end
        end

        function nSupport = getPositiveSupportSize(f, fNyquist)
            f = f(:);
            f = f(isfinite(f));

            if isempty(f)
                nSupport = 0;
                return
            end

            fNonnegative = f(f >= 0);
            tol = LiftedHarmonicGainFunctions.frequencyTolerance(fNyquist);

            if isempty(fNonnegative)
                nSupport = 0;
                return
            end

            if max(fNonnegative) > fNyquist + tol
                nSupport = floor(numel(f) / 2);
                return
            end

            nSupport = nnz(fNonnegative <= fNyquist + tol);
        end

        function tol = frequencyTolerance(fNyquist)
            tol = max(1e-9, 1e-9 * abs(fNyquist));
        end

        function w = getHalfWidth(maskParams)
            if isprop(maskParams, "alpha")
                w = maskParams.alpha;
                return
            end

            if isprop(maskParams, "bandwidth")
                w = maskParams.bandwidth / 2;
                return
            end

            error( ...
                "sfrfs:LiftedHarmonicGainFunctions:InvalidMaskParams", ...
                "Mask parameters must expose alpha or bandwidth.");
        end

    end
end