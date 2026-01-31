classdef TestSFRFsParameters < matlab.unittest.TestCase
    % Unit tests for SFRFsParameters.createSFRFsParameters static method.

    methods (Test)
        function testDefaultParameters(testCase)
            params = SFRFsParameters.buildSFRFsParameters();

            testCase.verifyEqual(params.order, 0);
            testCase.verifyEqual(params.numSidebands, 2);
            testCase.verifyEqual(params.numHarmonics, 10);
            testCase.verifyEqual(params.inhibitionFactor, 0.8);

            testCase.verifyClass(params.centerMask, ...
                'GaussianMaskParameters');
            testCase.verifyClass(params.surroundMask, ...
                'GaussianMaskParameters');

            testCase.verifyEqual(params.centerMask.bandwidth, 4);
            testCase.verifyEqual(params.centerMask.sigmaRule, 3);
            testCase.verifyEqual(params.centerMask.normalize, false);

            testCase.verifyEqual(params.surroundMask.bandwidth, 4);
            testCase.verifyEqual(params.surroundMask.sigmaRule, 3);
            testCase.verifyEqual(params.surroundMask.normalize, false);
        end

        function testCustomParameters(testCase)
            centerMask = GaussianMaskParameters( ...
                'bandwidth', 5, ...
                'sigmaRule', 7, ...
                'normalize', true);

            surroundMask = SuperGaussianMaskParameters( ...
                'alpha', 12, ...
                'beta', 4);

            params = SFRFsParameters.buildSFRFsParameters( ...
                'order', 3, ...
                'numSidebands', 5, ...
                'numHarmonics', 7, ...
                'centerMask', centerMask, ...
                'surroundMask', surroundMask, ...
                'inhibitionFactor', 0.6);

            testCase.verifyEqual(params.order, 3);
            testCase.verifyEqual(params.numSidebands, 5);
            testCase.verifyEqual(params.numHarmonics, 7);
            testCase.verifyEqual(params.inhibitionFactor, 0.6);

            testCase.verifyClass(params.centerMask, ...
                'GaussianMaskParameters');
            testCase.verifyEqual(params.centerMask.bandwidth, 5);
            testCase.verifyEqual(params.centerMask.sigmaRule, 7);
            testCase.verifyEqual(params.centerMask.normalize, true);

            testCase.verifyClass(params.surroundMask, ...
                'SuperGaussianMaskParameters');
            testCase.verifyEqual(params.surroundMask.alpha, 12);
            testCase.verifyEqual(params.surroundMask.beta, 4);
        end

        function testValidationErrors(testCase)
            % Negative order
            f = @()SFRFsParameters.buildSFRFsParameters('order', -1);
            testCase.verifyError(f, 'MATLAB:validators:mustBeNonnegative');

            % Non-integer order
            f = @()SFRFsParameters.buildSFRFsParameters('order', 2.5);
            testCase.verifyError(f, 'MATLAB:validators:mustBeInteger');

            % Negative numSidebands
            f = @()SFRFsParameters.buildSFRFsParameters(...
                'numSidebands', -1);
            testCase.verifyError(f, 'MATLAB:validators:mustBeNonnegative');

            % Non-integer numSidebands
            f = @()SFRFsParameters.buildSFRFsParameters(...
                'numSidebands', 1.5);
            testCase.verifyError(f, 'MATLAB:validators:mustBeInteger');

            % Zero numHarmonics
            f = @()SFRFsParameters.buildSFRFsParameters(...
                'numHarmonics', 0);
            testCase.verifyError(f, 'MATLAB:validators:mustBePositive');

            % Non-integer numHarmonics
            f = @()SFRFsParameters.buildSFRFsParameters(...
                'numHarmonics', 2.2);
            testCase.verifyError(f, 'MATLAB:validators:mustBeInteger');

            % Inhibition factor out of bounds
            f = @()SFRFsParameters.buildSFRFsParameters(...
                'inhibitionFactor', -0.1);
            testCase.verifyError(...
                f, 'MATLAB:validators:mustBeGreaterThanOrEqual');

            f = @()SFRFsParameters.buildSFRFsParameters(...
                'inhibitionFactor', 1.1);
            testCase.verifyError(...
                f, 'MATLAB:validators:mustBeLessThanOrEqual');

            % Invalid mask types
            f = @()SFRFsParameters.buildSFRFsParameters(...
                'centerMask', 123);
            testCase.verifyError(f, 'MATLAB:validation:UnableToConvert');

            f = @()SFRFsParameters.buildSFRFsParameters(...
                'surroundMask', struct());
            testCase.verifyError(f, 'MATLAB:validation:UnableToConvert');
        end
    end
end
