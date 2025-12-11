classdef TestSFRFsParameters < matlab.unittest.TestCase
    % Unit tests for SFRFsParameters.createSFRFsParameters static method.

    methods (Test)
        function testDefaultParameters(testCase)
            params = SFRFsParameters.createSFRFsParameters();

            testCase.verifyEqual(params.order, 0);
            testCase.verifyEqual(params.numSidebands, 2);
            testCase.verifyEqual(params.numHarmonics, 10);
            testCase.verifyEqual(params.sigmaCenter, [4, 6]);
            testCase.verifyEqual(params.sigmaSurround, [12, 1]);
            testCase.verifyEqual(params.inhibitionFactor, 0.8);
        end

        function testCustomParameters(testCase)
            params = SFRFsParameters.createSFRFsParameters( ...
                'order', 3, ...
                'numSidebands', 5, ...
                'numHarmonics', 7, ...
                'sigmaCenter', [5, 7], ...
                'sigmaSurround', [10, 2], ...
                'inhibitionFactor', 0.6);

            testCase.verifyEqual(params.order, 3);
            testCase.verifyEqual(params.numSidebands, 5);
            testCase.verifyEqual(params.numHarmonics, 7);
            testCase.verifyEqual(params.sigmaCenter, [5, 7]);
            testCase.verifyEqual(params.sigmaSurround, [10, 2]);
            testCase.verifyEqual(params.inhibitionFactor, 0.6);
        end

        function testValidationErrors(testCase)
            % Negative order
            f = @()SFRFsParameters.createSFRFsParameters('order', -1);
            testCase.verifyError(f, 'MATLAB:validators:mustBeNonnegative');

            % Non-integer order
            f = @()SFRFsParameters.createSFRFsParameters('order', 2.5);
            testCase.verifyError(f, 'MATLAB:validators:mustBeInteger');

            % Negative numSidebands
            f = @()SFRFsParameters.createSFRFsParameters(...
                'numSidebands', -1);
            testCase.verifyError(f, 'MATLAB:validators:mustBeNonnegative');

            % Non-integer numSidebands
            f = @()SFRFsParameters.createSFRFsParameters(...
                'numSidebands', 1.5);
            testCase.verifyError(f, 'MATLAB:validators:mustBeInteger');

            % Zero numHarmonics
            f = @()SFRFsParameters.createSFRFsParameters(...
                'numHarmonics', 0);
            testCase.verifyError(f, 'MATLAB:validators:mustBePositive');

            % Non-integer numHarmonics
            f = @()SFRFsParameters.createSFRFsParameters(...
                'numHarmonics', 2.2);
            testCase.verifyError(f, 'MATLAB:validators:mustBeInteger');

            % Invalid sigmaCenter
            f = @()SFRFsParameters.createSFRFsParameters(...
                'sigmaCenter', [-1 2]);
            testCase.verifyError(f, 'MATLAB:validators:mustBePositive');

            f = @()SFRFsParameters.createSFRFsParameters(...
                'sigmaCenter', [1 2 3]);
            testCase.verifyError(f, 'MATLAB:validation:IncompatibleSize');

            % Invalid sigmaSurround
            f = @()SFRFsParameters.createSFRFsParameters(...
                'sigmaSurround', [0 1]);
            testCase.verifyError(f, 'MATLAB:validators:mustBePositive');

            f = @()SFRFsParameters.createSFRFsParameters(...
                'sigmaSurround', [1 2 3]);
            testCase.verifyError(f, 'MATLAB:validation:IncompatibleSize');

            % Inhibition factor out of bounds
            f = @()SFRFsParameters.createSFRFsParameters(...
                'inhibitionFactor', -0.1);
            testCase.verifyError(...
                f, 'MATLAB:validators:mustBeGreaterThanOrEqual');

            f = @()SFRFsParameters.createSFRFsParameters(...
                'inhibitionFactor', 1.1);
            testCase.verifyError(...
                f, 'MATLAB:validators:mustBeLessThanOrEqual');
        end
    end
end
