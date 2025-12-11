classdef TestSFRFsEnsembleBroker < matlab.unittest.TestCase
    % Tests for the SFRFsEnsembleBroker subclass

    properties
        sampleEnsemble
        getFilesFcn
        temporalSnapshotColumns
        broker
    end

    methods (TestMethodSetup)
        function setup(testCase)
            % Dummy ensemble with Files property
            filesStruct = struct('Files', {{'file1.mat', 'file2.mat'}});
            testCase.sampleEnsemble = filesStruct;

            % Signal columns
            testCase.temporalSnapshotColumns = { ...
                'HorizontalAcceleration', 'VerticalAcceleration'};

            testCase.getFilesFcn = @(obj) obj.Files;

            % Create SFRFsEnsembleBroker instance
            testCase.broker = SFRFsEnsembleBroker( ...
                EnsembleObject = testCase.sampleEnsemble, ...
                GetFilesFunction = testCase.getFilesFcn, ...
                TemporalSnapshotColumns = ...
                testCase.temporalSnapshotColumns);
        end
    end

    methods (Test)

        function testDefaultSFRFsSuffix(testCase)
            % Map to SFRF name and infer default suffix
            name = "Signal1";
            sfrfsName = testCase.broker.mapToSFRFColumn(name);

            testCase.verifyEqual(sfrfsName, name + "_SFRFs");
        end

        function testCustomSFRFsSuffix(testCase)
            customSuffix = "_CUSTOM_SFRFS";

            customBroker = SFRFsEnsembleBroker( ...
                EnsembleObject = testCase.sampleEnsemble, ...
                GetFilesFunction = testCase.getFilesFcn, ...
                TemporalSnapshotColumns = ...
                testCase.temporalSnapshotColumns, ...
                sfrfsSuffix = customSuffix);

            name = "Signal2";
            sfrfsName = customBroker.mapToSFRFColumn(name);

            testCase.verifyEqual(sfrfsName, name + customSuffix);
        end

        function testMappingPreservesType(testCase)
            % char input
            baseChar = 'Signal_Char';
            sfrfsChar = testCase.broker.mapToSFRFColumn(baseChar);
            testCase.verifyClass(sfrfsChar, 'char');

            temporalChar = ...
                testCase.broker.mapToTemporalFromSFRFColumn(sfrfsChar);
            testCase.verifyEqual(temporalChar, baseChar);

            % string input
            baseStr = "Signal_String";
            sfrfsStr = testCase.broker.mapToSFRFColumn(baseStr);
            testCase.verifyClass(sfrfsStr, 'string');

            temporalStr = ...
                testCase.broker.mapToTemporalFromSFRFColumn(sfrfsStr);
            testCase.verifyEqual(temporalStr, baseStr);
        end

        function testTemporalMappingErrorsIfSuffixMissing(testCase)
            badName = "SignalWithoutSuffix";

            fcn = @() ...
                testCase.broker.mapToTemporalFromSFRFColumn(badName);

            testCase.verifyError(fcn, ...
                'sfrfs:EnsembleUtil:InvalidSuffix');
        end
    end
end
