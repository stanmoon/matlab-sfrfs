classdef SFRFsCompute < handle
    % SFRFsCompute Performs spectral fault receptive field computations
    %   Uses ReceptiveFieldGainFunctions (with nested FaultFrequencyBands) and
    %   ParametersSnapshot to compute responses on input signals.
    %
    % Example usage:
    %   sfrfsCalc = SFRFsCompute(paramsSnapshot, rfgfInstance);
    %   responseTable = sfrfsCalc.compute(x, operatingCondition);
    

    properties (SetAccess = private)
        paramsSnapshot ParametersSnapshot  % Sampling and timing parameters
        rfgfs ReceptiveFieldGainFunctions  % RFGFs encapsulating also:
                                           %    - SFRFs, and 
                                           %    - operatingConditions
                                           % parameters.
    end

    properties (Dependent)
        samplingFrequency double
        sfrfsParams SFRFsParameters
        rfgfsTable table
        operatingConditions table
    end
    
    methods
        function obj = SFRFsCompute(args)
        % SFRFsCompute Construct a configured SFRFsCompute object
        %
        % obj = SFRFsCompute(...
        %   snapshotParameters = sp, rfgfs = rfgfsInstance)
        % creates an instance configured with the given snapshot parameters 
        % and receptive field gain functions.
        %
        % Named input arguments:
        %   snapshotParameters                  - Sampling parameters
        %   rfgfs                               - Receptive field gain 
        %                                         functions and parameters
        %
        % See also ParametersSnapshot, ReceptiveFieldGainFunctions, compute
            arguments
                args.snapshotParameters ParametersSnapshot
                args.rfgfs ReceptiveFieldGainFunctions
            end
            obj.paramsSnapshot = args.snapshotParameters;
            obj.rfgfs = args.rfgfs;
        end
        
        function val = get.samplingFrequency(obj)
            val = obj.paramsSnapshot.samplingFrequency;
        end
        
        function val = get.sfrfsParams(obj)
            val = obj.rfgfs.frequencyBands.sfrfsParams;
        end

        function val = get.rfgfsTable(obj)
            val = obj.rfgfs.gainFunctionsTable;
        end

        function val = get.operatingConditions(obj)
            val = obj.rfgfs.frequencyBands.operatingConditions;
        end
        
        function responseTable = compute(obj, args)
            arguments
                obj
                args.temporalSnapshot (:, :) double = []
                args.spectrumSnapshot (:, :) double = []
                args.operatingCondition table ...
                    {SFRFsCompute.mustBeOneRowTable}
            end

            if isempty(args.temporalSnapshot) && ...
                    isempty(args.spectrumSnapshot)
                error('sfrfs:SFRFsCompute:NoInputSingal', ...
                    'Either temporal or spectral data must be provided.');
            elseif ~isempty(args.temporalSnapshot) && ...
                    ~isempty(args.spectrumSnapshot)
                error('sfrfs:SFRFsCompute:AmbiguousInputSignal',...
                    ['Only one of temporal or spectral data' ...
                     ' should be provided.']);
            end

            
            log = SFRFsLogger.getLogger();

            % Retrieve frequency domain details
            f = obj.paramsSnapshot.getFrequencyDomain();
            
            % Access gain functions table
            gainTable = obj.rfgfs.gainFunctionsTable;
            
            % Validate and filter operating conditions
            requiredVars = {'Speed', 'Load'};
            if ~all(ismember(...
                    requiredVars, ...
                    args.operatingCondition.Properties.VariableNames))
                error('sfrfs:SFRFsCompute:MissingColumn', ...
                      'Nonconforming to expected Speed and Load columns.');
            end
            
            % RequiredVars for filtering gainTable by operatingCondition
            maskRows = ismember(...
                gainTable(:, requiredVars), ...
                args.operatingCondition(:, requiredVars));
            idxs = find(maskRows);
            
            if isempty(idxs)
                if log.isSevereEnabled()
                    jsonStr = jsonencode(args.operatingCondition);
                    msg = sprintf(...
                        'Operating condition missing in RFGFs: %s', ...
                        jsonStr);
                    log.severe(msg);
                end
                error('sfrfs:SFRFsCompute:MissingFaultBands', ...
                      'Operating condition missing in RFGRs.');
            end

            selectedBands = gainTable(idxs, :);
            
            % Compute or use provided FFT
            if isempty(args.spectrumSnapshot)
                X = fft(args.temporalSnapshot, [], 1);
            else
                X = args.spectrumSnapshot;
            end
            
            nFFT = size(X, 1);


            % Calculate SFRF responses per fault mode
            SFRF = cell(height(selectedBands), 1);
            for i = 1:height(selectedBands)

                masks = selectedBands.FrequencyBankMasks{i};
                % Ensure mask lengths match FFT length
                if length(masks.CenterFrequencyBankMask) ~= nFFT || ...
                        length(masks.SurroundFrequencyBankMask) ~= nFFT
                    error('sfrfs:SFRFsCompute:MaskLength', ...
                        'Mask length does not match FFT length.');
                end

                % Extract fault type for current row (example)
                faultGroup = selectedBands.FaultGroup(i);
                faultType = ...
                    obj.rfgfs.frequencyBands.faultGroupToTypeName(...
                    faultGroup);
            
                % Retrieve inhibition factor specific to fault type
                k = obj.sfrfsParams.(faultType).inhibitionFactor;

                SFRF{i} = obj.computeSingleModeResponse(...
                    X, ...
                    masks.CenterFrequencyBankMask, ...
                    masks.SurroundFrequencyBankMask, ...
                    f, ...
                    k);
            end
            
            % Construct response table including SFRF results
            responseTable = selectedBands;
            responseTable.SFRFs = SFRF;
        end
    end
    
    methods (Access = private)
        function response = computeSingleModeResponse(...
                ~, X, centerMask, surroundMask, f, k)
            % Compute SFRF response for one fault mode over all signals
            
            spectrumCenter = X .* centerMask;
            spectrumSurround = X .* surroundMask;
            
            magCenter = abs(spectrumCenter) / length(centerMask);
            magSurround = abs(spectrumSurround) / length(surroundMask);
            
            integralCenter = trapz(f, magCenter, 1);
            integralSurround = trapz(f, magSurround, 1);
            
            response = integralCenter - k * integralSurround;
        end
    end

    methods (Static, Access = private)
        function mustBeOneRowTable(tbl)
            if ~(istable(tbl) && size(tbl, 1) == 1)
                error('Input must be a table with exactly one row.');
            end
        end
    end
end