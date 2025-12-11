classdef TestEnsembleBroker < matlab.unittest.TestCase
    % Tests for the EnsembleBroker wrapper class

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

            % Signal columns for temporal snapshot columns argument
            testCase.temporalSnapshotColumns = {...
                'HorizontalAcceleration', 'VerticalAcceleration'};

            testCase.getFilesFcn = @(obj) obj.Files;

            % Updated constructor call with temporalSnapshotColumns
            testCase.broker = EnsembleBroker(...
                ensembleObject = testCase.sampleEnsemble, ...
                getFilesFunction = testCase.getFilesFcn, ...
                temporalSnapshotColumns = ...
                testCase.temporalSnapshotColumns);
        end
    end

    methods (Test)
        function testGetFilesReturnsCorrectFiles(testCase)
            % Verify that getFiles returns the correct file list
            files = testCase.broker.getFiles();
            filesStruct = struct('Files', {{'file1.mat', 'file2.mat'}});
            testCase.verifyEqual(files, filesStruct.Files);
        end

        function testConstructorRejectsEmptyEnsemble(testCase)
            % Verify constructor rejects empty ensembleObject
            testCase.verifyError(@() EnsembleBroker(...
                ensembleObject = [], ...
                getFilesFunction = testCase.getFilesFcn, ...
                    temporalSnapshotColumns = ...
                    testCase.temporalSnapshotColumns), ...
                    'MATLAB:validators:mustBeNonempty');
        end

        function testConstructorRejectsMissingGetFilesFunction(testCase)
            % Verify constructor throws error if function is missing
            testCase.verifyError(@() EnsembleBroker(...
                ensembleObject = testCase.sampleEnsemble, ...
                temporalSnapshotColumns = ...
                    testCase.temporalSnapshotColumns), ...
                'MATLAB:nonExistentField');
        end

        function testConstructorRejectsMissingEnsembleObject(testCase)
            % Verify constructor throws error if ensembleObject is missing
            testCase.verifyError(@() EnsembleBroker(...
                getFilesFunction = testCase.getFilesFcn, ...
                temporalSnapshotColumns = ...
                    testCase.temporalSnapshotColumns), ...
                    'MATLAB:nonExistentField');
        end

        function testConstructorRejectsMissingTemporalSnapshotColumns(...
                testCase)
            % Verify constructor throws error if temporalSnapshotColumns is 
            % missing
            testCase.verifyError(@() EnsembleBroker(...
                ensembleObject = testCase.sampleEnsemble, ...
                getFilesFunction = testCase.getFilesFcn), ...
                    'MATLAB:nonExistentField');
        end

        function testConstructorRejectsInvalidTemporalSnapshotColumns(...
                testCase)
            badColumns = {42, [3;1]}; 
            testCase.verifyError(@() EnsembleBroker(...
                ensembleObject = testCase.sampleEnsemble, ...
                getFilesFunction = testCase.getFilesFcn, ...
                temporalSnapshotColumns = badColumns), ...
                'sfrfs:EnsembleBroker:InvalidColumnNames');
        end

        function testSaveAndLoadEnsembleMember(testCase)
            tbl = table((1:3)', ['a';'b';'c'], 'VariableNames', ...
                {'SnapshotIndex','Signal'});
            filename = tempname+".mat";

            EnsembleBroker.saveEnsembleMember(...
                filename, 'ensembleMemberTable', tbl);
            loadedTbl = EnsembleBroker.loadEnsembleMember(...
                filename = filename, ...
                memberTableVarName = 'ensembleMemberTable');

            testCase.verifyEqual(loadedTbl, tbl);
        end

        function testSaveEnsembleMemberRejectsBadVarName(testCase)
            tbl = table(1:3);
            filename = tempname+".mat";
            testCase.verifyError(@() ...
                EnsembleBroker.saveEnsembleMember(...
                filename, "bad name", tbl), ...
                'sfrfs:EnsembleBroker:InvalidVarName');
        end

        function testDefaultSpectralSuffix(testCase)
            testCase.verifyEqual(testCase.broker.spectralSuffix, "_FFT");
        end
        
        function testCustomSpectralSuffix(testCase)
            customSuffix = "_FFT_CUSTOM";
            customBroker = EnsembleBroker(...
                ensembleObject = testCase.sampleEnsemble, ...
                getFilesFunction = testCase.getFilesFcn, ...
                temporalSnapshotColumns = ...
                    testCase.temporalSnapshotColumns, ...
                spectralSuffix = customSuffix);
            testCase.verifyEqual(...
                customBroker.spectralSuffix, customSuffix);
        end

        function testMappingMethodsPreserveType(testCase)
            baseNameChar = 'Signal_1';
            baseNameStr = "Signal_2";
            
            % char input
            specNameChar = ...
                testCase.broker.mapToSpectralColumn(baseNameChar);
            testCase.verifyClass(specNameChar, 'char');
            tempNameChar = ...
                testCase.broker.mapToTemporalColumn(specNameChar);
            testCase.verifyClass(tempNameChar, 'char');
            testCase.verifyEqual(tempNameChar, baseNameChar);
            
            % string input
            specNameStr = testCase.broker.mapToSpectralColumn(baseNameStr);
            testCase.verifyClass(specNameStr, 'string');
            tempNameStr = testCase.broker.mapToTemporalColumn(specNameStr);
            testCase.verifyClass(tempNameStr, 'string');
            testCase.verifyEqual(tempNameStr, baseNameStr);
        end

       function testMappingPreservesInputTypeChar(testCase)
            baseName = 'Signal1';
            % Map to spectral name
            spectral = testCase.broker.mapToSpectralColumn(baseName);
            testCase.verifyClass(spectral, 'char');
            % Map back to temporal name
            temporal = testCase.broker.mapToTemporalColumn(spectral);
            testCase.verifyClass(temporal, 'char');
            testCase.verifyEqual(temporal, baseName);
        end
    
        function testMappingPreservesInputTypeString(testCase)
            baseName = "Signal2";
            % Map to spectral name
            spectral = testCase.broker.mapToSpectralColumn(baseName);
            testCase.verifyClass(spectral, 'string');
            % Map back to temporal name
            temporal = testCase.broker.mapToTemporalColumn(spectral);
            testCase.verifyClass(temporal, 'string');
            testCase.verifyEqual(temporal, baseName);
        end
    
        function testMapToTemporalColumnErrorsIfSuffixMissing(testCase)
            badName = "SignalWithoutSuffix";
            fcn = @() testCase.broker.mapToTemporalColumn(badName);
            testCase.verifyError(fcn, ...
                'sfrfs:EnsembleUtil:InvalidSuffix');
        end
    
        function testMappingWithCustomSuffix(testCase)
            customSuffix = "__CUSTOM_SPECTRAL_SUFFIX";
            customBroker = EnsembleBroker(...
                ensembleObject = testCase.sampleEnsemble, ...
                getFilesFunction = testCase.getFilesFcn, ...
                temporalSnapshotColumns = ...
                    testCase.temporalSnapshotColumns, ...
                spectralSuffix = customSuffix);
            baseName = "Signal3";
            spectral = customBroker.mapToSpectralColumn(baseName);
            testCase.verifyEqual(spectral, baseName + customSuffix);
            temporal = customBroker.mapToTemporalColumn(spectral);
            testCase.verifyEqual(temporal, baseName);
        end

    end
end
