classdef TestContrastMappings < matlab.unittest.TestCase
% TestContrastMappings
%
% Validates factory construction, scalar evaluation, parameter overrides,
% and input validation for ContrastMappings.

    methods(Test)

        function testFactoriesReturnFunctionHandles(testCase)
            k = 1;

            maps = { ...
                ContrastMappings.difference(k = k), ...
                ContrastMappings.ratio(k = k, eps = 1e-12), ...
                ContrastMappings.logRatio(k = k, eps = 1e-12), ...
                ContrastMappings.normalizedDifference(k = k, eps = 1e-12)};

            for i = 1:numel(maps)
                testCase.verifyClass(maps{i}, "function_handle");
            end
        end

        function testDifferenceScalarEvaluation(testCase)
            map = ContrastMappings.difference(k = 2);

            Rc = 1.2;
            Rs = 0.7;

            act = map(Rc, Rs);
            exp = Rc - 2 * Rs;

            testCase.verifyEqual(act, exp);
        end

        function testRatioScalarEvaluation(testCase)
            map = ContrastMappings.ratio(k = 2, eps = 1e-12);

            Rc = 1.2;
            Rs = 0.7;

            act = map(Rc, Rs);
            exp = Rc / (2 * Rs + 1e-12);

            testCase.verifyEqual(act, exp, "AbsTol", 1e-12);
        end

        function testLogRatioScalarEvaluation(testCase)
            map = ContrastMappings.logRatio(k = 2, eps = 1e-12);

            Rc = 1.2;
            Rs = 0.7;

            act = map(Rc, Rs);
            exp = log((Rc + 1e-12) / (2 * Rs + 1e-12));

            testCase.verifyEqual(act, exp, "AbsTol", 1e-12);
        end

        function testNormalizedDifferenceScalarEvaluation(testCase)
            map = ContrastMappings.normalizedDifference(k = 2, eps = 1e-12);

            Rc = 1.2;
            Rs = 0.7;

            act = map(Rc, Rs);
            exp = (Rc - 2 * Rs) / (Rc + 2 * Rs + 1e-12);

            testCase.verifyEqual(act, exp, "AbsTol", 1e-12);
        end

        function testOverrideParamsAtEvaluationTime(testCase)
            map = ContrastMappings.ratio(k = 1, eps = 1e-12);

            Rc = 1.2;
            Rs = 0.7;

            params = struct("k", 2, "eps", 1e-9);

            act = map(Rc, Rs, params);
            exp = Rc / (2 * Rs + 1e-9);

            testCase.verifyEqual(act, exp, "AbsTol", 1e-12);
        end

        function testInvalidParamsThrows(testCase)
            map = ContrastMappings.difference(k = 1);

            Rc = 1.2;
            Rs = 0.7;

            testCase.verifyError(@() map(Rc, Rs, 123), ...
                "sfrfs:ContrastMappings:InvalidParams");
        end

        function testInvalidEpsThrows(testCase)
            map = ContrastMappings.ratio(k = 1, eps = 1e-12);

            Rc = 1.2;
            Rs = 0.7;

            params = struct("eps", -1);

            testCase.verifyError(@() map(Rc, Rs, params), ...
                "sfrfs:ContrastMappings:InvalidEps");
        end

    end
end
