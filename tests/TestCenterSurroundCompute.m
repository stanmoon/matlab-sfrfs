classdef TestCenterSurroundCompute < matlab.unittest.TestCase
    % TestCenterSurroundCompute
    %
    % Unit tests for CenterSurroundCompute.

    methods (Test)
        function testComputeByRowProducesFiniteOutputs(tc)
            [sp, rfgfs, T, f] = tc.buildObjects();

            cs = CenterSurroundCompute( ...
                snapshotParameters = sp, ...
                rfgfs              = rfgfs);

            row = 1;

            [contrast, Rc, Rs, C, S, DoG] = cs.compute( ...
                memberTable    = T, ...
                spectralColumn = "FFT", ...
                row            = row);

            tc.verifyEqual(size(C), size(f));
            tc.verifyEqual(size(S), size(f));
            tc.verifyEqual(size(DoG), size(f));

            tc.verifySize(contrast, size(Rc));
            tc.verifySize(contrast, size(Rs));

            tc.verifyTrue(all(isfinite(C)));
            tc.verifyTrue(all(isfinite(S)));
            tc.verifyTrue(all(isfinite(DoG)));

            tc.verifyTrue(all(isfinite(Rc)));
            tc.verifyTrue(all(isfinite(Rs)));
            tc.verifyTrue(all(isfinite(contrast)));
        end

        function testComputeByFaultTypeSelectionIfAvailable(tc)
            [sp, rfgfs, T, ~] = tc.buildObjects();

            if ~isprop(rfgfs, "frequencyBands")
                tc.assumeFail("RFGFs fixture lacks frequencyBands.");
            end

            cs = CenterSurroundCompute( ...
                snapshotParameters = sp, ...
                rfgfs              = rfgfs);

            sel = OperatingConditionSelection( ...
                speed = 35, ...
                load  = 12);

            ft = tc.pickFaultTypeName(rfgfs);

            if strlength(ft) == 0
                tc.assumeFail("No faultType name available.");
            end

            [contrast, Rc, Rs] = cs.compute( ...
                memberTable    = T, ...
                spectralColumn = "FFT", ...
                faultType      = ft, ...
                selection      = sel);

            tc.verifySize(contrast, size(Rc));
            tc.verifySize(contrast, size(Rs));
            tc.verifyTrue(all(isfinite(contrast)));
        end
    end

    methods (Access = private)
        function [sp, rfgfs, T, f] = buildObjects(tc)

            sp = ParametersSnapshot( ...
                samplingFrequency = 25600, ...
                duration          = 1.28, ...
                stride            = 60);

            f = sp.getFrequencyDomain();

            bp = ParametersRollingBearings( ...
                numRollingElements = 8, ...
                ballDiameter       = 7.92, ...
                pitchDiameter      = 34.55, ...
                contactAngle       = 0);

            shared = SFRFsParameters.buildSFRFsParameters( ...
                order            = 0, ...
                numSidebands     = 2, ...
                numHarmonics     = 10, ...
                centerMask       = GaussianMaskParameters( ...
                    bandwidth = 4, ...
                    sigmaRule = 1.0253), ...
                surroundMask     = GaussianMaskParameters( ...
                    bandwidth = 12, ...
                    sigmaRule = 0.8905), ...
                inhibitionFactor = 0.8647);

            sfrfsParams = SFRFsParametersRollingBearings( ...
                SameForAllFaultTypes = shared);

            oc = OperatingConditions([35], [12]);

            bfb = BearingFrequencyBands( ...
                bearingParams       = bp, ...
                sfrfsParams         = sfrfsParams, ...
                operatingConditions = oc);

            bfb.computeBands();

            rfgfs = ReceptiveFieldGainFunctions(bfb);
            rfgfs.computeGainFunctions(f);

            T = tc.buildSyntheticMemberTable(f, 50);
        end

        function T = buildSyntheticMemberTable(~, f, n)
            nBins = numel(f);

            FFT = cell(n, 1);
            for i = 1:n
                x = abs(randn(nBins, 1));
                x = x + 0.05 * (f(:) / max(f));
                FFT{i} = x;
            end

            T = table((1:n).', FFT, ...
                VariableNames = ["SnapshotIndex", "FFT"]);
        end

        function ft = pickFaultTypeName(~, rfgfs)
            ft = "";

            fb = rfgfs.frequencyBands;
            if ~isprop(fb, "sfrfsParams")
                return;
            end

            sp = fb.sfrfsParams;

            if isa(sp, "SFRFsParametersRollingBearings")
                try
                    ft = SFRFsParametersRollingBearings. ...
                        OUTER_RACE_FAULT_TYPE_NAME;
                catch
                    ft = "";
                end
            end
        end
    end
end
