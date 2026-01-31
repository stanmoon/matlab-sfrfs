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

            centerSpec   = [5, 7];    % [bandwidth, sigmaRule]
            surroundSpec = [12, 3];   % [bandwidth, sigmaRule]

            centerMask = GaussianMaskParameters( ...
                'bandwidth', centerSpec(1), ...
                'sigmaRule', centerSpec(2));

            surroundMask = GaussianMaskParameters( ...
                'bandwidth', surroundSpec(1), ...
                'sigmaRule', surroundSpec(2));

            sharedParams = SFRFsParameters.buildSFRFsParameters( ...
                'order', 3, ...
                'numSidebands', 4, ...
                'numHarmonics', 8, ...
                'centerMask', centerMask, ...
                'surroundMask', surroundMask, ...
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
            import structs.FaultBandsExtractSchema

            bands = FaultFrequencyBands.extractBands( ...
                testCase.faultBandsTable, 2);

            testCase.verifyTrue(isstruct(bands));

            kN = FaultBandsExtractSchema.NUMBEROFBANDS;
            kCenter = FaultBandsExtractSchema.CENTERBANDSMATRIX;
            kSur = FaultBandsExtractSchema.SURROUNDBANDSMATRIX;

            testCase.verifyGreaterThan(bands.(kN), 0);
            testCase.verifySize(bands.(kCenter), [bands.(kN), 4]);
            testCase.verifySize(bands.(kSur), [bands.(kN), 4]);
        end

        function testOutOfBounds(testCase)
            fbt = testCase.faultBandsTable;

            testCase.verifyError(@() FaultFrequencyBands.extractBands( ...
                fbt, height(fbt) + 1), ...
                'sfrfs:extractBands:Badsubscript');
        end

        function testEmptyBandsHandled(testCase)
            % Empty set of maps for a row should yield N=0 and empty matrices.
            import tables.FaultBandsTableSchema
            import structs.FaultBandsExtractSchema

            kRfbT = FaultBandsTableSchema.RECEPTIVEFIELDBANDS;

            fbt = testCase.faultBandsTable(1, :);

            % Preserve the storage contract: scalar outer cell, inner cell array
            % of maps (here: empty).
            fbt{1, kRfbT} = {{}};

            bands = FaultFrequencyBands.extractBands(fbt, 1);

            kN = FaultBandsExtractSchema.NUMBEROFBANDS;
            kCenter = FaultBandsExtractSchema.CENTERBANDSMATRIX;
            kSur = FaultBandsExtractSchema.SURROUNDBANDSMATRIX;

            testCase.verifyEqual(bands.(kN), 0);
            testCase.verifyEmpty(bands.(kCenter));
            testCase.verifyEmpty(bands.(kSur));
        end

        function testScalarMapIsHandled(testCase)
            import tables.FaultBandsTableSchema
            import structs.FaultBandsExtractSchema

            kRfbT = FaultBandsTableSchema.RECEPTIVEFIELDBANDS;

            fbt = testCase.faultBandsTable(1, :);

            % Extract a single map from the usual nested storage 
            % {{mapsCell}}
            nested = fbt{1, kRfbT};     % expected: 1x1 cell
            oneMap = nested{1}{1};      % first containers.Map

            % Assign a scalar containers.Map into a single table cell
            fbt(1, kRfbT) = {oneMap};

            bands = FaultFrequencyBands.extractBands(fbt, 1);

            kN = FaultBandsExtractSchema.NUMBEROFBANDS;
            kCenter = FaultBandsExtractSchema.CENTERBANDSMATRIX;
            kSur = FaultBandsExtractSchema.SURROUNDBANDSMATRIX;

            testCase.verifyGreaterThanOrEqual(bands.(kN), 1);
            testCase.verifySize(bands.(kCenter), [bands.(kN), 4]);
            testCase.verifySize(bands.(kSur), [bands.(kN), 4]);
        end

        function testNestedOuterCellIsHandled(testCase)
            % The extractor explicitly supports the nested representation
            % produced by computeBands: {{mapsCell}}.
            import tables.FaultBandsTableSchema
            import structs.FaultBandsExtractSchema

            kRfbT = FaultBandsTableSchema.RECEPTIVEFIELDBANDS;

            fbt = testCase.faultBandsTable(1, :);

            % Ensure it's nested as {{mapsCell}}
            maps = fbt{1, kRfbT};
            testCase.verifyTrue(iscell(maps) && isscalar(maps));
            testCase.verifyTrue(iscell(maps{1}));

            bands = FaultFrequencyBands.extractBands(fbt, 1);

            kN = FaultBandsExtractSchema.NUMBEROFBANDS;
            testCase.verifyGreaterThanOrEqual(bands.(kN), 1);
        end

        function testNonMapCellRejected(testCase)
            % Cell arrays must contain containers.Map objects.
            import tables.FaultBandsTableSchema

            kRfbT = FaultBandsTableSchema.RECEPTIVEFIELDBANDS;

            fbt = testCase.faultBandsTable(1, :);

            % Make illegal content inside the inner maps-cell
            fbt{1, kRfbT} = {{42}};

            testCase.verifyError( ...
                @() FaultFrequencyBands.extractBands(fbt, 1), ...
                'sfrfs:extractBands:InvalidBandContainer');
        end
    end

end
