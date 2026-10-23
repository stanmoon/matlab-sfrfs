classdef TestOnOffContrastPolarityDetector < matlab.unittest.TestCase

    methods (Test)

        function firstSnapshotHasNoEvents(testCase)

            C = [ ...
                1, -2,  0; ...
                0, -2,  3];

            [eOn, eOff] = OnOffContrastPolarityDetector.detect(C, 1);

            testCase.verifyEqual(eOn, [0, 0, 0]);
            testCase.verifyEqual(eOff, [0, 0, 0]);

        end

        function detectsOnEvents(testCase)

            C = [ ...
                0,  0,  1, -2; ...
                3, -4,  1, -2];

            [eOn, eOff] = OnOffContrastPolarityDetector.detect(C, 2);

            testCase.verifyEqual(eOn, [1, -1, 0, 0]);
            testCase.verifyEqual(eOff, [0, 0, 0, 0]);

        end

        function detectsOffEvents(testCase)

            C = [ ...
                3, -4,  0,  0; ...
                0,  0,  0, -2];

            [eOn, eOff] = OnOffContrastPolarityDetector.detect(C, 2);

            testCase.verifyEqual(eOn, [0, 0, 0, -1]);
            testCase.verifyEqual(eOff, [1, -1, 0, 0]);

        end

        function detectAllReturnsSignedMaps(testCase)

            C = [ ...
                0,  2,  0; ...
                1,  0, -3; ...
               -2,  4,  0; ...
                0,  0,  5];

            [onMap, offMap] = ...
                OnOffContrastPolarityDetector.detectAll(C);

            expectedOn = [ ...
                0,  0,  0; ...
                1,  0, -1; ...
                0,  1,  0; ...
                0,  0,  1];

            expectedOff = [ ...
                0,  0,  0; ...
                0,  1,  0; ...
                0,  0, -1; ...
               -1,  1,  0];

            testCase.verifyEqual(onMap, expectedOn);
            testCase.verifyEqual(offMap, expectedOff);

        end

        function summarizeReturnsCounts(testCase)

            C = [ ...
                0,  2,  0; ...
                1,  0, -3; ...
               -2,  4,  0; ...
                0,  0,  5];

            summary = OnOffContrastPolarityDetector.summarize(C);

            testCase.verifyEqual( ...
                summary.PositiveOnCountPerHarmonic, ...
                [1; 1; 1]);

            testCase.verifyEqual( ...
                summary.NegativeOnCountPerHarmonic, ...
                [0; 0; 1]);

            testCase.verifyEqual( ...
                summary.PositiveOffCountPerHarmonic, ...
                [0; 2; 0]);

            testCase.verifyEqual( ...
                summary.NegativeOffCountPerHarmonic, ...
                [1; 0; 1]);

        end

        function nonFiniteTrajectoryFails(testCase)

            C = [1, 0; NaN, -2];

            testCase.verifyError( ...
                @() OnOffContrastPolarityDetector.detect(C, 2), ...
                "sfrfs:OnOffContrastPolarityDetector:InvalidContrast");

        end

        function emptyTrajectoryFails(testCase)

            C = [];

            testCase.verifyError( ...
                @() OnOffContrastPolarityDetector.detect(C, 1), ...
                "sfrfs:OnOffContrastPolarityDetector:InvalidContrast");

        end

        function invalidSnapshotFails(testCase)

            C = [1, 0; 0, -1];

            testCase.verifyError( ...
                @() OnOffContrastPolarityDetector.detect(C, 3), ...
                "sfrfs:OnOffContrastPolarityDetector:InvalidSnapshot");

        end

    end

end