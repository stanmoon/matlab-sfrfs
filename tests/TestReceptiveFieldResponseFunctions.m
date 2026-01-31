classdef TestReceptiveFieldResponseFunctions < matlab.unittest.TestCase
% TestReceptiveFieldResponseFunctions
%
% Unit tests for ReceptiveFieldResponseFunctions:
% - correctness of core readouts
% - consistency of wrappers
% - validation error identifiers

    methods(Test)

        function testIntegralAbsMatchesTrapz(testCase)
            f = linspace(0, 200, 1024).';
            X = (1:1024).' * (1 + 1i);
            X = [X, 2*X];

            fcn = ReceptiveFieldResponseFunctions.integralAbs();

            act = fcn(X, f);
            exp = trapz(f, abs(X), 1);

            testCase.verifyEqual(act, exp, "AbsTol", 1e-12);
        end

        function testEntropyNormalizedUniformIsOne(testCase)
            nBins = 128;
            f = linspace(0, 200, nBins).';

            % Uniform magnitude => uniform P => entropy = log(nBins)
            X = ones(nBins, 3);

            fcn = ReceptiveFieldResponseFunctions.entropy( ...
                normalize = true, ...
                eps = 1e-12);

            act = fcn(X, f);
            exp = ones(1, size(X, 2));

            testCase.verifyEqual(act, exp, "AbsTol", 1e-6);
        end

        function testEntropyUnnormalizedUniformIsLogNBins(testCase)
            nBins = 64;
            f = linspace(0, 200, nBins).';
            X = ones(nBins, 2);

            fcn = ReceptiveFieldResponseFunctions.entropy( ...
                normalize = false, ...
                eps = 1e-12);

            act = fcn(X, f);
            exp = log(nBins) * ones(1, size(X, 2));

            testCase.verifyEqual(act, exp, "AbsTol", 1e-6);
        end

        function testIntegralAbsFreqScaledOrderZeroEqualsIntegralAbs(...
                testCase)
            f = linspace(0, 200, 256).';
            X = exp(1i * 2*pi*rand(size(f, 1), 4));

            f0 = ReceptiveFieldResponseFunctions.integralAbs();
            f1 = ReceptiveFieldResponseFunctions.integralAbsFreqScaled( ...
                order = 0, ...
                freqFloorHz = 1e-3);

            act = f1(X, f);
            expf = f0(X, f);

            testCase.verifyEqual(act, expf, "AbsTol", 1e-12);
        end

        function testVelocityLikeEqualsOrder1(testCase)
            f = linspace(0, 200, 512).';
            X = (randn(numel(f), 3) + 1i*randn(numel(f), 3));

            fv = ReceptiveFieldResponseFunctions.velocityLike( ...
                freqFloorHz = 1e-3);

            f1 = ReceptiveFieldResponseFunctions.integralAbsFreqScaled( ...
                order = 1, ...
                freqFloorHz = 1e-3);

            testCase.verifyEqual(fv(X, f), f1(X, f), "AbsTol", 1e-12);
        end

        function testDisplacementLikeEqualsOrder2(testCase)
            f = linspace(0, 200, 512).';
            X = (randn(numel(f), 2) + 1i*randn(numel(f), 2));

            fd = ReceptiveFieldResponseFunctions.displacementLike( ...
                freqFloorHz = 1e-3);

            f2 = ReceptiveFieldResponseFunctions.integralAbsFreqScaled( ...
                order = 2, ...
                freqFloorHz = 1e-3);

            testCase.verifyEqual(fd(X, f), f2(X, f), "AbsTol", 1e-12);
        end

        function testValidateXFMismatchThrows(testCase)
            f = linspace(0, 200, 100).';
            X = ones(101, 2);

            fcn = ReceptiveFieldResponseFunctions.integralAbs();

            testCase.verifyError(@() fcn(X, f), ...
                "sfrfs:ReceptiveFieldResponseFunctions:FreqAxisMismatch");
        end

        function testInvalidSpectrumThrows(testCase)
            f = linspace(0, 200, 10).';
            X = [];

            fcn = ReceptiveFieldResponseFunctions.integralAbs();

            testCase.verifyError(@() fcn(X, f), ...
                "sfrfs:ReceptiveFieldResponseFunctions:InvalidSpectrum");
        end

        function testInvalidFreqAxisThrows(testCase)
            f = linspace(0, 200, 10).';
            f(3) = NaN;
            X = ones(10, 1);

            fcn = ReceptiveFieldResponseFunctions.integralAbs();

            testCase.verifyError(@() fcn(X, f), ...
                "sfrfs:ReceptiveFieldResponseFunctions:InvalidFreqAxis");
        end

        function testEntropyEpsMustBePositive(testCase)
            testCase.verifyError(@() ...
                ReceptiveFieldResponseFunctions.entropy(eps = -1), ...
                "MATLAB:validators:mustBePositive");
        end

    end
end
