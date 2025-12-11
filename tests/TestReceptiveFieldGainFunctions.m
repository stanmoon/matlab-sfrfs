classdef TestReceptiveFieldGainFunctions < matlab.unittest.TestCase
    % Test suite for ReceptiveFieldGainFunctions class.
    %
    % Covers:
    % - Valid construction with a BearingFrequencyBands instance
    % - computeGainFunctions output correctness and property update
    % - Frequency mask fields presence and size
    % - Error handling for empty frequencyDomain input
    
    properties
        bfb                 % BearingFrequencyBands instance
        rfgf                % ReceptiveFieldGainFunctions instance
        frequencyDomain     % Frequency axis
    end
    
    methods (TestMethodSetup)
        function createValidObjects(testCase)
            % Create valid bearing parameters and SFRF params
            bearingParams = ParametersRollingBearings( ...
                'NumRollingElements',8, ...
                'BallDiameter',7.92, ...
                'PitchDiameter',34.55, ...
                'ContactAngle',0);

            sharedParams = ...
                SFRFsParameters.createSFRFsParameters(...
                'order', 1, ...
                'numSidebands', 2, ...
                'numHarmonics', 10, ...
                'sigmaCenter', [4, 1], ...
                'sigmaSurround', [12, 0.9], ...
                'inhibitionFactor', 0.8);
        
            sfrfsParams = SFRFsParametersRollingBearings( ...
                'SameForAllFaultTypes', sharedParams);

            speed = [35; 37.5; 40];
            load  = [12; 11; 10];
            oc = OperatingConditions(speed, load);
            
            % Assemble BearingFrequencyBands instance
            testCase.bfb = ...
                BearingFrequencyBands(...
                bearingParams = bearingParams, ... 
                sfrfsParams = sfrfsParams,...
                operatingConditions = oc);
            testCase.bfb.computeBands();
            
            % Create ReceptiveFieldGainFunctions instance
            testCase.rfgf = ReceptiveFieldGainFunctions(testCase.bfb);
            
            % Define frequency domain vector for tests
            snapshotParams = ParametersSnapshot( ...
                'samplingFrequency', 25600, ...
                'duration', 1.28, ...
                'stride', 60);
            testCase.frequencyDomain = snapshotParams.getFrequencyDomain();
        end
    end
    
    methods (Test)
        function testValidConstruction(testCase)
            testCase.verifyInstanceOf(...
                testCase.rfgf, 'ReceptiveFieldGainFunctions');
            testCase.verifyEqual( ...
                testCase.rfgf.frequencyBands, testCase.bfb);
            testCase.verifyEmpty( ...
                testCase.rfgf.gainFunctionsTable);
        end
        
        function testComputeGainFunctionsCreatesTable(testCase)
            gf = testCase.rfgf;
            gf.computeGainFunctions(testCase.frequencyDomain);
            testCase.verifyClass(gf.gainFunctionsTable, 'table');
            testCase.verifyEqual( ...
                height(gf.gainFunctionsTable), ...
                height(testCase.bfb.bandsTable));
            testCase.verifyTrue( ...
                any(strcmp('FrequencyBankMasks', ...
                gf.gainFunctionsTable.Properties.VariableNames)));
        end
        
        function testFrequencyMasksFieldsAndSize(testCase)
            testCase.rfgf.computeGainFunctions( ...
                testCase.frequencyDomain);
            masks = testCase.rfgf.gainFunctionsTable.FrequencyBankMasks;
            
            % Check that masks cell array is not empty and fields exist
            testCase.verifyTrue(all(~cellfun(@isempty, masks)));
            for i = 1:length(masks)
                maskStruct = masks{i};
                testCase.verifyTrue(isstruct(maskStruct));
                testCase.verifyTrue( ...
                    isfield(maskStruct, 'CenterFrequencyBankMask'));
                testCase.verifyTrue( ...
                    isfield(maskStruct, 'SurroundFrequencyBankMask'));

                % Each mask should match frequencyDomain length
                testCase.verifyEqual( ...
                    length(maskStruct.CenterFrequencyBankMask), ...
                    length(testCase.frequencyDomain));
                testCase.verifyEqual( ...
                    length(maskStruct.SurroundFrequencyBankMask), ...
                    length(testCase.frequencyDomain));
            end
        end

        function testEmptyFrequencyDomainError(testCase)
            f = @() testCase.rfgf.computeGainFunctions([]);

            testCase.verifyError(f, ...
                ['sfrfs:ReceptiveFieldGainFunctions:'...
                'computeGainFunctions:EmptyFrequencyDomain']);
        end

        function testComputeGainFunctionsWithZeroSidebands(testCase)

            % Rebuild sfrfs with zero sidebands
            bearingParams = testCase.bfb.bearingParams;

            sharedParams = ...
                SFRFsParameters.createSFRFsParameters(...
                'order', 1, ...
                'numSidebands', 0, ...   
                'numHarmonics', 10, ...
                'sigmaCenter', [4, 1], ...
                'sigmaSurround', [12, 0.9], ...
                'inhibitionFactor', 0.8);

            sfrfsParams = SFRFsParametersRollingBearings( ...
                'SameForAllFaultTypes', sharedParams);

            oc = testCase.bfb.operatingConditions;

            % Rebuild BFB with sidebands = 0
            bfbZero = BearingFrequencyBands( ...
                bearingParams = bearingParams, ...
                sfrfsParams = sfrfsParams, ...
                operatingConditions = oc);

            bfbZero.computeBands();

            % Rebuild rfgf
            rfgfZero = ReceptiveFieldGainFunctions(bfbZero);

            % Should not throw
            rfgfZero.computeGainFunctions(testCase.frequencyDomain);

            % Structural checks
            tbl = rfgfZero.gainFunctionsTable;

            testCase.verifyClass(tbl, 'table');
            testCase.verifyGreaterThan(height(tbl), 0)

            masks = tbl.FrequencyBankMasks;

            testCase.verifyTrue(all(iscell(masks)))
            testCase.verifyTrue(all(~cellfun(@isempty, masks)))

            for i = 1:length(masks)
                maskStruct = masks{i};
                testCase.verifyTrue(isstruct(maskStruct))
                testCase.verifyTrue(...
                    isfield(maskStruct,'CenterFrequencyBankMask'))
            end
        end
    end
end
