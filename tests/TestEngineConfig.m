classdef TestEngineConfig < matlab.unittest.TestCase
% TestEngineConfig
%
% Unit tests for:
%   epistemic.tools.evolutionary.EngineConfig

    properties (Constant, Access = private)
        Leaf = "ConfigValidator"
    end

    methods (Test)

        function Constructor_Defaults_Passes(testCase)

            testCase.verifyWarningFree(@() ...
                epistemic.tools.evolutionary.EngineConfig());

        end

        function Constructor_Defaults_AssignsExpectedValues(testCase)

            cfg = epistemic.tools.evolutionary.EngineConfig();

            testCase.verifyEqual( ...
                cfg.getConfig(cfg.POPULATION_SIZE), 100);

            testCase.verifyEqual( ...
                cfg.getConfig(cfg.MAX_GENERATIONS), 100);

            testCase.verifyEqual( ...
                cfg.getConfig(cfg.MUTATION_RATE), 0.01);

            testCase.verifyEqual( ...
                cfg.getConfig(cfg.POWER_LAW_ALPHA), 1.5);

            testCase.verifyEqual( ...
                cfg.getConfig(cfg.POWER_LAW_RMIN), 1.0e-10);

        end

        function Constructor_Overrides_AssignExpectedValues(testCase)

            cfg = epistemic.tools.evolutionary.EngineConfig( ...
                populationSize = 80, ...
                maxGenerations = 50, ...
                mutationRate = 0.05, ...
                powerLawAlpha = 0.7, ...
                powerLawRMin = 1.0e-3);

            testCase.verifyEqual( ...
                cfg.getConfig(cfg.POPULATION_SIZE), 80);

            testCase.verifyEqual( ...
                cfg.getConfig(cfg.MAX_GENERATIONS), 50);

            testCase.verifyEqual( ...
                cfg.getConfig(cfg.MUTATION_RATE), 0.05);

            testCase.verifyEqual( ...
                cfg.getConfig(cfg.POWER_LAW_ALPHA), 0.7);

            testCase.verifyEqual( ...
                cfg.getConfig(cfg.POWER_LAW_RMIN), 1.0e-3);

        end

        function GetConfig_ReturnsTypedNumericValues(testCase)

            cfg = epistemic.tools.evolutionary.EngineConfig( ...
                mutationRate = 0.05, ...
                powerLawAlpha = 0.7, ...
                powerLawRMin = 1.0e-3);

            value1 = cfg.getConfig(cfg.MUTATION_RATE);
            value2 = cfg.getConfig(cfg.POWER_LAW_ALPHA);
            value3 = cfg.getConfig(cfg.POWER_LAW_RMIN);

            testCase.verifyClass(value1, "double");
            testCase.verifyEqual(value1, 0.05);

            testCase.verifyClass(value2, "double");
            testCase.verifyEqual(value2, 0.7);

            testCase.verifyClass(value3, "double");
            testCase.verifyEqual(value3, 1.0e-3);

        end

        function ToString_ReturnsDeterministicSingleRow(testCase)
        % Keep this because single-row deterministic rendering is part of
        % the class contract for logging.

            cfg = epistemic.tools.evolutionary.EngineConfig();

            actual = cfg.toString();

            expected = ...
                "EngineConfig[" + ...
                "populationSize=100," + ...
                "maxGenerations=100," + ...
                "mutationRate=0.01," + ...
                "powerLawAlpha=1.5," + ...
                "powerLawRMin=1e-10]";

            testCase.verifyEqual(actual, expected);

        end

        function Constructor_ThrowsForBadPopulationSize(testCase)

            testCase.verifyError(@() ...
                epistemic.tools.evolutionary.EngineConfig( ...
                populationSize = 0), ...
                testCase.id_("BadPopulationSize"));

        end

        function Constructor_ThrowsForBadMaxGenerations(testCase)

            testCase.verifyError(@() ...
                epistemic.tools.evolutionary.EngineConfig( ...
                maxGenerations = 0), ...
                testCase.id_("BadMaxGenerations"));

        end

        function Constructor_ThrowsForBadMutationRateShape(testCase)

            testCase.verifyError(@() ...
                epistemic.tools.evolutionary.EngineConfig( ...
                mutationRate = [0.01 0.02]), ...
                "MATLAB:validation:IncompatibleSize");

        end

        function Constructor_ThrowsForBadMutationRateRange(testCase)

            testCase.verifyError(@() ...
                epistemic.tools.evolutionary.EngineConfig( ...
                mutationRate = -0.01), ...
                testCase.id_("MutationRateOutOfRange"));

        end

        function Constructor_ThrowsForBadPowerLawAlphaShape(testCase)

            testCase.verifyError(@() ...
                epistemic.tools.evolutionary.EngineConfig( ...
                powerLawAlpha = [0.7 1.5]), ...
                "MATLAB:validation:IncompatibleSize");

        end

        function Constructor_ThrowsForBadPowerLawAlpha(testCase)

            testCase.verifyError(@() ...
                epistemic.tools.evolutionary.EngineConfig( ...
                powerLawAlpha = 0), ...
                testCase.id_("BadPowerLawAlpha"));

        end

        function Constructor_ThrowsForBadPowerLawRMinShape(testCase)

            testCase.verifyError(@() ...
                epistemic.tools.evolutionary.EngineConfig( ...
                powerLawRMin = [1.0e-3 1.0e-4]), ...
                "MATLAB:validation:IncompatibleSize");

        end

        function Constructor_ThrowsForBadPowerLawRMin(testCase)

            testCase.verifyError(@() ...
                epistemic.tools.evolutionary.EngineConfig( ...
                powerLawRMin = 0), ...
                testCase.id_("BadPowerLawRMin"));

        end

    end

    methods (Access = private)

        function id = id_(testCase, suffix)
            id = "sfrfs:" + testCase.Leaf + ":" + string(suffix);
            id = char(id);
        end

    end

end