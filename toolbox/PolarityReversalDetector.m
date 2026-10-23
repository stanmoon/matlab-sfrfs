classdef PolarityReversalDetector
%POLARITYREVERSALDETECTOR Detect harmonic contrast polarity reversals.
%
% Detects changes between successive nonzero contrast polarities,
% ignoring zero-valued observations without resetting polarity state.
%
% Provides snapshot-wise detection, trajectory-wide event masks,
% and per-harmonic reversal counts and rates.

    methods (Static)

        function [Hrev, state] = detect(c, state)

            arguments
                c {mustBeNumeric, mustBeReal}
                state {mustBeNumeric, mustBeReal}
            end

            PolarityReversalDetector.mustHaveValidSnapshot(c);
            PolarityReversalDetector.mustHaveValidState(c, state);

            u = sign(c);

            activeMask = u ~= 0;
            reversalMask = activeMask & (state .* u < 0);

            Hrev = find(reversalMask);

            state(activeMask) = u(activeMask);

        end

        function eventMask = detectAll(C)

            arguments
                C {mustBeNumeric, mustBeReal}
            end

            PolarityReversalDetector.mustHaveValidTrajectory(C);

            eventMask = false(size(C));
            state = zeros(1, size(C, 2), "like", C);

            for t = 1:size(C, 1)
                [Hrev, state] = ...
                    PolarityReversalDetector.detect(C(t, :), state);

                eventMask(t, Hrev) = true;
            end

        end

        function summary = summarize(C)

            arguments
                C {mustBeNumeric, mustBeReal}
            end

            PolarityReversalDetector.mustHaveValidTrajectory(C);

            eventMask = PolarityReversalDetector.detectAll(C);

            countPerHarmonic = sum(eventMask, 1).';
            ratePerHarmonic = ...
                countPerHarmonic ./ max(size(C, 1) - 1, 1);

            [snapshotIndex, harmonicIndex] = find(eventMask);

            summary = struct( ...
                "EventMask", eventMask, ...
                "SnapshotIndex", snapshotIndex, ...
                "HarmonicIndex", harmonicIndex, ...
                "CountPerHarmonic", countPerHarmonic, ...
                "RatePerHarmonic", ratePerHarmonic);

        end

    end

    methods (Static, Access = private)

        function mustHaveValidSnapshot(c)

            if ~isvector(c) || isempty(c)
                error( ...
                    "sfrfs:PolarityReversalDetector:InvalidContrast", ...
                    "Contrast snapshot must be a nonempty vector.");
            end

            if any(~isfinite(c(:)))
                error( ...
                    "sfrfs:PolarityReversalDetector:InvalidContrast", ...
                    "Contrast snapshot must contain only finite values.");
            end

        end

        function mustHaveValidTrajectory(C)

            if ~ismatrix(C) || isempty(C)
                error( ...
                    "sfrfs:PolarityReversalDetector:InvalidContrast", ...
                    "Contrast trajectory must be a nonempty matrix.");
            end

            if any(~isfinite(C(:)))
                error( ...
                    "sfrfs:PolarityReversalDetector:InvalidContrast", ...
                    "Contrast trajectory must contain only finite values.");
            end

        end

        function mustHaveValidState(c, state)

            if ~isequal(size(c), size(state))
                error( ...
                    "sfrfs:PolarityReversalDetector:SizeMismatch", ...
                    "Contrast snapshot and detector state must have the same size.");
            end

            if any(~isfinite(state(:))) || ...
                    any(~ismember(state(:), [-1, 0, 1]))
                error( ...
                    "sfrfs:PolarityReversalDetector:InvalidState", ...
                    "Detector state must contain only values -1, 0, or 1.");
            end

        end

    end

end