classdef TestFrequencyMask < matlab.unittest.TestCase
    % TestFrequencyMask
    % Unit tests for FrequencyMask (Gaussian + SuperGaussian).

    methods (Test)
        function testGaussianBasicFunctionality(testCase)
            fs = 25.6e3;
            N = 32768;
            f = (0:N-1) * (fs / N);
            f = f(:);

            band = [45, 55];
            G = FrequencyMask.gaussian(f, band, 1);

            testCase.verifyTrue(isvector(G), "Output is not a vector.");
            testCase.verifyEqual(length(G), length(f), ...
                "Output size mismatch.");

            [~, idx] = max(G);
            centerFreq = mean(band);

            % Bounded limited resolution error.
            testCase.verifyLessThan(...
                abs(f(idx) - centerFreq), fs / N + 1e-8);
        end

        function testGaussianNormalization(testCase)
            fs = 25.6e3;
            N = 32768;
            f = (0:N-1) * (fs / N);
            f = f(:);

            band = [45, 55];
            Gnorm = FrequencyMask.gaussian(f, band, 1, true);

            df = mean(diff(f));
            area = sum(Gnorm) * df;

            testCase.verifyLessThan(abs(area - 1), 1e-6, ...
                "Normalized area is not 1.");
        end

        function testGaussianDefaultArguments(testCase)
            fs = 25.6e3;
            N = 32768;
            f = (0:N-1) * (fs / N);
            f = f(:);

            band = [45, 55];

            % Call with only required arguments (defaults used).
            Gdefault = FrequencyMask.gaussian(f, band);

            % Call with all arguments explicitly set to their defaults.
            sigmaRuleDefault = 3;
            normalizeDefault = false;
            Gexplicit = FrequencyMask.gaussian( ...
                f, band, sigmaRuleDefault, normalizeDefault);

            testCase.verifyEqual(Gdefault, Gexplicit, ...
                "Default and explicit calls should match.");
        end

        function testGaussianSigmaRuleEffect(testCase)
            fs = 25.6e3;
            N = 32768;
            f = (0:N-1) * (fs / N);
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
            testCase.verifyTrue(isscalar(Gsingle), ...
                "Single frequency input should return scalar.");
        end

        function testInvalidGaussianInputs(testCase)
            f = (0:10)';

            band = [-5, 5];
            testCase.verifyError(@() ...
                FrequencyMask.gaussian(f, band), ...
                "MATLAB:validators:mustBeNonnegative");

            band = [5, 10];
            testCase.verifyError(@() ...
                FrequencyMask.gaussian(f, band, -1), ...
                "MATLAB:validators:mustBePositive");
        end

        function testSuperGaussBasicFunctionality(testCase)
            fs = 25.6e3;
            N = 32768;
            f = (0:N-1) * (fs / N);
            f = f(:);

            band = [45, 55];
            alpha = (band(2) - band(1)) / 2;
            beta = 4;
            tol = 1e-8;

            G = FrequencyMask.superGauss(f, band, alpha, beta);

            testCase.verifyTrue(isvector(G), ...
                "superGauss output is not a vector.");
            testCase.verifyEqual(length(G), length(f), ...
                "superGauss output size mismatch.");

            [~, idx] = max(G);
            centerFreq = mean(band);
            testCase.verifyLessThan(...
                abs(f(idx) - centerFreq), fs / N + tol);
        end

        function testSuperGaussShapeEffect(testCase)
            fs = 25.6e3;
            N = 32768;
            f = (0:N-1) * (fs / N);
            f = f(:);

            band = [45, 55];
            alpha = (band(2) - band(1)) / 2;

            betaLow = 2;
            betaHigh = 8;

            Glow = FrequencyMask.superGauss(f, band, alpha, betaLow);
            Ghigh = FrequencyMask.superGauss(f, band, alpha, betaHigh);

            % Higher beta changes the profile; keep the original heuristic.
            testCase.verifyLessThan(std(Glow), std(Ghigh));
        end

        function testSuperGaussScalarInput(testCase)
            band = [45, 55];
            alpha = (band(2) - band(1)) / 2;
            beta = 4;

            Gsingle = FrequencyMask.superGauss(50, band, alpha, beta);

            testCase.verifyTrue(isscalar(Gsingle), ...
                "Single frequency input should return scalar.");
        end

        function testSuperGaussInvalidInputs(testCase)
            f = (0:10)';

            bandNeg = [-1, 5];
            testCase.verifyError(@() ...
                FrequencyMask.superGauss(f, bandNeg, 1, 4), ...
                "MATLAB:validators:mustBeNonnegative");

            testCase.verifyError(@() ...
                FrequencyMask.superGauss(f, [0 10], -1, 4), ...
                "MATLAB:validators:mustBePositive");

            testCase.verifyError(@() ...
                FrequencyMask.superGauss(f, [0 10], 0, 4), ...
                "MATLAB:validators:mustBePositive");

            testCase.verifyError(@() ...
                FrequencyMask.superGauss(f, [0 10], 5, -2), ...
                "MATLAB:validators:mustBePositive");

            testCase.verifyError(@() ...
                FrequencyMask.superGauss(f, [0 10], 5, 0), ...
                "MATLAB:validators:mustBePositive");
        end

        function testSuperGaussAlphaMismatchRaisesError(testCase)
            fs = 25.6e3;
            N = 32768;
            f = (0:N-1) * (fs / N);
            f = f(:);

            band = [45, 55];
            beta = 4;

            expectedAlpha = (band(2) - band(1)) / 2;
            wrongAlpha = expectedAlpha * 1.1;

            testCase.verifyError(@() ...
                FrequencyMask.superGauss(f, band, wrongAlpha, beta), ...
                "sfrfs:FrequencyMask:superGauss:AlphaMismatch");
        end

        function testSuperGaussAtBeta2EqualsGaussian(testCase)
            fs = 25.6e3;
            N = 32768;
            f = (0:N-1) * (fs / N);
            f = f(:);

            band = [45, 55];
            tol = 1e-6;

            % With alpha = half-bandwidth and beta = 2, the matching
            % Gaussian uses sigmaRule = sqrt(2).
            sigmaRule = sqrt(2);
            G_gauss = FrequencyMask.gaussian(f, band, sigmaRule, false);

            alpha = (band(2) - band(1)) / 2;
            beta = 2;
            G_super = FrequencyMask.superGauss(f, band, alpha, beta);

            testCase.verifyEqual(G_super, G_gauss, "AbsTol", tol, ...
                "SuperGauss(beta=2) differs from Gaussian.");
        end

        function testEvaluateGaussianUsesParams(testCase)
            fs = 25.6e3;
            N = 32768;
            f = (0:N-1) * (fs / N);
            f = f(:);

            band = [45, 55];

            p = GaussianMaskParameters( ...
                bandwidth = 4, ...
                sigmaRule = 5, ...
                normalize = true);

            G_eval = FrequencyMask.evaluate(f, band, p);
            G_ref  = FrequencyMask.gaussian(f, band, p.sigmaRule, ...
                p.normalize);

            testCase.verifyEqual(G_eval, G_ref, ...
                "evaluate for GaussianMaskParameters inconsistent.");
        end

        function testEvaluateSuperGaussianUsesParams(testCase)
            fs = 25.6e3;
            N = 32768;
            f = (0:N-1) * (fs / N);
            f = f(:);

            band = [45, 55];
            alpha = (band(2) - band(1)) / 2;

            p = SuperGaussianMaskParameters( ...
                alpha = alpha, ...
                beta  = 4);

            G_eval = FrequencyMask.evaluate(f, band, p);
            G_ref  = FrequencyMask.superGauss(f, band, p.alpha, p.beta);

            testCase.verifyEqual(G_eval, G_ref, ...
                "evaluate for SuperGaussianMaskParameters inconsistent.");
        end
    end
end
