classdef TestFrequencyMask < matlab.unittest.TestCase
    methods (Test)
        function testGaussianBasicFunctionality(testCase)
            fs = 25.6e3;
            N = 32768;
            f = (0:N-1)*(fs/N);
            f = f(:);
            band = [45, 55];
            G = FrequencyMask.gaussian(f, band, 1);
            testCase.verifyTrue(...
                isvector(G), 'Output is not a vector.');
            testCase.verifyEqual(...
                length(G), length(f), 'Output size mismatch.');
            [~, idx] = max(G);
            centerFreq = mean(band);
            % bounded limited resolution error
            testCase.verifyLessThan(abs(f(idx) - centerFreq), fs/N + 1e-8);
        end
        
        function testGaussianNormalization(testCase)
            fs = 25.6e3;
            N = 32768;
            f = (0:N-1)*(fs/N);
            f = f(:);
            band = [45, 55];
            Gnorm = FrequencyMask.gaussian(f, band, 1, true);
            df = mean(diff(f));
            area = sum(Gnorm) * df;
            testCase.verifyLessThan(...
                abs(area - 1), 1e-6, 'Normalized area is not 1.');
        end
        
        function testGaussianDefaultArguments(testCase)
            fs = 25.6e3;
            N = 32768;
            f = (0:N-1)*(fs/N);
            f = f(:);
            band = [45, 55];
            % Call with only required arguments (defaults used)
            Gdefault = FrequencyMask.gaussian(f, band);
            % Call with all arguments explicitly set to their defaults
            sigmaRuleDefault = 3;
            normalizeDefault = false;
            Gexplicit = FrequencyMask.gaussian(...
                f, band, sigmaRuleDefault, normalizeDefault);
            % Results must be identical
            testCase.verifyEqual(...
                Gdefault, ...
                Gexplicit, 'Default and explicit calls should match.');
        end
        
        function testGaussianSigmaRuleEffect(testCase)
            fs = 25.6e3;
            N = 32768;
            f = (0:N-1)*(fs/N);
            f = f(:);
            band = [45, 55];
            Gwide = FrequencyMask.gaussian(f, band, 1);
            Gnarrow = FrequencyMask.gaussian(f, band, 10);
            stdWide = std(Gwide);
            stdNarrow = std(Gnarrow);
            testCase.verifyGreaterThan(stdWide, stdNarrow);
        end
        
        function testGaussianSingleFrequencyInput(testCase)
            Gsingle = FrequencyMask.gaussian(50, [45, 55]);
            testCase.verifyTrue(...
                isscalar(Gsingle), ...
                'Single frequency input should return scalar.');
        end
        
        function testInvalidGaussianInputs(testCase)
            f = (0:10)';
            band = [-5, 5];
            testCase.verifyError(@() ...
                FrequencyMask.gaussian(f, band), ...
                'MATLAB:validators:mustBeNonnegative');
            band = [5, 10];
            testCase.verifyError(@() ...
                FrequencyMask.gaussian(f, band, -1), ...
                'MATLAB:validators:mustBePositive');
        end
        
        function testSuperGaussBasicFunctionality(testCase)
            fs = 25.6e3;
            N = 32768;
            f = (0:N-1)*(fs/N);
            f = f(:);
            band = [45, 55];
            beta = 4;  % shape parameter
            tol = 1.e-8;
            G = FrequencyMask.superGauss(f, band, beta);
            testCase.verifyTrue(...
                isvector(G), 'superGauss output is not a vector.');
            testCase.verifyEqual(...
                length(G), length(f), 'superGauss output size mismatch.');
            [~, idx] = max(G);
            centerFreq = mean(band);
            testCase.verifyLessThan(abs(f(idx) - centerFreq), fs/N + tol);
        end
        
        function testSuperGaussShapeEffect(testCase)
            fs = 25.6e3;
            N = 32768;
            f = (0:N-1)*(fs/N);
            f = f(:);
            band = [45, 55];
            betaLow = 2;  % Gaussian shape
            betaHigh = 8; % flatter (square-like)
            Glow = FrequencyMask.superGauss(f, band, betaLow);
            Ghigh = FrequencyMask.superGauss(f, band, betaHigh);
            % Higher beta produces flatter peak and wider tails; std increases
            testCase.verifyLessThan(std(Glow), std(Ghigh));
        end
        
        function testSuperGaussScalarInput(testCase)
            Gsingle = FrequencyMask.superGauss(50, [45, 55], 4);
            testCase.verifyTrue(...
                isscalar(Gsingle), ...
                'Single frequency input should return scalar.');
        end
        
        function testSuperGaussInvalidInputs(testCase)
            f = (0:10)';
            bandNeg = [-1, 5];
            testCase.verifyError(@() ...
                FrequencyMask.superGauss(f, bandNeg, 4), ...
                'MATLAB:validators:mustBeNonnegative');
            testCase.verifyError(@() ...
                FrequencyMask.superGauss(f, [0 10], -2), ...
                'MATLAB:validators:mustBePositive');
            testCase.verifyError(@() ...
                FrequencyMask.superGauss(f, [0 10], 0), ...
                'MATLAB:validators:mustBePositive');
        end
        
        function testSuperGaussAtBeta2EqualsGaussian(testCase)
            fs = 25.6e3;
            N = 32768;
            f = (0:N-1)*(fs/N);
            f = f(:);
            band = [45, 55];
            tol = 1.e-6;
        
            % Parameters matching the gaussian sigmaF calculation
            sigmaRule = sqrt(2)/2;
        
            % Gaussian mask
            G_gauss = FrequencyMask.gaussian(f, band, sigmaRule, false);
        
            % SuperGaussian mask with beta = 2 and alpha = sqrt(2)*sigmaF
            beta = 2;
            G_super = FrequencyMask.superGauss(f, band, beta);
        
            % Verify masks are almost identical
            testCase.verifyEqual(G_super, G_gauss, 'AbsTol', ...
                tol, 'SuperGauss with beta=2 differs from Gaussian.');
        end

    end
end
