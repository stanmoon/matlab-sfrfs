classdef TestOperatingConditionSelection < matlab.unittest.TestCase
% TestOperatingConditionSelection
%
% Minimal validation tests for OperatingConditionSelection.

    methods(Test)

        function testValidInputs(testCase)
            sel = OperatingConditionSelection(speed = 35, load = 12);

            testCase.verifyEqual(sel.speed, 35);
            testCase.verifyEqual(sel.load, 12);
        end

        function testSpeedMustBePositive(testCase)
            testCase.verifyError( ...
                @() OperatingConditionSelection(speed = -1, load = 12), ...
                "MATLAB:validators:mustBePositive");
        end

        function testSpeedMustBeFinite(testCase)
            testCase.verifyError( ...
                @() OperatingConditionSelection(speed = NaN, load = 12),...
                "MATLAB:validators:mustBeFinite");
        end

        function testLoadMustBeReal(testCase)
            testCase.verifyError( ...
                @() OperatingConditionSelection( ...
                speed = 35, load = 1 + 2i), ...
                "MATLAB:validators:mustBeReal");
        end

        function testLoadMustBeFinite(testCase)
            testCase.verifyError( ...
                @() OperatingConditionSelection(speed = 35, load = Inf),...
                "MATLAB:validators:mustBeFinite");
        end

    end
end
