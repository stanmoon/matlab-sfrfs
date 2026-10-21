classdef LiftedHarmonicResponseCompute < handle
%LiftedHarmonicResponseCompute
%
% Applies lifted center/surround harmonic masks and evaluates injected
% RFRFs independently on the resulting center/surround spectra.
%
% Convention:
% This class owns the lifted-mask application and the historical SFRFs
% FFT-length amplitude scaling. RFRFs receive already masked and scaled
% spectra. If a receptiveFieldResponseBinder is supplied, masks are passed
% to the binder only for normalization or parameterization.

    properties (SetAccess = private)
        snapshotParameters
        liftedGainFunctions LiftedHarmonicGainFunctions
    end

    methods

        function obj = LiftedHarmonicResponseCompute(args)
            arguments
                args.snapshotParameters (1,1) ParametersSnapshot
                args.liftedGainFunctions (1,1) ...
                    LiftedHarmonicGainFunctions
            end

            obj.snapshotParameters = args.snapshotParameters;
            obj.liftedGainFunctions = args.liftedGainFunctions;
        end

        function responses = compute(obj, args)
            arguments
                obj
                args.memberTable table
                args.spectralColumn (1,1) string
                args.receptiveFieldResponseFunction ...
                    function_handle = function_handle.empty()
                args.receptiveFieldResponseBinder ...
                    function_handle = function_handle.empty()
            end

            obj.validateResponseArguments(args);

            f = obj.liftedGainFunctions.frequencyDomain;
            tbl = obj.liftedGainFunctions.liftedGainFunctionsTable;

            X = obj.readSpectra(args.memberTable, args.spectralColumn);

            nSnapshots = size(X, 2);
            nH = height(tbl);
            nFFT = size(X, 1);

            Rc = zeros(nSnapshots, nH);
            Rs = zeros(nSnapshots, nH);

            for i = 1:nH
                masks = tbl.FrequencyBankMasks{i};

                centerMask = masks.CenterMask(:);
                surroundMask = masks.SurroundMask(:);

                obj.validateMaskLength(centerMask, nFFT);
                obj.validateMaskLength(surroundMask, nFFT);

                % Historical SFRFs convention:
                % apply masks upstream, then scale by FFT length before
                % RFRF evaluation. This keeps the generalized lifted
                % pipeline compatible with the older SFRFsCompute response
                % scale, where abs(X .* mask) / N was integrated.
                Xc = (centerMask .* X) ./ nFFT;
                Xs = (surroundMask .* X) ./ nFFT;

                [rfC, rfS] = obj.resolveRFRFs( ...
                    args, ...
                    centerMask, ...
                    surroundMask);

                Rc(:, i) = rfC(Xc, f).';
                Rs(:, i) = rfS(Xs, f).';
            end

            responses = struct( ...
                "Center", Rc, ...
                "Surround", Rs, ...
                "HarmonicIndex", tbl.HarmonicIndex, ...
                "CenterFrequencyHz", tbl.CenterFrequencyHz);
        end

    end

    methods (Static, Access = private)

        function validateResponseArguments(args)
            hasFcn = ~isempty(args.receptiveFieldResponseFunction);
            hasBinder = ~isempty(args.receptiveFieldResponseBinder);

            if hasFcn == hasBinder
                error( ...
                    "sfrfs:LiftedHarmonicResponseCompute:" + ...
                    "InvalidResponseSpecification", ...
                    "Specify exactly one RFRF function or RFRF binder.");
            end
        end

        function validateMaskLength(mask, nFFT)
            if numel(mask) ~= nFFT
                error( ...
                    "sfrfs:LiftedHarmonicResponseCompute:" + ...
                    "MaskLengthMismatch", ...
                    "Mask length must match spectrum length.");
            end
        end

        function [rfC, rfS] = resolveRFRFs(args, centerMask, surroundMask)
            if ~isempty(args.receptiveFieldResponseBinder)
                rfC = args.receptiveFieldResponseBinder(centerMask);
                rfS = args.receptiveFieldResponseBinder(surroundMask);
                return
            end

            rfC = args.receptiveFieldResponseFunction;
            rfS = args.receptiveFieldResponseFunction;
        end

        function X = readSpectra(memberTable, spectralColumn)
            spectra = memberTable.(spectralColumn);

            if ~iscell(spectra)
                X = spectra;
                return
            end

            if isscalar(spectra) && isnumeric(spectra{1})
                X = spectra{1};
                return
            end

            nSnapshots = numel(spectra);
            nBins = numel(spectra{1});

            X = zeros(nBins, nSnapshots, "like", spectra{1});

            for i = 1:nSnapshots
                X(:, i) = spectra{i}(:);
            end
        end

    end

end