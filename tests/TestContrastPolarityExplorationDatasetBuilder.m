classdef TestContrastPolarityExplorationDatasetBuilder < matlab.unittest.TestCase
%TESTCONTRASTPOLARITYEXPLORATIONDATASETBUILDER
% Fast contract tests for the exploratory ensemble-to-channel builder.
% These tests deliberately do not process the full XJTU-SY ensemble.
% Numerical parity and saved MAT-file contents require a separate
% integration comparison with the original experiment inputs.

    methods (Test)
        function defaultConfiguration(testCase)
            b = ContrastPolarityExplorationDatasetBuilder();
            testCase.verifyEqual(b.QuantileLevel, 0.95);
            testCase.verifyEqual(b.RiseRate, 1/7);
            testCase.verifyEqual(b.FallRate, 1/49);
            testCase.verifyEqual(b.FamilyNames, ...
                ["BPFO", "BPFI", "BSF", "FTF"]);
            testCase.verifyEqual(b.TemporalColumns, ...
                ["HorizontalAcceleration", "VerticalAcceleration"]);
            testCase.verifyEqual(b.SpectralColumns, ...
                ["HorizontalAcceleration_FFT", "VerticalAcceleration_FFT"]);
            testCase.verifyEmpty(b.DiagnosisTable);
        end

        function customConfiguration(testCase)
            diagnoses = table("BearingA", true, false, false, false, ...
                'VariableNames', {'Label', 'Failure_O', 'Failure_I', ...
                'Failure_C', 'Failure_B'});
            b = ContrastPolarityExplorationDatasetBuilder( ...
                quantileLevel = 0.9, riseRate = 0.2, fallRate = 0.1, ...
                epsEntropy = 1e-10, diagnosisTable = diagnoses);
            testCase.verifyEqual(b.QuantileLevel, 0.9);
            testCase.verifyEqual(b.RiseRate, 0.2);
            testCase.verifyEqual(b.FallRate, 0.1);
            testCase.verifyEqual(b.EntropyEpsilon, 1e-10);
            testCase.verifyEqual(b.DiagnosisTable, diagnoses);
        end

        function rejectsUnsupportedFamilyOrder(testCase)
            testCase.verifyError( ...
                @() ContrastPolarityExplorationDatasetBuilder( ...
                    familyNames = ["BPFI", "BPFO", "BSF", "FTF"]), ...
                "sfrfs:ExplorationDataset:Families");
        end

        function explicitFileRequiresSaving(testCase)
            b = ContrastPolarityExplorationDatasetBuilder();
            ds = localEmptyEnsemble();
            testCase.verifyError( ...
                @() b.buildFromEnsemble(ds, ...
                    outputFile = "my_dataset.mat"), ...
                "sfrfs:ExplorationDataset:SaveNotEnabled");
        end

        function rejectsMissingDatastoreVariables(testCase)
            b = ContrastPolarityExplorationDatasetBuilder();
            ds = localEmptyEnsemble();
            ds.DataVariables = "UnexpectedVariable";
            testCase.verifyError( ...
                @() b.buildFromEnsemble(ds), ...
                "sfrfs:ExplorationDataset:MissingVariables");
        end

        function rejectsInvalidDiagnosisSchema(testCase)
            diagnoses = table(...
                "BearingA", 'VariableNames', {'Label'});

            builder = ContrastPolarityExplorationDatasetBuilder( ...
                diagnosisTable = diagnoses);

            ds = localEmptyEnsemble();

            testCase.verifyError( ...
                @() builder.buildFromEnsemble(ds), ...
                ?MException);
        end

        function rejectsEmptyEnsemble(testCase)
            b = ContrastPolarityExplorationDatasetBuilder();
            ds = localEmptyEnsemble();
            testCase.verifyError( ...
                @() b.buildFromEnsemble(ds), ...
                "sfrfs:ExplorationDataset:EmptyEnsemble");
        end
    end
end

function ds = localEmptyEnsemble()
% Minimal in-memory datastore double for schema and empty-input checks.
    required = ["Label", "SnapshotIndex", "Speed", "Load", "Lifetime", ...
        "HorizontalAcceleration", "VerticalAcceleration", ...
        "HorizontalAcceleration_FFT", "VerticalAcceleration_FFT"];
    ds = ContrastPolarityEmptyEnsembleFixture(required);
end
