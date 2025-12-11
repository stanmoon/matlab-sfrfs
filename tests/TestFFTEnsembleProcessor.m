classdef TestFFTEnsembleProcessor < matlab.unittest.TestCase
    % Test suite for FFTEnsembleProcessor

    properties (Constant)
        % Column/field names and test labels
        ColHorizAccel = "HorizontalAcceleration";
        ColVertAccel  = "VerticalAcceleration";
        ColHorizFFT   = "HorizontalAcceleration_FFT";
        ColVertFFT    = "VerticalAcceleration_FFT";
        ColSnapshot   = "SnapshotIndex";
        TempMemberFmt = "member_%d.mat";
        DataStructField = "ensembleMemberTable";
        EnsembleFilesPattern = "member_*.mat";
        TemporalColumns = ...
            {'HorizontalAcceleration','VerticalAcceleration'};
        AbsTol = 1.e-10;
    end

    properties
        processor
        testEnsemble
        tempDir
    end

    methods (TestMethodSetup)
        function setupTest(testCase)
            testCase.tempDir = tempname;
            mkdir(testCase.tempDir);
            for k = 1:2
                tbl = table;
                tbl.(testCase.ColHorizAccel) = {randn(128,1)};
                tbl.(testCase.ColVertAccel)  = {randn(128,1)};
                tbl.(testCase.ColSnapshot)   = k;
                dataToSave = struct(testCase.DataStructField, tbl);
                save(fullfile(testCase.tempDir, ...
                    sprintf(testCase.TempMemberFmt, k)), ...
                    '-fromstruct', dataToSave, '-v7.3');
            end
            files = dir(fullfile( ...
                testCase.tempDir, testCase.EnsembleFilesPattern));
            fileList = fullfile({files.folder}, {files.name})';
            ensembleStruct = struct('Files', {fileList});
            testCase.testEnsemble = EnsembleBroker(...
                ensembleObject = ensembleStruct, ...
                getFilesFunction = @(obj) obj.Files, ...
                temporalSnapshotColumns = testCase.TemporalColumns);
            testCase.processor = FFTEnsembleProcessor(...
                numWorkers = 2, ...
                ensemble = testCase.testEnsemble);
        end
    end

    methods (TestMethodTeardown)
        function teardownTest(testCase)
            if isfolder(testCase.tempDir)
                rmdir(testCase.tempDir, 's');
            end
        end
    end

    methods (Test)
        function testProcessAddsFFTColumns(testCase)
            testCase.processor.process();
            for k = 1:numel(testCase.testEnsemble.ensemble.Files)
                data = load( ...
                    testCase.testEnsemble.ensemble.Files{k}, ...
                    testCase.DataStructField);
                tbl = data.(testCase.DataStructField);
                testCase.verifyTrue( ...
                    ismember( ...
                        testCase.ColHorizFFT, ...
                        tbl.Properties.VariableNames));
                testCase.verifyTrue(...
                    ismember( ...
                        testCase.ColVertFFT, ...
                        tbl.Properties.VariableNames));
                testCase.verifyEqual( ...
                    length(tbl.(testCase.ColHorizFFT)), height(tbl));
                testCase.verifyEqual( ...
                    length(tbl.(testCase.ColVertFFT)), height(tbl));
            end
        end

        function testFFTValuesAreCorrect(testCase)
            testCase.processor.process();
            for k = 1:numel(testCase.testEnsemble.ensemble.Files)
                data = load( ...
                    testCase.testEnsemble.ensemble.Files{k}, ...
                    testCase.DataStructField);
                tbl = data.(testCase.DataStructField);
                for row = 1:height(tbl)
                    xh = tbl.(testCase.ColHorizAccel){row};
                    xv = tbl.(testCase.ColVertAccel){row};
                    testCase.verifyEqual( ...
                        tbl.(testCase.ColHorizFFT){row}, ...
                        fft(xh), 'AbsTol', testCase.AbsTol);
                    testCase.verifyEqual( ...
                        tbl.(testCase.ColVertFFT){row}, ...
                        fft(xv), 'AbsTol', testCase.AbsTol);
                end
            end
        end

        function testParallelProcessing(testCase)
            testCase.processor.process();
            testCase.assertTrue(true);
        end

        function testNoFilesDoesNotError(testCase)
            noMembersEnsembleStruct = struct('Files', {{}});
            noMembersEnsemble = EnsembleBroker(...
                ensembleObject = noMembersEnsembleStruct, ...
                getFilesFunction = @(obj) obj.Files, ...
                temporalSnapshotColumns = {});
            testCase.processor.ensemble = noMembersEnsemble;
            testCase.processor.process();
            testCase.assertTrue(true);
        end
    end
end
