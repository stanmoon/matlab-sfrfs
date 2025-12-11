classdef TestEnsembleUtil < matlab.unittest.TestCase
    % Unit tests for EnsembleUtil

    methods (Test)

        function testAppendSuffixWithChar(testCase)
            base = 'Signal';
            suffix = "_FFT";

            result = EnsembleUtil.appendSuffix(base, suffix);

            testCase.verifyClass(result, 'char');
            testCase.verifyEqual(result, 'Signal_FFT');
        end


        function testAppendSuffixWithString(testCase)
            base = "Signal";
            suffix = "_SFRFs";

            result = EnsembleUtil.appendSuffix(base, suffix);

            testCase.verifyClass(result, 'string');
            testCase.verifyEqual(result, "Signal_SFRFs");
        end


        function testRemoveSuffixWithChar(testCase)
            name = 'Signal_FFT';
            suffix = "_FFT";

            result = EnsembleUtil.removeSuffix(name, suffix);

            testCase.verifyClass(result, 'char');
            testCase.verifyEqual(result, 'Signal');
        end


        function testRemoveSuffixWithString(testCase)
            name = "Signal_SFRFs";
            suffix = "_SFRFs";

            result = EnsembleUtil.removeSuffix(name, suffix);

            testCase.verifyClass(result, 'string');
            testCase.verifyEqual(result, "Signal");
        end


        function testRemoveSuffixThrowsIfMissing(testCase)
            name = "Signal_FFT";
            suffix = "_SFRFs";

            testCase.verifyError(@() ...
                EnsembleUtil.removeSuffix(name, suffix), ...
                'sfrfs:EnsembleUtil:InvalidSuffix');
        end

    end
end
