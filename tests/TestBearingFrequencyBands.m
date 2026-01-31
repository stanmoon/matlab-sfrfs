classdef TestBearingFrequencyBands < matlab.unittest.TestCase
    % Test suite for the BearingFrequencyBands class.
    %
    % Covers:
    % - Valid construction with required arguments
    % - Constructor type validation errors
    % - computeForSpeed output structure correctness
    % - computeBands output table integrity and descriptions
    % - Band computation correctness vs bearingFaultBands
    % - Sideband center correctness
    % - ReceptiveFieldBands storage invariants

    properties
        validOperatingConditions
        validBearingParams
        validSfrfsParams
        bfb
    end

    methods (TestMethodSetup)
        function createValidObjects(testCase)
            testCase.validBearingParams = ParametersRollingBearings( ...
                'numRollingElements', 8, ...
                'ballDiameter', 7.92, ...
                'pitchDiameter', 34.55, ...
                'contactAngle', 0);

            sharedParams = ...
                SFRFsParametersRollingBearings.buildSFRFsParameters( ...
                'order', 3, ...
                'numSidebands', 2, ...
                'numHarmonics', 3, ...
                'centerMask', GaussianMaskParameters( ...
                    'bandwidth', 5, 'sigmaRule', 7), ...
                'surroundMask', GaussianMaskParameters( ...
                    'bandwidth', 12, 'sigmaRule', 3), ...
                'inhibitionFactor', 0.5);

            testCase.validSfrfsParams = SFRFsParametersRollingBearings( ...
                'SameForAllFaultTypes', sharedParams);

            speed = [35; 37.5; 40];
            load  = [12; 11; 10];
            testCase.validOperatingConditions = ...
                OperatingConditions(speed, load);

            testCase.bfb = BearingFrequencyBands( ...
                bearingParams = testCase.validBearingParams, ...
                sfrfsParams = testCase.validSfrfsParams, ...
                operatingConditions = testCase.validOperatingConditions);
        end
    end

    methods (Test)
        function testValidConstruction(testCase)
            testCase.verifyInstanceOf(testCase.bfb, ...
                'BearingFrequencyBands');
            testCase.verifyEqual(testCase.bfb.bearingParams, ...
                testCase.validBearingParams);
            testCase.verifyEqual(testCase.bfb.sfrfsParams, ...
                testCase.validSfrfsParams);
        end

        function testInvalidBearingParamsType(testCase)
            f = @() BearingFrequencyBands( ...
                bearingParams = 'invalid', ...
                sfrfsParams = testCase.validSfrfsParams, ...
                operatingConditions = testCase.validOperatingConditions);

            testCase.verifyError(f, 'MATLAB:validation:UnableToConvert');
        end

        function testInvalidSfrfsParamsType(testCase)
            f = @() BearingFrequencyBands( ...
                bearingParams = testCase.validBearingParams, ...
                sfrfsParams = [], ...
                operatingConditions = testCase.validOperatingConditions);

            testCase.verifyError(f, 'MATLAB:validation:UnableToConvert');
        end

        function testInvalidOperatingConditions(testCase)
            f = @() BearingFrequencyBands( ...
                bearingParams = testCase.validBearingParams, ...
                sfrfsParams = testCase.validSfrfsParams, ...
                operatingConditions = {});

            testCase.verifyError(f, 'MATLAB:validation:UnableToConvert');
        end

        function testMissingBearingParamsArgument(testCase)
            f = @() BearingFrequencyBands( ...
                sfrfsParams = testCase.validSfrfsParams, ...
                operatingConditions = testCase.validOperatingConditions);

            testCase.verifyError(f, 'MATLAB:nonExistentField');
        end

        function testMissingSfrfsParamsArgument(testCase)
            f = @() BearingFrequencyBands( ...
                bearingParams = testCase.validBearingParams, ...
                operatingConditions = testCase.validOperatingConditions);

            testCase.verifyError(f, 'MATLAB:nonExistentField');
        end

        function testMissingOperatingConditionsArgument(testCase)
            f = @() BearingFrequencyBands( ...
                bearingParams = testCase.validBearingParams, ...
                sfrfsParams = testCase.validSfrfsParams);

            testCase.verifyError(f, 'MATLAB:nonExistentField');
        end

        function testComputeForSpeedKeysAndTypes(testCase)
            result = testCase.bfb.computeForSpeed(30);
            ftNames = SFRFsParametersRollingBearings.faultTypes;

            testCase.verifyEqual(sort(fieldnames(result)), sort(ftNames)');

            import dicts.BandMapSchema

            kBands = BandMapSchema.BANDS;
            kHar   = BandMapSchema.HARMONIC;
            kLbl   = BandMapSchema.LABEL;
            kSide  = BandMapSchema.SIDEBAND;

            for f = ftNames
                val = result.(f{1});

                testCase.verifyClass(val, 'cell');
                testCase.verifyGreaterThan(numel(val), 0);

                testCase.verifyClass(val{1}, 'containers.Map');
                m = val{1};

                testCase.verifyTrue(isKey(m, kBands));
                testCase.verifyTrue(isKey(m, kHar));
                testCase.verifyTrue(isKey(m, kLbl));
                testCase.verifyTrue(isKey(m, kSide));
            end
        end

        function testDescriptionsInAnswer(testCase)
            testCase.bfb.computeBands();

            import tables.FaultBandsTableSchema
            import tables.OperatingConditionsTableSchema

            ocTable = testCase.validOperatingConditions.conditionsTable;
            tbl = testCase.bfb.bandsTable;

            expectedRows = height(ocTable) * ...
                numel(SFRFsParametersRollingBearings.faultTypes);

            testCase.verifyEqual(height(tbl), expectedRows);

            kFaultGroupT = FaultBandsTableSchema.FAULTGROUP;
            kDescT       = FaultBandsTableSchema.DESCRIPTION;

            for idx = 1:expectedRows
                fg = tbl{idx, kFaultGroupT};
                ftName = BearingFrequencyBands.faultGroupToTypeName(fg);

                expectedDesc = ...
                    BearingFrequencyBands.faultTypeDescriptions(ftName);

                actualDesc = string(tbl{idx, kDescT});

                testCase.verifyEqual(actualDesc, expectedDesc);
            end
        end

        function testBPFOcentralFreqFromMaps(testCase)
            testCase.verifyCentralFreqMatchesPdM( ...
                30, BearingFrequencyBands.BPFO_CODE, ...
                SFRFsParametersRollingBearings.OUTER_RACE_FAULT_TYPE_NAME);
        end

        function testBPFIcentralFreqFromMaps(testCase)
            testCase.verifyCentralFreqMatchesPdM( ...
                30, BearingFrequencyBands.BPFI_CODE, ...
                SFRFsParametersRollingBearings.INNER_RACE_FAULT_TYPE_NAME);
        end

        function testBSFcentralFreqFromMaps(testCase)
            testCase.verifyCentralFreqMatchesPdM( ...
                30, BearingFrequencyBands.BSF_CODE, ...
                SFRFsParametersRollingBearings.BALL_FAULT_TYPE_NAME);
        end

        function testFTFcentralFreqFromMaps(testCase)
            testCase.verifyCentralFreqMatchesPdM( ...
                30, BearingFrequencyBands.FTF_CODE, ...
                SFRFsParametersRollingBearings.CAGE_FAULT_TYPE_NAME);
        end

        function testBPFOCenterAndSurroundBands(testCase)
            testCase.verifyBandsMatchPdM( ...
                30, BearingFrequencyBands.BPFO_CODE, ...
                SFRFsParametersRollingBearings.OUTER_RACE_FAULT_TYPE_NAME, ...
                testCase.validSfrfsParams.outerRace);
        end

        function testBPFICenterAndSurroundBands(testCase)
            testCase.verifyBandsMatchPdM( ...
                30, BearingFrequencyBands.BPFI_CODE, ...
                SFRFsParametersRollingBearings.INNER_RACE_FAULT_TYPE_NAME, ...
                testCase.validSfrfsParams.innerRace);
        end

        function testBSFCenterAndSurroundBands(testCase)
            testCase.verifyBandsMatchPdM( ...
                30, BearingFrequencyBands.BSF_CODE, ...
                SFRFsParametersRollingBearings.BALL_FAULT_TYPE_NAME, ...
                testCase.validSfrfsParams.ball);
        end

        function testFTFCenterAndSurroundBands(testCase)
            testCase.verifyBandsMatchPdM( ...
                30, BearingFrequencyBands.FTF_CODE, ...
                SFRFsParametersRollingBearings.CAGE_FAULT_TYPE_NAME, ...
                testCase.validSfrfsParams.cage);
        end

        function testBSFSidebandCentersUseCageFrequency(testCase)
            speed = 30;

            rs = testCase.bfb.computeForSpeed(speed);
            maps = rs.(SFRFsParametersRollingBearings.BALL_FAULT_TYPE_NAME);

            expectedLabel = [ ...
                '1' BearingFrequencyBands.BSF_CODE ...
                '+1' BearingFrequencyBands.FTF_CODE];

            m = testCase.findMapByLabel(maps, expectedLabel);
            testCase.verifyNotEmpty(m);

            f_bsf = testCase.bfb.getCentralFrequency( ...
                BearingFrequencyBands.BSF_CODE, speed);
            f_ftf = testCase.bfb.getCentralFrequency( ...
                BearingFrequencyBands.FTF_CODE, speed);

            expectedCenter = f_bsf + f_ftf;

            import dicts.BandMapSchema
            import structs.OpponentBandsSchema

            kBands = BandMapSchema.BANDS;
            kCenterBand = OpponentBandsSchema.CENTER;

            actualCenter = mean(m(kBands).(kCenterBand));

            testCase.verifyEqual(actualCenter, expectedCenter, ...
                'AbsTol', 1e-12);
        end

        function testBPFISidebandCentersUseShaftFrequency(testCase)
            speed = 30;

            rs = testCase.bfb.computeForSpeed(speed);
            maps = rs.( ...
                SFRFsParametersRollingBearings.INNER_RACE_FAULT_TYPE_NAME);

            f_bpfi = testCase.bfb.getCentralFrequency( ...
                BearingFrequencyBands.BPFI_CODE, speed);
            f_fr = speed;

            expectedLabelP = [ ...
                '1' BearingFrequencyBands.BPFI_CODE ...
                '+1' BearingFrequencyBands.FR_CODE];

            expectedLabelM = [ ...
                '1' BearingFrequencyBands.BPFI_CODE ...
                '-1' BearingFrequencyBands.FR_CODE];

            mP = testCase.findMapByLabel(maps, expectedLabelP);
            mM = testCase.findMapByLabel(maps, expectedLabelM);

            testCase.verifyNotEmpty(mP);
            testCase.verifyNotEmpty(mM);

            import dicts.BandMapSchema
            import structs.OpponentBandsSchema

            kBands = BandMapSchema.BANDS;
            kCenterBand = OpponentBandsSchema.CENTER;

            expectedCenterP = f_bpfi + f_fr;
            expectedCenterM = f_bpfi - f_fr;

            actualCenterP = mean(mP(kBands).(kCenterBand));
            actualCenterM = mean(mM(kBands).(kCenterBand));

            testCase.verifyEqual(actualCenterP, expectedCenterP, ...
                'AbsTol', 1e-12);
            testCase.verifyEqual(actualCenterM, expectedCenterM, ...
                'AbsTol', 1e-12);
        end

        function testReceptiveFieldBandsAlwaysCell(testCase)
            sharedParams = ...
                SFRFsParametersRollingBearings.buildSFRFsParameters( ...
                'order', 0, ...
                'numSidebands', 0, ...
                'numHarmonics', 10, ...
                'centerMask', GaussianMaskParameters( ...
                    'bandwidth', 4, 'sigmaRule', 1), ...
                'surroundMask', GaussianMaskParameters( ...
                    'bandwidth', 12, 'sigmaRule', 1), ...
                'inhibitionFactor', 0.5);

            sfrfsParams = SFRFsParametersRollingBearings( ...
                SameForAllFaultTypes = sharedParams);

            bfbLocal = BearingFrequencyBands( ...
                bearingParams = testCase.validBearingParams, ...
                sfrfsParams = sfrfsParams, ...
                operatingConditions = testCase.validOperatingConditions);

            bfbLocal.computeBands();
            tbl = bfbLocal.bandsTable;

            import tables.FaultBandsTableSchema
            kRfbT = FaultBandsTableSchema.RECEPTIVEFIELDBANDS;

            for i = 1:height(tbl)
                bands = tbl{i, kRfbT};

                testCase.verifyClass(bands, 'cell');

                % Stored as a scalar cell wrapping the vector of maps
                % (as per computeBands contract)
                testCase.verifyTrue(isscalar(bands));

                maps = bands{1};
                testCase.verifyClass(maps, 'cell');
                testCase.verifyTrue(all(cellfun(@(x) ...
                    isa(x, 'containers.Map'), maps)));
            end
        end
    end

    methods (Access = private)
        function verifyCentralFreqMatchesPdM( ...
                testCase, speed, centralCode, faultTypeName)

            [NB, DB, DP, phiDeg] = testCase.getPdMInputs();

            [~, info] = bearingFaultBands(speed, NB, DB, DP, phiDeg);

            expectedLabel = ['1' centralCode];
            idx = find(strcmp(info.Labels, expectedLabel), 1);
            testCase.verifyNotEmpty(idx);

            expected = info.Centers(idx);

            rs = testCase.bfb.computeForSpeed(speed);
            maps = rs.(faultTypeName);

            m = testCase.findMapByLabel(maps, expectedLabel);
            testCase.verifyNotEmpty(m);

            import dicts.BandMapSchema
            import structs.OpponentBandsSchema

            kBands = BandMapSchema.BANDS;
            kLbl   = BandMapSchema.LABEL;
            kCenterBand = OpponentBandsSchema.CENTER;

            testCase.verifyEqual(m(kLbl), expectedLabel);

            centralFreqFromMap = mean(m(kBands).(kCenterBand));

            testCase.verifyEqual(centralFreqFromMap, expected, ...
                'AbsTol', 1e-12);
        end

        function verifyBandsMatchPdM( ...
                testCase, speed, centralCode, faultTypeName, paramsForType)

            [NB, DB, DP, phiDeg] = testCase.getPdMInputs();

            expectedLabel = ['1' centralCode];

            widthCenter = paramsForType.centerMask.bandwidth;
            [FBcenter, info] = bearingFaultBands( ...
                speed, NB, DB, DP, phiDeg, 'Width', widthCenter);
            idx = find(strcmp(info.Labels, expectedLabel), 1);
            testCase.verifyNotEmpty(idx);
            expectedCenterBand = FBcenter(idx, :);

            widthSurround = paramsForType.surroundMask.bandwidth;
            FBsurround = bearingFaultBands( ...
                speed, NB, DB, DP, phiDeg, 'Width', widthSurround);
            expectedSurroundBand = FBsurround(idx, :);

            rs = testCase.bfb.computeForSpeed(speed);
            maps = rs.(faultTypeName);

            m = testCase.findMapByLabel(maps, expectedLabel);
            testCase.verifyNotEmpty(m);

            import dicts.BandMapSchema
            import structs.OpponentBandsSchema

            kBands = BandMapSchema.BANDS;
            kCenterBand = OpponentBandsSchema.CENTER;
            kSurBand = OpponentBandsSchema.SURROUND;

            bands = m(kBands);

            testCase.verifyEqual( ...
                bands.(kCenterBand), expectedCenterBand, 'AbsTol', 1e-12);
            testCase.verifyEqual( ...
                bands.(kSurBand), expectedSurroundBand, 'AbsTol', 1e-12);
        end

        function m = findMapByLabel(~, maps, expectedLabel)
            
            import dicts.BandMapSchema
            kLbl = BandMapSchema.LABEL;

            labels = cellfun(@(x) x(kLbl), maps, 'UniformOutput', false);
            idx = find(strcmp(labels, expectedLabel), 1);

            if isempty(idx)
                m = [];
            else
                m = maps{idx};
            end
        end

        function [NB, DB, DP, phiDeg] = getPdMInputs(testCase)
            NB = testCase.validBearingParams.numRollingElements;
            DB = testCase.validBearingParams.ballDiameter;
            DP = testCase.validBearingParams.pitchDiameter;

            % PdM bearingFaultBands expects degrees
            phiDeg = testCase.validBearingParams.contactAngle;
        end
    end
end
