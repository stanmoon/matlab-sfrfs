classdef testGetXJTUSYEnsemble < matlab.unittest.TestCase
%TESTGETXJTUSYENSEMBLE Unit tests for the getXJTUSYEnsemble function.
%
%   Verifies correct construction, configuration, and error handling
%   of the data.getXJTUSYEnsemble function.

    properties
        TempFolder
        MemberFiles
        MemberData
    end

    methods (TestClassSetup)
        function setupOnce(testCase)
            % Create a temporary folder for ensemble members
            testCase.TempFolder = tempname;
            mkdir(testCase.TempFolder);

            % Create dummy data for 3 members
            testCase.MemberFiles = strings(3,1);
            testCase.MemberData = cell(3,1);
            for k = 1:3
                tbl = table( ...
                    categorical("Label" + k), ...
                    k, ... % SnapshotIndex
                    rand()*100, ... % Speed
                    rand()*10, ...  % Load
                    randi(100), ... % Lifetime
                    {randn(5,1)}, ... % HorizontalAcceleration
                    {randn(5,1)}, ... % VerticalAcceleration
                    'VariableNames', ...
                    {'Label','SnapshotIndex','Speed','Load','Lifetime', ...
                     'HorizontalAcceleration','VerticalAcceleration'} ...
                );
                filename = fullfile(...
                    testCase.TempFolder, sprintf('member_%d.mat', k));
                ensembleMemberTable = tbl; %#ok<NASGU>
                save(filename, 'ensembleMemberTable');
                testCase.MemberFiles(k) = filename;
                testCase.MemberData{k} = tbl;
            end
        end
    end

    methods(TestClassTeardown)
        function teardownOnce(testCase)
            % Clean up temp folder
            if isfolder(testCase.TempFolder)
                rmdir(testCase.TempFolder, 's');
            end
        end
    end


    methods (Test)
        function testReturnsDatastore(testCase)
            ensemble = data.getXJTUSYEnsemble(testCase.TempFolder);
            testCase.verifyClass(ensemble, 'fileEnsembleDatastore');
        end

        function testVariablesAreConfigured(testCase)
            ensemble = data.getXJTUSYEnsemble(testCase.TempFolder);
            expectedVars = [
                "Label","Speed","Load","Lifetime","SnapshotIndex", ...
                "HorizontalAcceleration","VerticalAcceleration"
            ];
            testCase.verifyEqual(...
                sort(ensemble.SelectedVariables(:)), ...
                sort(expectedVars(:)));
        end


        function testReadAllMatchesOriginal(testCase)
            ensemble = data.getXJTUSYEnsemble(testCase.TempFolder);
            tbl = readall(ensemble);

            % There should be 3 rows (one per member)
            testCase.verifyEqual(height(tbl), 3);

            % Check that each member's data matches what was written
            for k = 1:3
                orig = testCase.MemberData{k};
                readRow = tbl(k,:);
                % Compare each variable
                for v = orig.Properties.VariableNames
                    testCase.verifyEqual(readRow.(v{1}), orig.(v{1}));
                end
            end
        end

        function testErrorOnMissingFolder(testCase)
            nonexistent = tempname;
            testCase.verifyError(@() ...
                data.getXJTUSYEnsemble(nonexistent), ...
                'sfrfs:data:getXJTUSYEnsemble:NotAFolder');
        end
    end
end
