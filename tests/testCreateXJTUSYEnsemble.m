% testCreateXJTUSYEnsemble.m
%
% Unit tests for the createXJTUSYEnsemble function.
% Verifies correct dataset creation, output folder handling,
% data structure integrity, and error handling for invalid inputs.
%
% Uses temporary folders and mock data to isolate tests from
% actual dataset dependencies.

function tests = testCreateXJTUSYEnsemble
    tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    rng('default'); 
    % Create a temporary dataset structure for testing
    testCase.TestData.tempRoot = tempname;
    mkdir(testCase.TestData.tempRoot);
    testCase.TestData.oc = ["35Hz12kN", "37.5Hz11kN", "40Hz10kN"];
    N = numel(testCase.TestData.oc);
    testCase.TestData.snapshotCounts = zeros(N, 5); 

    for i = 1:N
        for j = 1:5
            bearingFolder = fullfile(...
                testCase.TestData.tempRoot, ...
                testCase.TestData.oc(i), ...
                sprintf("Bearing%d_%d", i, j));
            mkdir(bearingFolder);
            % Random number of snapshots between 5 and 10
            numSnapshots = randi([5,10]);
            testCase.TestData.snapshotCounts(i,j) = numSnapshots;
            for k = 1:numSnapshots
                T = table(randn(2048,1), randn(2048,1), ...
                    'VariableNames', {...
                    'Horizontal_vibration_signals', ...
                    'Vertical_vibration_signals'});
                writetable(T, ...
                    fullfile(bearingFolder, sprintf('%d.csv', k)));
            end
        end
    end
end

function teardownOnce(testCase)
    % Remove temporary test data
    if isfolder(testCase.TestData.tempRoot)
        rmdir(testCase.TestData.tempRoot, 's');
    end
end

function testCreatesEnsembleDatastore(testCase)
    import data.createXJTUSYEnsemble
    outputFolder = tempname;
   ensemble = createXJTUSYEnsemble( ...
       "datasetFolder", testCase.TestData.tempRoot, ...
       "outputFolder", outputFolder, ...
       "progressMode", "none" ...
       );
    % Verify output folder exists and .mat files are present
    files = dir(fullfile(outputFolder, '*.mat'));
    verifyGreaterThan(testCase, numel(files), 0, 'No .mat files created');
    % Verify the ensemble is a fileEnsembleDatastore
    verifyClass(testCase, ensemble, 'fileEnsembleDatastore');
    % Verify the ensemble has the expected variables
    expectedVars = ["Label","SnapshotIndex","Speed","Load","Lifetime",...
        "HorizontalAcceleration","VerticalAcceleration"];
    verifyEqual(testCase, ...
        sort(ensemble.SelectedVariables(:))', ...
        sort(expectedVars(:))');

    % Preview data and check structure
    tbl = preview(ensemble);
    verifyTrue(testCase, ...
        all(ismember(expectedVars, tbl.Properties.VariableNames)));
end

function testMissingInputFolderThrowsError(testCase)
    import data.createXJTUSYEnsemble
    verifyError(testCase, ...
    @() createXJTUSYEnsemble( ...
        "datasetFolder", "nonexistent_folder", ...
        "outputFolder", tempname, ...
        "progressMode", "none" ...
    ), ...
    'sfrfs:data:createXJTUSYEnsemble:InputFolderDoesNotExist');

end

function testOutputFolderCreated(testCase)
    import data.createXJTUSYEnsemble
    outputFolder = fullfile(tempname, 'newoutput');
    createXJTUSYEnsemble( ...
        datasetFolder = testCase.TestData.tempRoot, ...
        outputFolder = outputFolder, ...
        progressMode = "none" ...
        );
    verifyTrue(testCase, isfolder(outputFolder), ...
        'Output folder was not created');

end

function testMatFileCountEqualsBearings(testCase)
    import data.createXJTUSYEnsemble
    outputFolder = tempname;
    createXJTUSYEnsemble(...
        datasetFolder = testCase.TestData.tempRoot, ...
        outputFolder = outputFolder, ...
        progressMode = "none");

    N = numel(testCase.TestData.oc);
    bearingsPerOC = 5; 
    expectedNumBearings = N * bearingsPerOC;

    % Count .mat files in the output folder
    matFiles = dir(fullfile(outputFolder, '*.mat'));
    actualNumMatFiles = numel(matFiles);

    verifyEqual(testCase, actualNumMatFiles, expectedNumBearings, ...
        'The number of .mat files does not match the number of bearings.');
end

function testEnsembleRowCount(testCase)
    import data.createXJTUSYEnsemble
    ensemble = createXJTUSYEnsemble(...
        datasetFolder = testCase.TestData.tempRoot, ...
        outputFolder = tempname, ...
        progressMode = "none");

    % Calculate expected number of snapshots
    expectedTotalSnapshots = sum(testCase.TestData.snapshotCounts, 'all');

    % Read all rows from the ensemble
    tbl = readall(ensemble);

    % Verify the count
    verifyEqual(testCase, height(tbl), expectedTotalSnapshots, ...
        ['The number of rows in the ensemble does not match the ', ...
        'expected number of snapshots.']);
end

