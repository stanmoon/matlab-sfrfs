classdef TestSFRFsCompute < matlab.unittest.TestCase
    properties
        x
        x_multi
        fs
        f
        operatingConditions     % Operating conditions
        bearingParams           % Bearing parameters
        sfrfsParams             % SFRF parameters
        frequencyBands          % Bearing Frequency Bands 
        rfgfs                   % Receptive Field Gain Functions 
        paramsSnapshot          % Parameters of Snapshot
        sfrfsCompute            % SFRFs Compute
    end
    
    methods (TestMethodSetup)
        function setupOnce(testCase)
            % Signal generation setup
            testCase.fs = 25.6e3;
            N = 32768;
            testCase.x = rand(N,1);
            testCase.x_multi = [ ...
                testCase.x, ...
                2*testCase.x, ...
                3*testCase.x, ...
                log(testCase.x + eps)];
            testCase.f = (0:N-1)' * (testCase.fs/N);
            
            % bearing parameters
            bp = ParametersRollingBearings( ...
                'NumRollingElements', 8, ...
                'BallDiameter', 7.92, ...
                'PitchDiameter', 34.55, ...
                'ContactAngle', 0);
            
            % SFRFs parameters
            sharedParams = SFRFsParameters.createSFRFsParameters( ...
                'order', 3, ...
                'numSidebands', 4, ...
                'numHarmonics', 8, ...
                'sigmaCenter', [5, 7], ...
                'sigmaSurround', [12, 3], ...
                'inhibitionFactor', 0.6);
            
            sp = SFRFsParametersRollingBearings( ...
                'SameForAllFaultTypes', sharedParams);
            
            % Operating conditions
            speed = [35; 37.5; 40];
            load = [12; 11; 10];
            oc = OperatingConditions(speed, load);

            testCase.operatingConditions = oc;
            testCase.bearingParams = bp;
            testCase.sfrfsParams = sp;
            
            % Create and compute fault bands for bearings
            bfb = BearingFrequencyBands( ...
                bearingParams = bp, ...
                sfrfsParams = sp, ...
                operatingConditions = oc);
            bfb.computeBands();

            testCase.frequencyBands = bfb;
            
            % Create ReceptiveFieldGainFunctions and compute gain masks
            gfs = ReceptiveFieldGainFunctions(testCase.frequencyBands);
            gfs.computeGainFunctions(testCase.f);
            testCase.rfgfs = gfs;
            
            % Create ParametersSnapshot (adjust constructor as needed)
            testCase.paramsSnapshot = ParametersSnapshot( ...
                'samplingFrequency', testCase.fs, ...
                'duration', N / testCase.fs, ...
                'stride', 1);
            
            % Initialize SFRFsCompute instance with named arguments
            testCase.sfrfsCompute = SFRFsCompute( ...
                snapshotParameters = testCase.paramsSnapshot, ...
                rfgfs = testCase.rfgfs);
        end
    end
    
    methods (Test)
        function testSingleSignalAgainstDoG(testCase)
            oc = testCase.operatingConditions.conditionsTable(1,:);
            k = testCase.sfrfsParams.outerRace.inhibitionFactor;
            
            responseTableNew = testCase.sfrfsCompute.compute(...
                operatingCondition = oc, temporalSnapshot = testCase.x);
            
            % Legacy computeDoGResponse assumed to accept these inputs
            responseTableDoG = TestSFRFsCompute.computeDoGResponse(...
                testCase.x, testCase.fs, ...
                testCase.rfgfs.gainFunctionsTable, ...
                'OperatingConditions', oc, ...
                'InhibitionFactor', k);
            
            actual = cell2mat(responseTableNew.SFRFs);
            expected = responseTableDoG.SFRF;
            
            testCase.verifyEqual(actual, expected, 'RelTol', 1e-10);
        end
        
        function testMultiSignalAgainstDoG(testCase)
            oc = testCase.operatingConditions.conditionsTable(1,:);
            k = testCase.sfrfsParams.outerRace.inhibitionFactor;
            responseTableNew = ...
                testCase.sfrfsCompute.compute(...
                temporalSnapshot = testCase.x_multi, ...
                operatingCondition = oc);
            newResp = cell2mat(responseTableNew.SFRFs);
            
            numFaults = length(BearingFrequencyBands.faultFrequencyCodes);
            legacyResp = zeros(numFaults, size(testCase.x_multi, 2));
            for j = 1:size(testCase.x_multi, 2)
                respLegacy = TestSFRFsCompute.computeDoGResponse(...
                    testCase.x_multi(:, j), ...
                    testCase.fs, testCase.rfgfs.gainFunctionsTable, ...
                    'OperatingConditions', oc, ...
                    'InhibitionFactor', k);
                legacyResp(:, j) = respLegacy.SFRF;
            end
            
            testCase.verifyEqual(newResp, legacyResp, 'RelTol', 1e-10);
        end
    end

    methods (Static)faultBandsTable
        % This is the reference implementation, we test against it
        function responseTable = computeDoGResponse(...
            x, fs, gainFunctionsTable, args)
        % COMPUTEDOGRESPONSE Compute center-surround (DoG) response for 
        %   operating conditions.
        %   responseTable = COMPUTEDOGRESPONSE(x, fs, faultBandsTable)
        %   computes the difference-of-Gaussians (DoG) response for all 
        %   operational conditions in faultBandsTable and returns a table 
        %   with the results.
        %
        %   responseTable = COMPUTEDOGRESPONSE(...
        %                 x, fs, gainFunctionsTable, ...
        %                 'OperatingConditions', oc, 'InhibitionFactor', k)
        %   computes the DoG response only for the specified operating 
        %   conditions and specifies the inhibition factor.
        %
        %   Optional name-value pairs:
        %       'OperatingConditions' - Table with columns matching those 
        %                               in faultBandsTable 
        %                               (e.g., 'Speed', 'Load'). 
        %                               If omitted, computes for all rows.
        %       'InhibitionFactor'    - Surround inhibition scale factor 
        %                               (default: 1/3)
        %
        
            arguments
                x (:,1) double
                fs (1,1) double {mustBePositive}
                gainFunctionsTable table
                args.OperatingConditions table = table()
                args.InhibitionFactor (1,1) double = 1/3
            end
        
            operatingConditions = args.OperatingConditions;
            k = args.InhibitionFactor;
        
            opCondVars = operatingConditions.Properties.VariableNames;
        
            if isempty(operatingConditions)
                idxToUse = 1:height(gainFunctionsTable);
                condTable = gainFunctionsTable;
            else
                % Use only those columns from faultBandsTable for matching
                mask = ismember(...
                    gainFunctionsTable(:, ...
                    opCondVars), operatingConditions);
                idxToUse = find(mask);  % All indices where any row matches
                if isempty(idxToUse)
                    error('sfrfs:computeDoGResponse:Nomatch', ...
                        'No matching operating condition found.');
                end
                condTable = gainFunctionsTable(idxToUse,:);
            end
        
            responseRFV = zeros(numel(idxToUse),1);
            for n = 1:numel(idxToUse)
                responseRFV(n) = computeDoGResponseForRow(...
                    x, fs, gainFunctionsTable, idxToUse(n), k);
            end
        
            responseTable = condTable;
            responseTable.SFRF = responseRFV;
        
            % helper, actual computation
            function responseRF = computeDoGResponseForRow(...
                    x, fs, gainFunctionsTable, idx, k)
                N = length(x);
                f = (0:N-1) * (fs / N);
                X = fft(x);
        
                masks = gainFunctionsTable.FrequencyBankMasks{idx};
                centerMask = masks.CenterFrequencyBankMask;
                surroundMask = masks.SurroundFrequencyBankMask;
        
                if length(centerMask) ~= N || length(surroundMask) ~= N
                    error('sfrfs:computeDoGResponse:MaskLength', ...
                        'Mask length does not match FFT length.');
                end
        
                spectrumCenter = X .* centerMask;
                spectrumSurround = X .* surroundMask;
        
                magspectrumCenter = abs(spectrumCenter) / N;
                magspectrumSurround = abs(spectrumSurround) / N;
        
                integralCenter = trapz(f, magspectrumCenter);
                integralSurround = ...
                    trapz(f, magspectrumSurround);
        
                responseRF = integralCenter - k * integralSurround;
            end
        end
    end
end
