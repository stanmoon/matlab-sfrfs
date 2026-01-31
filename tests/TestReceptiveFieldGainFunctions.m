classdef TestReceptiveFieldGainFunctions < matlab.unittest.TestCase
    % Test suite for ReceptiveFieldGainFunctions class.
    %
    % Covers:
    % - Valid construction with a BearingFrequencyBands instance
    % - computeGainFunctions output correctness and property update
    % - Frequency mask fields presence and size (center/surround/contrast)
    % - Contrast mask definition: center - k * surround
    % - Error handling for empty frequencyDomain input

    properties
        bfb                 % BearingFrequencyBands instance
        rfgf                % ReceptiveFieldGainFunctions instance
        frequencyDomain     % Frequency axis
    end

    methods (TestMethodSetup)
        function createValidObjects(testCase)
            bearingParams = ParametersRollingBearings( ...
                'NumRollingElements', 8, ...
                'BallDiameter', 7.92, ...
                'PitchDiameter', 34.55, ...
                'ContactAngle', 0);

            centerMask = GaussianMaskParameters( ...
                'bandwidth', 4, ...
                'sigmaRule', 1);

            surroundMask = GaussianMaskParameters( ...
                'bandwidth', 12, ...
                'sigmaRule', 0.9);

            sharedParams = SFRFsParameters.buildSFRFsParameters( ...
                'order', 1, ...
                'numSidebands', 2, ...
                'numHarmonics', 10, ...
                'centerMask', centerMask, ...
                'surroundMask', surroundMask, ...
                'inhibitionFactor', 0.8);

            sfrfsParams = SFRFsParametersRollingBearings( ...
                'SameForAllFaultTypes', sharedParams);

            speed = [35; 37.5; 40];
            load  = [12; 11; 10];
            oc = OperatingConditions(speed, load);

            testCase.bfb = BearingFrequencyBands( ...
                bearingParams = bearingParams, ...
                sfrfsParams = sfrfsParams, ...
                operatingConditions = oc);
            testCase.bfb.computeBands();

            testCase.rfgf = ReceptiveFieldGainFunctions(testCase.bfb);

            snapshotParams = ParametersSnapshot( ...
                'samplingFrequency', 25600, ...
                'duration', 1.28, ...
                'stride', 60);
            testCase.frequencyDomain = snapshotParams.getFrequencyDomain();
        end
    end

    methods (Test)
        function testValidConstruction(testCase)
            testCase.verifyInstanceOf( ...
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

            testCase.verifyEqual( ...
                numel(gf.frequencyDomain), ...
                numel(testCase.frequencyDomain));

            import tables.GainFunctionsTableSchema
            kMasksT = GainFunctionsTableSchema.FREQUENCYBANKMASKS;

            testCase.verifyTrue( ...
                any(strcmp( ...
                gf.gainFunctionsTable.Properties.VariableNames, kMasksT)));
        end

        function testFrequencyMasksFieldsAndSize(testCase)
            testCase.rfgf.computeGainFunctions(testCase.frequencyDomain);

            import tables.GainFunctionsTableSchema
            import tables.FaultBandsTableSchema
            import structs.FrequencyBankMasksSchema

            kMasksT  = GainFunctionsTableSchema.FREQUENCYBANKMASKS;
            kCenter  = FrequencyBankMasksSchema.CENTER;
            kSur     = FrequencyBankMasksSchema.SURROUND;
            kCon     = FrequencyBankMasksSchema.CONTRAST;

            kFaultGp = FaultBandsTableSchema.FAULTGROUP;

            tbl = testCase.rfgf.gainFunctionsTable;
            masks = tbl.(kMasksT);

            testCase.verifyTrue(iscell(masks));
            testCase.verifyTrue(all(~cellfun(@isempty, masks)));

            % Use the implementation's fault-group -> inhibitionFactor
            % mapping semantics, but validate the mask-level contract.
            sfrfsParams = testCase.bfb.sfrfsParams;

            for i = 1:numel(masks)
                maskStruct = masks{i};

                testCase.verifyTrue(isstruct(maskStruct));
                testCase.verifyTrue(isscalar(maskStruct));

                testCase.verifyTrue(isfield(maskStruct, kCenter));
                testCase.verifyTrue(isfield(maskStruct, kSur));
                testCase.verifyTrue(isfield(maskStruct, kCon));

                centerMask = maskStruct.(kCenter);
                surroundMask = maskStruct.(kSur);
                contrastMask = maskStruct.(kCon);

                n = numel(testCase.frequencyDomain);

                testCase.verifyEqual(numel(centerMask), n);
                testCase.verifyEqual(numel(surroundMask), n);
                testCase.verifyEqual(numel(contrastMask), n);

                % Verify contrast definition: center - k * surround
                faultGroup = tbl.(kFaultGp)(i);
                faultType = testCase.bfb.faultGroupToTypeName(faultGroup);
                k = sfrfsParams.(faultType).inhibitionFactor;

                expectedContrast = centerMask - k * surroundMask;

                % Numeric tolerance: should be exactly equal in practice,
                % but keep a tiny tolerance to avoid pointless failures.
                testCase.verifyEqual( ...
                    contrastMask, expectedContrast, ...
                    'AbsTol', 1e-12, ...
                    'Contrast mask mismatch.');
            end
        end

        function testEmptyFrequencyDomainError(testCase)
            f = @() testCase.rfgf.computeGainFunctions([]);

            testCase.verifyError(f, ...
                ['sfrfs:ReceptiveFieldGainFunctions:' ...
                 'computeGainFunctions:EmptyFrequencyDomain']);
        end

        function testComputeGainFunctionsWithZeroSidebands(testCase)
            bearingParams = testCase.bfb.bearingParams;

            centerMask = GaussianMaskParameters( ...
                'bandwidth', 4, ...
                'sigmaRule', 1);

            surroundMask = GaussianMaskParameters( ...
                'bandwidth', 12, ...
                'sigmaRule', 0.9);

            sharedParams = SFRFsParameters.buildSFRFsParameters( ...
                'order', 1, ...
                'numSidebands', 0, ...
                'numHarmonics', 10, ...
                'centerMask', centerMask, ...
                'surroundMask', surroundMask, ...
                'inhibitionFactor', 0.8);

            sfrfsParams = SFRFsParametersRollingBearings( ...
                'SameForAllFaultTypes', sharedParams);

            oc = testCase.bfb.operatingConditions;

            bfbZero = BearingFrequencyBands( ...
                bearingParams = bearingParams, ...
                sfrfsParams = sfrfsParams, ...
                operatingConditions = oc);
            bfbZero.computeBands();

            import tables.FaultBandsTableSchema
            kRfbT = FaultBandsTableSchema.RECEPTIVEFIELDBANDS;
            testCase.verifyTrue( ...
                any(strcmp(bfbZero.bandsTable.Properties.VariableNames, ...
                kRfbT)));

            rfgfZero = ReceptiveFieldGainFunctions(bfbZero);

            rfgfZero.computeGainFunctions(testCase.frequencyDomain);

            tbl = rfgfZero.gainFunctionsTable;
            testCase.verifyClass(tbl, 'table');
            testCase.verifyGreaterThan(height(tbl), 0);

            import tables.GainFunctionsTableSchema
            import tables.FaultBandsTableSchema
            import structs.FrequencyBankMasksSchema

            kMasksT  = GainFunctionsTableSchema.FREQUENCYBANKMASKS;
            kCenter  = FrequencyBankMasksSchema.CENTER;
            kSur     = FrequencyBankMasksSchema.SURROUND;
            kCon     = FrequencyBankMasksSchema.CONTRAST;

            kFaultGp = FaultBandsTableSchema.FAULTGROUP;

            testCase.verifyTrue( ...
                any(strcmp(tbl.Properties.VariableNames, kMasksT)));

            masks = tbl.(kMasksT);

            testCase.verifyTrue(iscell(masks));
            testCase.verifyTrue(all(~cellfun(@isempty, masks)));

            sfrfsParamsZero = bfbZero.sfrfsParams;

            for i = 1:numel(masks)
                maskStruct = masks{i};

                testCase.verifyTrue(isstruct(maskStruct));
                testCase.verifyTrue(isscalar(maskStruct));

                testCase.verifyTrue(isfield(maskStruct, kCenter));
                testCase.verifyTrue(isfield(maskStruct, kSur));
                testCase.verifyTrue(isfield(maskStruct, kCon));

                centerMask = maskStruct.(kCenter);
                surroundMask = maskStruct.(kSur);
                contrastMask = maskStruct.(kCon);

                n = numel(testCase.frequencyDomain);

                testCase.verifyEqual(numel(centerMask), n);
                testCase.verifyEqual(numel(surroundMask), n);
                testCase.verifyEqual(numel(contrastMask), n);

                faultGroup = tbl.(kFaultGp)(i);
                faultType = bfbZero.faultGroupToTypeName(faultGroup);
                k = sfrfsParamsZero.(faultType).inhibitionFactor;

                expectedContrast = centerMask - k * surroundMask;

                testCase.verifyEqual( ...
                    contrastMask, expectedContrast, ...
                    'AbsTol', 1e-12, ...
                    'Contrast mask mismatch (zero sidebands).');
            end
        end
    end
end
