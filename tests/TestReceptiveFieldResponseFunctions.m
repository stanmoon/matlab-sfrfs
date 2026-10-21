classdef TestReceptiveFieldResponseFunctions < matlab.unittest.TestCase
%TestReceptiveFieldResponseFunctions
%
% Unit tests for ReceptiveFieldResponseFunctions:
% - correctness of core readouts
% - consistency of wrappers
% - masking semantics
% - validation error identifiers

    methods(Test)

        function testMaskedMeanAbsUsesMaskOnlyForNormalization( ...
                testCase)

            f = linspace(0, 100, 256).';

            mask = exp(-((f - 50) ./ 10).^2);

            Xraw = [ ...
                ones(numel(f), 1), ...
                2 * ones(numel(f), 1)];

            % Upstream masking convention.
            X = mask .* Xraw;

            binder = ReceptiveFieldResponseFunctions.maskedMeanAbs( ...
                eps = 1e-12);

            fcn = binder(mask);

            act = fcn(X, f);

            expected = ...
                trapz(f, abs(X), 1) ./ trapz(f, mask);

            testCase.verifyEqual( ...
                act, ...
                expected, ...
                "AbsTol", ...
                1e-12);
        end

        function testMaskedMeanAbsDoesNotApplyMaskAgain(testCase)

            f = linspace(0, 100, 256).';
        
            mask = exp(-((f - 50) ./ 10).^2);
        
            Xraw = ones(numel(f), 1);
        
            % Upstream masking convention.
            X = mask .* Xraw;
        
            binder = ReceptiveFieldResponseFunctions.maskedMeanAbs( ...
                eps = 1e-12);
        
            fcn = binder(mask);
        
            act = fcn(X, f);
        
            expected = ...
                trapz(f, abs(X), 1) ./ trapz(f, mask);
        
            doubleMasked = ...
                trapz(f, mask .* abs(X), 1) ./ trapz(f, mask);
        
            testCase.verifyEqual( ...
                act, ...
                expected, ...
                "AbsTol", ...
                1e-12);
        
            testCase.verifyGreaterThan( ...
                max(abs(act - doubleMasked), [], "all"), ...
                1e-6);
        end
        
        function testMaskedMeanAbsMaskMismatchThrows(testCase)

            f = linspace(0, 100, 32).';

            X = ones(32, 2);

            mask = ones(31, 1);

            binder = ...
                ReceptiveFieldResponseFunctions.maskedMeanAbs();

            fcn = binder(mask);

            testCase.verifyError( ...
                @() fcn(X, f), ...
                "sfrfs:ReceptiveFieldResponseFunctions:" + ...
                "MaskAxisMismatch");
        end

        function testMaskedMeanAbsInvalidMaskThrows(testCase)

            f = linspace(0, 100, 32).';

            X = ones(32, 2);

            mask = ones(32, 1);
            mask(5) = -1;

            binder = ...
                ReceptiveFieldResponseFunctions.maskedMeanAbs();

            fcn = binder(mask);

            testCase.verifyError( ...
                @() fcn(X, f), ...
                "sfrfs:ReceptiveFieldResponseFunctions:" + ...
                "InvalidMask");
        end

        function testMaskedMeanAbsEpsMustBePositive(testCase)

            testCase.verifyError( ...
                @() ReceptiveFieldResponseFunctions.maskedMeanAbs( ...
                    eps = -1), ...
                "MATLAB:validators:mustBePositive");
        end

        function testIntegralAbsMatchesTrapz(testCase)

            f = linspace(0, 200, 1024).';

            X = (1:1024).' * (1 + 1i);
            X = [X, 2 * X];

            fcn = ReceptiveFieldResponseFunctions.integralAbs();

            act = fcn(X, f);

            expected = trapz(f, abs(X), 1);

            testCase.verifyEqual( ...
                act, ...
                expected, ...
                "AbsTol", ...
                1e-12);
        end

        function testEntropyNormalizedUniformIsOne(testCase)

            nBins = 128;

            f = linspace(0, 200, nBins).';

            X = ones(nBins, 3);

            fcn = ReceptiveFieldResponseFunctions.entropy( ...
                normalize = true, ...
                eps = 1e-12);

            act = fcn(X, f);

            expected = ones(1, size(X, 2));

            testCase.verifyEqual( ...
                act, ...
                expected, ...
                "AbsTol", ...
                1e-6);
        end

        function testEntropyUnnormalizedUniformIsLogNBins(testCase)

            nBins = 64;

            f = linspace(0, 200, nBins).';

            X = ones(nBins, 2);

            fcn = ReceptiveFieldResponseFunctions.entropy( ...
                normalize = false, ...
                eps = 1e-12);

            act = fcn(X, f);

            expected = log(nBins) * ones(1, size(X, 2));

            testCase.verifyEqual( ...
                act, ...
                expected, ...
                "AbsTol", ...
                1e-6);
        end

        function testIntegralAbsFreqScaledOrderZeroEqualsIntegralAbs( ...
                testCase)

            f = linspace(0, 200, 256).';

            X = exp(1i * 2*pi*rand(size(f, 1), 4));

            f0 = ReceptiveFieldResponseFunctions.integralAbs();

            f1 = ...
                ReceptiveFieldResponseFunctions.integralAbsFreqScaled( ...
                    order = 0, ...
                    freqFloorHz = 1e-3);

            act = f1(X, f);

            expected = f0(X, f);

            testCase.verifyEqual( ...
                act, ...
                expected, ...
                "AbsTol", ...
                1e-12);
        end

        function testVelocityLikeEqualsOrder1(testCase)

            f = linspace(0, 200, 512).';

            X = randn(numel(f), 3) + ...
                1i * randn(numel(f), 3);

            fv = ReceptiveFieldResponseFunctions.velocityLike( ...
                freqFloorHz = 1e-3);

            f1 = ...
                ReceptiveFieldResponseFunctions.integralAbsFreqScaled( ...
                    order = 1, ...
                    freqFloorHz = 1e-3);

            testCase.verifyEqual( ...
                fv(X, f), ...
                f1(X, f), ...
                "AbsTol", ...
                1e-12);
        end

        function testDisplacementLikeEqualsOrder2(testCase)

            f = linspace(0, 200, 512).';

            X = randn(numel(f), 2) + ...
                1i * randn(numel(f), 2);

            fd = ReceptiveFieldResponseFunctions.displacementLike( ...
                freqFloorHz = 1e-3);

            f2 = ...
                ReceptiveFieldResponseFunctions.integralAbsFreqScaled( ...
                    order = 2, ...
                    freqFloorHz = 1e-3);

            testCase.verifyEqual( ...
                fd(X, f), ...
                f2(X, f), ...
                "AbsTol", ...
                1e-12);
        end

        function testValidateXFMismatchThrows(testCase)

            f = linspace(0, 200, 100).';

            X = ones(101, 2);

            fcn = ReceptiveFieldResponseFunctions.integralAbs();

            testCase.verifyError( ...
                @() fcn(X, f), ...
                "sfrfs:ReceptiveFieldResponseFunctions:" + ...
                "FreqAxisMismatch");
        end

        function testInvalidSpectrumThrows(testCase)

            f = linspace(0, 200, 10).';

            X = [];

            fcn = ReceptiveFieldResponseFunctions.integralAbs();

            testCase.verifyError( ...
                @() fcn(X, f), ...
                "sfrfs:ReceptiveFieldResponseFunctions:" + ...
                "InvalidSpectrum");
        end

        function testInvalidFreqAxisThrows(testCase)

            f = linspace(0, 200, 10).';
            f(3) = NaN;

            X = ones(10, 1);

            fcn = ReceptiveFieldResponseFunctions.integralAbs();

            testCase.verifyError( ...
                @() fcn(X, f), ...
                "sfrfs:ReceptiveFieldResponseFunctions:" + ...
                "InvalidFreqAxis");
        end

        function testEntropyEpsMustBePositive(testCase)

            testCase.verifyError( ...
                @() ReceptiveFieldResponseFunctions.entropy( ...
                    eps = -1), ...
                "MATLAB:validators:mustBePositive");
        end

        function testMaskedMeanAbsZeroMask(testCase)
            f = linspace(0, 100, 256).';
            mask = zeros(size(f));
            X = zeros(size(f));

            binder = ReceptiveFieldResponseFunctions.maskedMeanAbs();
            response = binder(mask);

            testCase.verifyEqual(response(X, f), 0);
        end

    end
end