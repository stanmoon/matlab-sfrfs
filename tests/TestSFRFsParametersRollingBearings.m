classdef TestSFRFsParametersRollingBearings < matlab.unittest.TestCase
    % Test suite for the SFRFsParametersRollingBearings class.
    %
    % Covers:
    %   - Construction in Mode 1 (all faults specified)
    %   - Construction in Mode 2 (SameForAllFaultTypes specified)
    %   - Validation errors for missing required fields
    %   - Validation errors for mode conflict

    properties
        completeParams
        paramsNoSidebands
        partialParams
    end

    methods (TestMethodSetup)
        function prepareParameters(testCase)
            % Fully specified valid SFRFs parameters
            testCase.completeParams = ...
                SFRFsParameters.createSFRFsParameters(...
                'order', 3, ...
                'numSidebands', 4, ...
                'numHarmonics', 8, ...
                'sigmaCenter', [5, 7], ...
                'sigmaSurround', [12, 3], ...
                'inhibitionFactor', 0.6);
            testCase.paramsNoSidebands = ...
                SFRFsParameters.createSFRFsParameters( ...
                'order', 3, ...
                'numSidebands', 0, ...
                'numHarmonics', 8, ...
                'sigmaCenter', [5, 7], ...
                'sigmaSurround', [12, 3], ...
                'inhibitionFactor', 0.6);

            % Partially specified (missing required fields) for error tests
            testCase.partialParams = struct('order', 1);
        end
    end

    methods (Test)
        function testMode1ValidConstruction(testCase)
            % All four faults specified with valid structs
            obj = SFRFsParametersRollingBearings( ...
                'outerRace', testCase.paramsNoSidebands, ...
                'innerRace', testCase.completeParams, ...
                'ball',      testCase.completeParams, ...
                'cage',      testCase.paramsNoSidebands);

            % Verify all properties were assigned correctly
            testCase.verifyEqual(...
                obj.outerRace, testCase.paramsNoSidebands);
            testCase.verifyEqual(obj.innerRace, testCase.completeParams);
            testCase.verifyEqual(obj.ball, testCase.completeParams);
            testCase.verifyEqual(obj.cage, testCase.paramsNoSidebands);
        end

        function testMode2ValidConstruction(testCase)
            % Only SameForAllFaultTypes specified
            obj = SFRFsParametersRollingBearings( ...
                'SameForAllFaultTypes', testCase.completeParams);

            % All four should match the shared struct, but for sidebands
            testCase.verifyEqual(...
                obj.outerRace, testCase.paramsNoSidebands);
            testCase.verifyEqual(obj.innerRace, testCase.completeParams);
            testCase.verifyEqual(obj.ball, testCase.completeParams);
            testCase.verifyEqual(obj.cage, testCase.paramsNoSidebands);
        end

        function testMissingFieldsError(testCase)
            % Missing required fields in one fault type should error
            testCase.verifyError(@() ...
                SFRFsParametersRollingBearings( ...
                    'outerRace', testCase.partialParams, ...
                    'innerRace', testCase.completeParams, ...
                    'ball',      testCase.completeParams, ...
                    'cage',      testCase.completeParams), ...
                ['sfrfs:SFRFsParametersRollingBearings:validateInputs:' ...
                'MissingSFRFsParameters']);
        end

        function testMutualExclusivityError(testCase)
            % Providing both SameForAllFaultTypes and others should error
            testCase.verifyError(@() ...
                SFRFsParametersRollingBearings( ...
                    'SameForAllFaultTypes', testCase.completeParams, ...
                    'outerRace', testCase.completeParams), ...
                ['sfrfs:SFRFsParametersRollingBearings:validateInputs:'...
                'ConflictingArguments']);
        end

        function testMissingFaultTypeError(testCase)
            % innerRace missing entirely, cage empty
            complete = testCase.completeParams; % from TestMethodSetup

            testCase.verifyError(@() ...
                SFRFsParametersRollingBearings( ...
                'outerRace', complete, ...
                'ball',      complete, ...
                'cage',      struct() ), ...
                ['sfrfs:SFRFsParametersRollingBearings:validateInputs:'...
                'MissingArguments']);
        end

        function testOrderValidation(testCase)
            % Negative order should error
            f = @()SFRFsParameters.createSFRFsParameters(...
                'order', -1);
            testCase.verifyError(f, 'MATLAB:validators:mustBeNonnegative');
    
            % Non-integer order should error
            f = @()SFRFsParameters.createSFRFsParameters(...
                'order', 2.5);
            testCase.verifyError(f, 'MATLAB:validators:mustBeInteger');
        end
    
        function testNumSidebandsValidation(testCase)
            % Negative numSidebands should error
            f = @()SFRFsParameters.createSFRFsParameters(...
                'numSidebands', -1);
            testCase.verifyError(f, 'MATLAB:validators:mustBeNonnegative');
    
            % Non-integer numSidebands should error
            f = @()SFRFsParameters.createSFRFsParameters(...
                'numSidebands', 1.5);
            testCase.verifyError(f, 'MATLAB:validators:mustBeInteger');
        end
    
        function testNumHarmonicsValidation(testCase)
            % Zero or less numHarmonics should error
            f = @()SFRFsParameters.createSFRFsParameters(...
                'numHarmonics', 0);
            testCase.verifyError(f, 'MATLAB:validators:mustBePositive');
    
            % Non-integer numHarmonics should error
            f = @()SFRFsParameters.createSFRFsParameters(...
                'numHarmonics', 2.2);
            testCase.verifyError(f, 'MATLAB:validators:mustBeInteger');
        end
    
        function testSigmaCenterValidation(testCase)
            % Negative element in sigmaCenter should error
            f = @()SFRFsParameters.createSFRFsParameters(...
                'sigmaCenter', [-1 6]);
            testCase.verifyError(f, 'MATLAB:validators:mustBePositive');
    
            % Wrong size for sigmaCenter should error
            f = @()SFRFsParameters.createSFRFsParameters(...
                'sigmaCenter', [4 6 8]);
            testCase.verifyError(f, 'MATLAB:validation:IncompatibleSize');
        end
    
        function testSigmaSurroundValidation(testCase)
            % Zero or negative element in sigmaSurround should error
            f = @()SFRFsParameters.createSFRFsParameters(...
                'sigmaSurround', [0 1]);
            testCase.verifyError(f, 'MATLAB:validators:mustBePositive');
    
            % Wrong size for sigmaSurround should error
            f = @()SFRFsParameters.createSFRFsParameters(...
                'sigmaSurround', [12 1 2]);
            testCase.verifyError(f, 'MATLAB:validation:IncompatibleSize');
        end
    
        function testInhibitionFactorValidation(testCase)
            % Inhibition factor below zero should error
            f = @()SFRFsParameters.createSFRFsParameters(...
                'inhibitionFactor', -0.1);
            testCase.verifyError(f, ...
                'MATLAB:validators:mustBeGreaterThanOrEqual');
    
            % Inhibition factor above one should error
            f = @()SFRFsParameters.createSFRFsParameters(...
                'inhibitionFactor', 1.1);
            testCase.verifyError(f, ...
                'MATLAB:validators:mustBeLessThanOrEqual');
        end
    end
end
