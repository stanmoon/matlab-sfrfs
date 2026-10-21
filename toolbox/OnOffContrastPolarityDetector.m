classdef OnOffContrastPolarityDetector
%ONOFFCONTRASTPOLARITYDETECTOR Detect signed contrast polarity ON/OFF events.
%
% Detects transitions between zero and nonzero harmonic contrasts,
% preserving the polarity of the newly active or previously active
% response in the corresponding ON or OFF event.
%
% Provides snapshot-wise detection, trajectory-wide signed event maps,
% and per-harmonic positive and negative event counts.

    methods (Static)

        function [eOn, eOff] = detect(C, t)

            arguments
                C {mustBeNumeric, mustBeReal}
                t (1,1) {mustBeInteger, mustBePositive}
            end

            OnOffContrastPolarityDetector.mustHaveValidTrajectory(C);
            OnOffContrastPolarityDetector.mustHaveValidSnapshotIndex(C, t);

            eOn = zeros(1, size(C, 2), "like", C);
            eOff = zeros(1, size(C, 2), "like", C);

            if t == 1
                return
            end

            previous = C(t - 1, :);
            current = C(t, :);

            previousSign = sign(previous);
            currentSign = sign(current);

            onMask = previousSign == 0 & currentSign ~= 0;
            offMask = previousSign ~= 0 & currentSign == 0;

            eOn(onMask) = currentSign(onMask);
            eOff(offMask) = previousSign(offMask);

        end

        function [onMap, offMap] = detectAll(C)

            arguments
                C {mustBeNumeric, mustBeReal}
            end

            OnOffContrastPolarityDetector.mustHaveValidTrajectory(C);

            onMap = zeros(size(C), "like", C);
            offMap = zeros(size(C), "like", C);

            for t = 1:size(C, 1)
                [eOn, eOff] = ...
                    OnOffContrastPolarityDetector.detect(C, t);

                onMap(t, :) = eOn;
                offMap(t, :) = eOff;
            end

        end

        function summary = summarize(C)

            arguments
                C {mustBeNumeric, mustBeReal}
            end

            OnOffContrastPolarityDetector.mustHaveValidTrajectory(C);

            [onMap, offMap] = ...
                OnOffContrastPolarityDetector.detectAll(C);

            summary = struct( ...
                "OnMap", onMap, ...
                "OffMap", offMap, ...
                "PositiveOnCountPerHarmonic", ...
                    sum(onMap > 0, 1).', ...
                "NegativeOnCountPerHarmonic", ...
                    sum(onMap < 0, 1).', ...
                "PositiveOffCountPerHarmonic", ...
                    sum(offMap > 0, 1).', ...
                "NegativeOffCountPerHarmonic", ...
                    sum(offMap < 0, 1).');

        end

    end

    methods (Static, Access = private)

        function mustHaveValidTrajectory(C)

            if ~ismatrix(C) || isempty(C)
                error( ...
                    "sfrfs:OnOffContrastPolarityDetector:InvalidContrast", ...
                    "Contrast trajectory must be a nonempty matrix.");
            end

            if any(~isfinite(C(:)))
                error( ...
                    "sfrfs:OnOffContrastPolarityDetector:InvalidContrast", ...
                    "Contrast trajectory must contain only finite values.");
            end

        end

        function mustHaveValidSnapshotIndex(C, t)

            if t > size(C, 1)
                error( ...
                    "sfrfs:OnOffContrastPolarityDetector:InvalidSnapshot", ...
                    "Snapshot index exceeds trajectory length.");
            end

        end

    end

end