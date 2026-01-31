classdef TestSuperGaussianMaskParameters < matlab.unittest.TestCase
    % Unit tests for SuperGaussianMaskParameters.

    methods (Test)
        function testDefaultParameters(testCase)
            obj = SuperGaussianMaskParameters();

            testCase.verifyEqual(obj.alpha, 4);
            testCase.verifyEqual(obj.beta, 2);

            testCase.verifyEqual(obj.params.alpha, 4);
            testCase.verifyEqual(obj.params.beta, 2);
        end

        function testCustomParameters(testCase)
            obj = SuperGaussianMaskParameters( ...
                'alpha', 12, ...
                'beta', 4);

            testCase.verifyEqual(obj.alpha, 12);
            testCase.verifyEqual(obj.beta, 4);

            testCase.verifyEqual(obj.params.alpha, 12);
            testCase.verifyEqual(obj.params.beta, 4);
        end

        function testBandwidthProperty(testCase)
            % Bandwidth is the reference bandwidth and equals 2*alpha.
        
            obj = SuperGaussianMaskParameters( ...
                'alpha', 10, ...
                'beta', 3);
        
            bwExpected = 2 * obj.alpha;
        
            % Dependent property
            testCase.verifyEqual(obj.bandwidth, bwExpected);
        
            % Backing dictionary
            testCase.verifyEqual(obj.params.bandwidth, bwExpected);
        
            % Explicit semantic check
            testCase.verifyEqual(obj.bandwidth, 2 * obj.alpha);
        end



        function testValidationErrors(testCase)
            f = @()SuperGaussianMaskParameters('alpha', 0);
            testCase.verifyError(f, 'MATLAB:validators:mustBePositive');

            f = @()SuperGaussianMaskParameters('alpha', -1);
            testCase.verifyError(f, 'MATLAB:validators:mustBePositive');

            f = @()SuperGaussianMaskParameters('beta', 0);
            testCase.verifyError(f, 'MATLAB:validators:mustBePositive');

            f = @()SuperGaussianMaskParameters('beta', -2);
            testCase.verifyError(f, 'MATLAB:validators:mustBePositive');
        end
    end
end
