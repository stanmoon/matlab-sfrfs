classdef TestBearingFrequencyBands < matlab.unittest.TestCase
    % Test suite for the BearingFrequencyBands class.
    %
    % Covers:
    %   - Valid construction with required arguments
    %   - Constructor type validation errors
    %   - computeForSpeed output structure correctness
    %   - computeFaultFrequencyBands input validation errors
    %   - Band computation correctness for known input
    %   - Label formatting and band structure integrity
    
    properties
        validOperatingConditions
        validBearingParams
        validSfrfsParams
        bfb      % BearingFrequencyBands instance
    end
    
    methods (TestMethodSetup)
        function createValidObjects(testCase)
            % Create a valid ParametersRollingBearings
            testCase.validBearingParams = ParametersRollingBearings( ...
                'numRollingElements', 8, ...
                'ballDiameter',       7.92, ...
                'pitchDiameter',      34.55, ...
                'contactAngle',       0 );
            
            % Create shared SFRF params for all fault types
            sharedParams = ...
                SFRFsParametersRollingBearings.createSFRFsParameters(...
                'order',           3, ...
                'numSidebands',    2, ...
                'numHarmonics',    3, ...
                'sigmaCenter',     [5, 7], ...
                'sigmaSurround',   [12, 3], ...
                'inhibitionFactor', 0.5 );
            
            testCase.validSfrfsParams = SFRFsParametersRollingBearings( ...
                'SameForAllFaultTypes', sharedParams );

            speed = [35; 37.5; 40];
            load  = [12; 11; 10];
            testCase.validOperatingConditions = ...
                OperatingConditions(speed, load);
            
            % Create BFB object
            testCase.bfb = BearingFrequencyBands( ...
                bearingParams = testCase.validBearingParams, ...
                sfrfsParams = testCase.validSfrfsParams,...
                operatingConditions = testCase.validOperatingConditions ...
                );
        end
    end
    
    methods (Test)
        
        % test valid construction and argument settings
        function testValidConstruction(testCase)
            testCase.verifyInstanceOf(...
                ...
                testCase.bfb, 'BearingFrequencyBands');
            testCase.verifyEqual(...
                testCase.bfb.bearingParams, testCase.validBearingParams);
            testCase.verifyEqual(...
                testCase.bfb.sfrfsParams, testCase.validSfrfsParams);
        end
        
        % test for an invalid object for bearing parameters
        function testInvalidBearingParamsType(testCase)
            testCase.verifyError(@() BearingFrequencyBands( ...
                bearingParams='invalid', ...
                sfrfsParams = testCase.validSfrfsParams,...
                OperatingConditions = testCase.validOperatingConditions), ...
                'MATLAB:validation:UnableToConvert');
        end

        % test for an invalid SFRF parameters
        function testInvalidSfrfsParamsType(testCase)
            invalidSFRFParams = [];
            testCase.verifyError(@() BearingFrequencyBands( ...
                bearingParams = testCase.validBearingParams, ...
                sfrfsParams = invalidSFRFParams,...
                OperatingConditions = testCase.validOperatingConditions), ...
                'MATLAB:validation:UnableToConvert');
        end

        % test for an invalid operating conditions
        function testInvalidOperatingConditions(testCase)
            invalidOperatingConditions = {};
            testCase.verifyError(@() BearingFrequencyBands( ...
                bearingParams = testCase.validBearingParams, ...
                sfrfsParams = testCase.validSfrfsParams,...
                OperatingConditions = invalidOperatingConditions), ...
                'MATLAB:validation:UnableToConvert');
        end

        % test missing bearing parameters
        function testMissingBearingParamsArgument(testCase)
            testCase.verifyError(@() BearingFrequencyBands( ...
                sfrfsParams = testCase.validSfrfsParams,...
                OperatingConditions = testCase.validOperatingConditions), ...
                'MATLAB:nonExistentField');
        end

        % test missing bearing parameters
        function testMissingSFRSsParamsArgument(testCase)
            testCase.verifyError(@() BearingFrequencyBands( ...
                bearingParams = testCase.validBearingParams, ...
                OperatingConditions = testCase.validOperatingConditions), ...
                'MATLAB:nonExistentField');
        end

        % test missing bearing parameters
        function testMissingOperatingConditionsArgument(testCase)
            testCase.verifyError(@() BearingFrequencyBands( ...
                bearingParams = testCase.validBearingParams, ...
                sfrfsParams = testCase.validSfrfsParams), ...
                'MATLAB:nonExistentField');
        end    
        
        
        % test structure of computation of individual operating conditions
        function testComputeForSpeedKeysAndTypes(testCase)
            result = testCase.bfb.computeForSpeed(30);
            ftNames = SFRFsParametersRollingBearings.faultTypes;
            
            % we expect a structure with fault types as field names
            testCase.verifyEqual(sort(fieldnames(result)), sort(ftNames)');
            
            % Check that each fault type returns a cell array of Maps
            % each map having appropriate keys
            for f = ftNames
                val = result.(f{1});
                testCase.verifyClass(val, 'cell');
                testCase.verifyClass(val{1}, 'containers.Map');
                testCase.verifyTrue(...
                    all( isKey(val{1}, ...
                    {'Bands','Harmonic','Label','Sideband'}) ));
            end
        end
        
        % test descriptions in table
        function testDescriptionsInAnswer(testCase)

            ocTable = testCase.validOperatingConditions.conditionsTable;
            testCase.bfb.computeBands();
            tbl = testCase.bfb.bandsTable;
            numrows = height(tbl);
            expectedRows = height(ocTable) * ...
                numel(SFRFsParametersRollingBearings.faultTypes);
            testCase.verifyEqual(numrows, expectedRows);
            
            % consistency of fault group and description
            
            for idx = 1:expectedRows
                faultType = BearingFrequencyBands.faultGroupToTypeName(...
                    tbl.FaultGroup(idx) );

                expectedDesc = ...
                    BearingFrequencyBands.faultTypeDescriptions(...
                    faultType);

                actualDesc = string(tbl.Description{idx});

                testCase.verifyEqual(actualDesc, expectedDesc);
            end
        end
        
        % test BPFO
        function testBPFOcentralFreqFromMaps(testCase)
            speed = 30;
            NB = testCase.validBearingParams.numRollingElements; 
            DB = testCase.validBearingParams.ballDiameter;
            DP = testCase.validBearingParams.pitchDiameter;
            phi = testCase.validBearingParams.contactAngle;
            
            % call to MATLAB's bearingFaultBands function to get bands 
            [~, info] = bearingFaultBands(speed, NB, DB, DP, phi);
            
            % Find the index of the BPFO first harmonic
            expectedLabel = ['1' BearingFrequencyBands.BPFO_CODE];

            idxBPFO = find(strcmp(info.Labels, expectedLabel), 1);
            expectedBPFO = info.Centers(idxBPFO);
            
            % compute with class 
            rs = testCase.bfb.computeForSpeed(speed);
            % No need to search for label, no sidebands, first element is
            % the first harmonic
            bpfoMap = rs.(...
             SFRFsParametersRollingBearings.OUTER_RACE_FAULT_TYPE_NAME){1};

            labelFromMap = bpfoMap('Label');
            
            % average center of receptive field to estimate central freq
            centralFreqFromMap = mean(bpfoMap('Bands').Center);
            
            % check it matches MATLAB's PdM toolbox answer
            testCase.verifyEqual(...
                centralFreqFromMap, expectedBPFO, 'AbsTol', 1e-12);
            testCase.verifyEqual(labelFromMap, expectedLabel);
        end
        
        % test BPFI
        function testBPFIcentralFreqFromMaps(testCase)
            speed = 30;
            NB = testCase.validBearingParams.numRollingElements; 
            DB = testCase.validBearingParams.ballDiameter;
            DP = testCase.validBearingParams.pitchDiameter;
            phi = testCase.validBearingParams.contactAngle;
        
            [~, info] = bearingFaultBands(speed, NB, DB, DP, phi);

            expectedLabel = ['1' BearingFrequencyBands.BPFI_CODE];
            idx = find(strcmp(info.Labels, expectedLabel), 1);
            expected = info.Centers(idx);
        
            rs = testCase.bfb.computeForSpeed(speed);

            maps = rs.(...
                SFRFsParametersRollingBearings.INNER_RACE_FAULT_TYPE_NAME);

            %find index of central freq
            idxCentral = find(...
                strcmp(...
                cellfun(...
                @(m)m('Label'), maps, 'UniformOutput', false),...
                expectedLabel), 1);

            bpfiMap = maps{idxCentral};
            
            centralFreqFromMap = mean(bpfiMap('Bands').Center);

            labelFromMap = bpfiMap('Label');
        
            testCase.verifyEqual(...
                centralFreqFromMap, expected, 'AbsTol', 1e-12);

            testCase.verifyEqual(labelFromMap, expectedLabel);
        end
        
        % test BSF
        function testBSFcentralFreqFromMaps(testCase)
            speed = 30;
            NB = testCase.validBearingParams.numRollingElements; 
            DB = testCase.validBearingParams.ballDiameter;
            DP = testCase.validBearingParams.pitchDiameter;
            phi = testCase.validBearingParams.contactAngle;
        
            [~, info] = bearingFaultBands(speed, NB, DB, DP, phi);

            expectedLabel = ['1' BearingFrequencyBands.BSF_CODE];
            idx = find(strcmp(info.Labels, expectedLabel), 1);
            expected = info.Centers(idx);
        
            rs = testCase.bfb.computeForSpeed(speed);

            maps = rs.(...
                SFRFsParametersRollingBearings.BALL_FAULT_TYPE_NAME);

            %find index of central freq
            idxCentral = find(...
                strcmp(...
                cellfun(...
                @(m)m('Label'), maps, 'UniformOutput', false),...
                expectedLabel), 1);

            bsfMap = maps{idxCentral};

            labelFromMap = bsfMap('Label');

            centralFreqFromMap = mean(bsfMap('Bands').Center);
        
            testCase.verifyEqual(...
                centralFreqFromMap, expected, 'AbsTol', 1e-12);

            testCase.verifyEqual(labelFromMap, expectedLabel);
        end
        
        function testFTFcentralFreqFromMaps(testCase)
            speed = 30;
            NB = testCase.validBearingParams.numRollingElements; 
            DB = testCase.validBearingParams.ballDiameter;
            DP = testCase.validBearingParams.pitchDiameter;
            phi = testCase.validBearingParams.contactAngle;
        
            [~, info] = bearingFaultBands(speed, NB, DB, DP, phi);

            expectedLabel = ['1' BearingFrequencyBands.FTF_CODE];
            idx = find(strcmp(info.Labels, expectedLabel), 1);
            expected = info.Centers(idx);
        
            rs = testCase.bfb.computeForSpeed(speed);
            % No need to search for label: FTF has no sidebands
            % first harmonic in first index as they are ordered
            ftfMap = rs.(...
                SFRFsParametersRollingBearings.CAGE_FAULT_TYPE_NAME){1};

            labelFromMap = ftfMap('Label');

            centralFreqFromMap = mean(ftfMap('Bands').Center);
        
            testCase.verifyEqual(...
                centralFreqFromMap, expected, 'AbsTol', 1e-12);

            testCase.verifyEqual(labelFromMap, expectedLabel);
        end

        % check bands of central freq for BPFO
        function testBPFOCenterAndSurroundBands(testCase)
            speed = 30;
            NB  = testCase.validBearingParams.numRollingElements;
            DB  = testCase.validBearingParams.ballDiameter;
            DP  = testCase.validBearingParams.pitchDiameter;
            phi = testCase.validBearingParams.contactAngle;
            expectedLabel = ['1' BearingFrequencyBands.BPFO_CODE];
        
            % expected center band
            widthCenter = ...
                testCase.validSfrfsParams.outerRace.sigmaCenter(1);
            [FBcenter, info] = ...
                bearingFaultBands(speed, NB, DB, DP, phi, ...
                'Width', widthCenter);
            idxCenter = find(strcmp(info.Labels, expectedLabel), 1);
            expectedCenterBand = FBcenter(idxCenter,:);
        
            % expected surround band
            widthSurround = ...
                testCase.validSfrfsParams.outerRace.sigmaSurround(1);
            FBsurround = bearingFaultBands(speed, NB, DB, DP, phi, ...
                                           'Width', widthSurround);
            expectedSurroundBand = FBsurround(idxCenter,:); 
        
            % compute with class under test
            rs = testCase.bfb.computeForSpeed(speed);
            % first harmonic is first element
            bpfoMap = rs.(...
             SFRFsParametersRollingBearings.OUTER_RACE_FAULT_TYPE_NAME){1};

            bands = bpfoMap('Bands');
        
            % checks
            testCase.verifyEqual(...
                bands.Center,   expectedCenterBand,   'AbsTol', 1e-12);
            testCase.verifyEqual(...
                bands.Surround, expectedSurroundBand, 'AbsTol', 1e-12);
        end

        % check bands of central freq for BPFI
        function testBPFICenterAndSurroundBands(testCase)
            speed = 30;
            NB  = testCase.validBearingParams.numRollingElements;
            DB  = testCase.validBearingParams.ballDiameter;
            DP  = testCase.validBearingParams.pitchDiameter;
            phi = testCase.validBearingParams.contactAngle;
            expectedLabel = ['1' BearingFrequencyBands.BPFI_CODE]; 
        
            % expected center band
            widthCenter = ...
                testCase.validSfrfsParams.innerRace.sigmaCenter(1);
            [FBcenter, info] = bearingFaultBands(...
                speed, NB, DB, DP, phi, ...
                'Width', widthCenter);
            idxCenter = find(strcmp(info.Labels, expectedLabel), 1);
            expectedCenterBand = FBcenter(idxCenter,:);
        
            % expected surround band
            widthSurround = ...
                testCase.validSfrfsParams.innerRace.sigmaSurround(1);
            FBsurround = bearingFaultBands(speed, NB, DB, DP, phi, ...
                                           'Width', widthSurround);
            expectedSurroundBand = FBsurround(idxCenter,:);
        
            % compute with class under test
            rs = testCase.bfb.computeForSpeed(speed);

            % actual maps from class
            maps = rs.(...
                SFRFsParametersRollingBearings.INNER_RACE_FAULT_TYPE_NAME);

            idxCentral = find(strcmp(...
                cellfun(@(m)m('Label'), maps, 'UniformOutput', false), ...
                expectedLabel), 1);

            bpfiMap = maps{idxCentral};
            bands = bpfiMap('Bands');
        
            % checks
            testCase.verifyEqual(...
                bands.Center, expectedCenterBand, 'AbsTol', 1e-12);
            testCase.verifyEqual(...
                bands.Surround, expectedSurroundBand, 'AbsTol', 1e-12);
        end
        
        % check bands of central freq for BSF
        function testBSFCenterAndSurroundBands(testCase)
            speed = 30;
            NB  = testCase.validBearingParams.numRollingElements;
            DB  = testCase.validBearingParams.ballDiameter;
            DP  = testCase.validBearingParams.pitchDiameter;
            phi = testCase.validBearingParams.contactAngle;
            expectedLabel = ['1' BearingFrequencyBands.BSF_CODE]; 
        
            % Expected center band
            widthCenter = testCase.validSfrfsParams.ball.sigmaCenter(1);
            [FBcenter, info] = bearingFaultBands(...
                speed, NB, DB, DP, phi, ...
                'Width', widthCenter);
            idxCenter = find(strcmp(info.Labels, expectedLabel), 1);
            expectedCenterBand = FBcenter(idxCenter,:);
        
            % Expected surround band
            widthSurround = ...
                testCase.validSfrfsParams.ball.sigmaSurround(1);
            FBsurround = bearingFaultBands(speed, NB, DB, DP, phi, ...
                                           'Width', widthSurround);
            expectedSurroundBand = FBsurround(idxCenter,:);
        
            % Actual maps from class (find central matching label)
            rs = testCase.bfb.computeForSpeed(speed);

            maps = rs.(...
                SFRFsParametersRollingBearings.BALL_FAULT_TYPE_NAME);

            idxCentral = find(strcmp(...
                cellfun(@(m)m('Label'), maps, 'UniformOutput', false), ...
                expectedLabel), 1);

            bsfMap = maps{idxCentral};
            bands = bsfMap('Bands');
        
            % checks
            testCase.verifyEqual(...
                bands.Center, expectedCenterBand, 'AbsTol', 1e-12);
            testCase.verifyEqual(...
                bands.Surround, expectedSurroundBand, 'AbsTol', 1e-12);
        end
        
        % check bands of central freq for BSF
        function testFTFCenterAndSurroundBands(testCase)
            speed = 30;
            NB  = testCase.validBearingParams.numRollingElements;
            DB  = testCase.validBearingParams.ballDiameter;
            DP  = testCase.validBearingParams.pitchDiameter;
            phi = testCase.validBearingParams.contactAngle;
            expectedLabel = ['1' BearingFrequencyBands.FTF_CODE];
        
            % expected center band
            widthCenter = testCase.validSfrfsParams.cage.sigmaCenter(1);
            [FBcenter, info] = bearingFaultBands(speed, NB, DB, DP, phi, ...
                                                 'Width', widthCenter);
            idxCenter = find(strcmp(info.Labels, expectedLabel), 1);
            expectedCenterBand = FBcenter(idxCenter,:);
        
            % expected surround band
            widthSurround = ...
                testCase.validSfrfsParams.cage.sigmaSurround(1);
            FBsurround = bearingFaultBands(speed, NB, DB, DP, phi, ...
                'Width', widthSurround);
            expectedSurroundBand = FBsurround(idxCenter,:);

            % actual maps from class
            % No sidebands for cage freq, safe to take first element
            rs = testCase.bfb.computeForSpeed(speed);
            ftfMap = rs.(...
                SFRFsParametersRollingBearings.CAGE_FAULT_TYPE_NAME){1};
            bands = ftfMap('Bands');

            % checks
            testCase.verifyEqual(...
                bands.Center, expectedCenterBand, 'AbsTol', 1e-12);
            testCase.verifyEqual(...
                bands.Surround, expectedSurroundBand, 'AbsTol', 1e-12);
        end

        function testReceptiveFieldBandsAlwaysCell(testCase)
            % Force edge case that previously broke the structure
            sharedParams = ...
                SFRFsParametersRollingBearings.createSFRFsParameters( ...
                'order',           0, ...
                'numSidebands',    0, ...
                'numHarmonics',    10, ...
                'sigmaCenter',     [4, 1], ...
                'sigmaSurround',   [12, 1], ...
                'inhibitionFactor', 0.5 );

            sfrfsParams = SFRFsParametersRollingBearings( ...
                SameForAllFaultTypes = sharedParams );

            bfbLocal = BearingFrequencyBands( ...
                bearingParams = testCase.validBearingParams, ...
                sfrfsParams = sfrfsParams, ...
                operatingConditions = testCase.validOperatingConditions );

            bfbLocal.computeBands();
            tbl = bfbLocal.bandsTable;

            % Every entry must be a scalar cell containing a cell array of 
            % Maps
            for i = 1:height(tbl)
                bands = tbl.ReceptiveFieldBands{i};

                % Must be a cell array
                testCase.verifyClass(bands, 'cell', ...
                    'ReceptiveFieldBands must always be a cell array');

                % Every cell must contain a containers.Map
                testCase.verifyTrue(all( ...
                    cellfun(@(x) isa(x,'containers.Map'), bands)), ...
                    'Each band must be a containers.Map');
            end
        end


    end
end
