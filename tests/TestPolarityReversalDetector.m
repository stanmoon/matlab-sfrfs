classdef TestPolarityReversalDetector < matlab.unittest.TestCase

    methods (Test)

        function initialStateHasNoEvents(testCase)

            c = [1, -2, 0];
            state = zeros(size(c));

            [Hrev, state] = PolarityReversalDetector.detect(c, state);

            testCase.verifyEmpty(Hrev);
            testCase.verifyEqual(state, [1, -1, 0]);

        end

        function detectsEpisodePolarityReversals(testCase)

            state = [1, -1, 0, 1];
            c = [-1, -3, 5, -4];

            [Hrev, state] = PolarityReversalDetector.detect(c, state);

            testCase.verifyEqual(Hrev, [1, 4]);
            testCase.verifyEqual(state, [-1, -1, 1, -1]);

        end

        function zerosDoNotResetState(testCase)

            state = [1, -1, -1];
            c = [0, 0, 2];

            [Hrev, state] = PolarityReversalDetector.detect(c, state);

            testCase.verifyEqual(Hrev, 3);
            testCase.verifyEqual(state, [1, -1, 1]);

        end

        function detectAllReturnsEpisodeEventMask(testCase)

            C = [ ...
                1,  2, -3; ...
                0,  2,  0; ...
               -1, -2,  3; ...
                2, -3, -4];

            eventMask = PolarityReversalDetector.detectAll(C);

            expected = [ ...
                false, false, false; ...
                false, false, false; ...
                true,  true,  true; ...
                true,  false, true];

            testCase.verifyEqual(eventMask, expected);

        end

        function summarizeReturnsCountsAndRates(testCase)

            C = [ ...
                1,  2, -3; ...
                0,  2,  0; ...
               -1, -2,  3; ...
                2, -3, -4];

            summary = PolarityReversalDetector.summarize(C);

            testCase.verifyEqual(summary.CountPerHarmonic, [2; 1; 2]);
            testCase.verifyEqual(summary.RatePerHarmonic, [2; 1; 2] ./ 3);

            testCase.verifyEqual(summary.SnapshotIndex, [3; 4; 3; 3; 4]);
            testCase.verifyEqual(summary.HarmonicIndex, [1; 1; 2; 3; 3]);

        end

        function nonFiniteSnapshotFails(testCase)

            c = [1, NaN, 3];
            state = zeros(size(c));

            testCase.verifyError( ...
                @() PolarityReversalDetector.detect(c, state), ...
                "sfrfs:PolarityReversalDetector:InvalidContrast");

        end

        function emptySnapshotFails(testCase)

            c = [];
            state = [];

            testCase.verifyError( ...
                @() PolarityReversalDetector.detect(c, state), ...
                "sfrfs:PolarityReversalDetector:InvalidContrast");

        end

        function stateSizeMismatchFails(testCase)

            c = [1, -1, 2];
            state = [0, 0];

            testCase.verifyError( ...
                @() PolarityReversalDetector.detect(c, state), ...
                "sfrfs:PolarityReversalDetector:SizeMismatch");

        end

        function invalidStateFails(testCase)

            c = [1, -1, 2];
            state = [0, 2, 0];

            testCase.verifyError( ...
                @() PolarityReversalDetector.detect(c, state), ...
                "sfrfs:PolarityReversalDetector:InvalidState");

        end

    end

end