classdef TestFaultFrequencyBands < matlab.unittest.TestCase
    properties
        faultBandsTable
    end
    
    methods (TestMethodSetup)
        function setupOnce(testCase)
            % Create valid bearing parameters and SFRF params
            bearingParams = ParametersRollingBearings( ...
                'NumRollingElements',8, ...
                'BallDiameter',7.92, ...
                'PitchDiameter',34.55, ...
                'ContactAngle',0);

            sharedParams = ...
                SFRFsParameters.createSFRFsParameters(...
                'order', 3, ...
                'numSidebands', 4, ...
                'numHarmonics', 8, ...
                'sigmaCenter', [5, 7], ...
                'sigmaSurround', [12, 3], ...
                'inhibitionFactor', 0.6);
        
            sfrfsParams = SFRFsParametersRollingBearings( ...
                'SameForAllFaultTypes', sharedParams);

            speed = [35; 37.5; 40];
            load  = [12; 11; 10];
            oc = OperatingConditions(speed, load);
            
            % Assemble BearingFrequencyBands instance
            bfb = ...
                BearingFrequencyBands(...
                bearingParams = bearingParams, ... 
                sfrfsParams = sfrfsParams,...
                operatingConditions = oc);

            bfb.computeBands();
            testCase.faultBandsTable = bfb.bandsTable;
        end
    end
    
    methods (Test)
        function testNormalCase(testCase)
            bands = FaultFrequencyBands.extractBands(...
                testCase.faultBandsTable, 2);
            testCase.verifyTrue(isstruct(bands));
            testCase.verifyGreaterThan(bands.NumberOfBands, 0);
            testCase.verifySize(bands.CenterBandsMatrix, ...
                [bands.NumberOfBands, 4]);
            testCase.verifySize(bands.SurroundBandsMatrix, ...
                [bands.NumberOfBands, 4]);
        end
        
        function testOutOfBounds(testCase)
            fbt = testCase.faultBandsTable;
            testCase.verifyError(@() FaultFrequencyBands.extractBands(...
                fbt, height(fbt)+1), ...
                'sfrfs:extractBands:Badsubscript');
        end
        
        function testEmptyBands(testCase)
            fbt = testCase.faultBandsTable(1,:);
            fbt.ReceptiveFieldBands{1} = {};
            bands = FaultFrequencyBands.extractBands(fbt, 1);
            testCase.verifyEqual(bands.NumberOfBands, 0);
            testCase.verifyEmpty(bands.CenterBandsMatrix);
            testCase.verifyEmpty(bands.SurroundBandsMatrix);
        end

        function testScalarMapIsHandled(testCase)
            fbt = testCase.faultBandsTable(1,:);

            % Force a scalar containers.Map instead of a cell
            fbt.ReceptiveFieldBands{1} = fbt.ReceptiveFieldBands{1}{1};

            bands = FaultFrequencyBands.extractBands(fbt, 1);

            testCase.verifyGreaterThanOrEqual(bands.NumberOfBands, 1);
            testCase.verifySize(bands.CenterBandsMatrix, ...
                [bands.NumberOfBands, 4]);
            testCase.verifySize(bands.SurroundBandsMatrix, ...
                [bands.NumberOfBands, 4]);
        end

        function testNestedCellIsRejected(testCase)
            fbt = testCase.faultBandsTable(1,:);

            % Force illegal nested cell: {{map1, map2, ...}}
            original = fbt.ReceptiveFieldBands{1};
            fbt.ReceptiveFieldBands{1} = {original};

            testCase.verifyError( ...
                @() FaultFrequencyBands.extractBands(fbt, 1), ...
                'sfrfs:extractBands:InvalidBandContainer');
        end

    end
end
