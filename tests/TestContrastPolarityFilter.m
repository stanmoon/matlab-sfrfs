classdef TestContrastPolarityFilter < matlab.unittest.TestCase

    methods (Test)

        function basicAgreementSelection(testCase)

            cV = [1, -2, 3, -4];
            cH = [2, -1, -5, -2];

            [Hrel, tau, c, s] = ...
                ContrastPolarityFilter.apply( ...
                    cV, cH, 1, zeros(1,1), 0.5, 0.5, 0.5);

            testCase.verifyEqual(s, [1, 1, 3, 2]);
            testCase.verifyEqual(c, [1.5, -1.5, 0, -3]);
            testCase.verifyEqual(Hrel, [1, 2, 4]);
            testCase.verifyEqual(tau(end), 1);

        end

        function quantileUsesSignedEvidencePopulation(testCase)

            cV = [4, 3, -4, 5];
            cH = [5, 4, 3, 6];

            [~, tau, ~, ~] = ...
                ContrastPolarityFilter.apply( ...
                    cV, cH, 1, zeros(1,1), 0.5, 0.5, 0.5);

            testCase.verifyEqual(tau(end), 3.5);

        end

        function floorClampedToZero(testCase)

            cV = [-1, -2, -3];
            cH = [1, 2, 3];

            [Hrel, tau, c, s] = ...
                ContrastPolarityFilter.apply( ...
                    cV, cH, 1, zeros(1,1), 0.5, 0.5, 0.5);

            testCase.verifyEqual(tau(end), 0);
            testCase.verifyEmpty(Hrel);
            testCase.verifyEqual(c, [0, 0, 0]);
            testCase.verifyEqual(s, [1, 2, 3]);

        end

        function risingFloorUsesRiseRate(testCase)

            cV = [4, 5, 6];
            cH = [4, 5, 6];

            [~, tau, ~, ~] = ...
                ContrastPolarityFilter.apply( ...
                    cV, cH, 2, 2, 0.5, 0.25, 0.75);

            testCase.verifyEqual(tau(end), 2.75);

        end

        function fallingFloorUsesFallRate(testCase)

            cV = [1, 2, 3];
            cH = [1, 2, 3];

            [~, tau, ~, ~] = ...
                ContrastPolarityFilter.apply( ...
                    cV, cH, 2, 5, 0.5, 0.25, 0.5);

            testCase.verifyEqual(tau(end), 3.5);

        end

        function disagreementIsRejected(testCase)

            cV = [1, -2, 3];
            cH = [1, 2, -3];

            [Hrel, tau, c, ~] = ...
                ContrastPolarityFilter.apply( ...
                    cV, cH, 1, zeros(1,1), 0.0, 1.0, 1.0);

            testCase.verifyEqual(tau(end), 0);
            testCase.verifyEqual(Hrel, 1);
            testCase.verifyEqual(c, [1, 0, 0]);

        end

        function mismatchedSizesFail(testCase)

            testCase.verifyError( ...
                @() ContrastPolarityFilter.apply( ...
                    [1, 2, 3], [1, 2], ...
                    1, zeros(1,1), 0.5, 0.5, 0.5), ...
                "sfrfs:ContrastPolarityFilter:SizeMismatch");

        end

        function nonFiniteInputsFail(testCase)

            testCase.verifyError( ...
                @() ContrastPolarityFilter.apply( ...
                    [1, NaN, 3], [1, 2, 3], ...
                    1, zeros(1,1), 0.5, 0.5, 0.5), ...
                "sfrfs:ContrastPolarityFilter:InvalidContrast");

        end

        function invalidFloorFails(testCase)

            testCase.verifyError( ...
                @() ContrastPolarityFilter.apply( ...
                    [1, 2, 3], [1, 2, 3], ...
                    2, [], 0.5, 0.5, 0.5), ...
                "sfrfs:ContrastPolarityFilter:InvalidFloor");

        end

    end

end