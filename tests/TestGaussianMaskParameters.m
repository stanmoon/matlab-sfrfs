classdef TestGaussianMaskParameters < matlab.unittest.TestCase
    % Unit tests for GaussianMaskParameters.

    methods (Test)
        function testDefaultParameters(testCase)
            obj = GaussianMaskParameters();

            testCase.verifyEqual(obj.bandwidth, 4);
            testCase.verifyEqual(obj.sigmaRule, 3);
            testCase.verifyEqual(obj.normalize, false);

            testCase.verifyEqual(obj.params.bandwidth, 4);
            testCase.verifyEqual(obj.params.sigmaRule, 3);
            testCase.verifyEqual(obj.params.normalize, false);
        end

        function testCustomParameters(testCase)
            obj = GaussianMaskParameters( ...
                GaussianMaskParameters.BANDWIDTH_PARAM_NAME, 5, ...
                GaussianMaskParameters.SIGMARULE_PARAM_NAME, 7, ...
                GaussianMaskParameters.NORMALIZE_PARAM_NAME, true);

            % direct access
            testCase.verifyEqual(obj.bandwidth, 5);
            testCase.verifyEqual(obj.sigmaRule, 7);
            testCase.verifyEqual(obj.normalize, true);

            % struct access
            testCase.verifyEqual(obj.params.bandwidth, 5);
            testCase.verifyEqual(obj.params.sigmaRule, 7);
            testCase.verifyEqual(obj.params.normalize, true);
        end

        function testGetReferenceBandwidth(testCase)
            obj = GaussianMaskParameters( ...
                GaussianMaskParameters.BANDWIDTH_PARAM_NAME, 9);

            testCase.verifyEqual(obj.getReferenceBandwidth(), obj.bandwidth);
            testCase.verifyEqual(obj.getReferenceBandwidth(), obj.params.bandwidth);
        end

        function testValidationErrors(testCase)
            f = @()GaussianMaskParameters('bandwidth', 0);
            testCase.verifyError(f, 'MATLAB:validators:mustBePositive');

            f = @()GaussianMaskParameters('bandwidth', -1);
            testCase.verifyError(f, 'MATLAB:validators:mustBePositive');

            f = @()GaussianMaskParameters('sigmaRule', 0);
            testCase.verifyError(f, 'MATLAB:validators:mustBePositive');

            f = @()GaussianMaskParameters('sigmaRule', -2);
            testCase.verifyError(f, 'MATLAB:validators:mustBePositive');

            % a numeric value is automatically cast to boolean, we
            % generate an error with a string
            f = @()GaussianMaskParameters('normalize', "true");
            testCase.verifyError(f, 'MATLAB:validation:UnableToConvert');
        end
    end
end
