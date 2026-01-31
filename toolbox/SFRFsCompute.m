classdef SFRFsCompute < handle
% SFRFsCompute Performs spectral fault receptive field computations
%   Uses ReceptiveFieldGainFunctions (with nested FaultFrequencyBands) and
%   ParametersSnapshot to compute responses on input signals.
%
% Example usage:
%   sfrfsCalc = SFRFsCompute( ...
%       snapshotParameters = paramsSnapshot, ...
%       rfgfs = rfgfInstance);
%
%   responseTable = sfrfsCalc.compute( ...
%       temporalSnapshot = x, ...
%       operatingCondition = operatingCondition);
    

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
            end

            if ~isempty(args.temporalSnapshot) && ...
                    ~isempty(args.spectrumSnapshot)
                error('sfrfs:SFRFsCompute:AmbiguousInputSignal', ...
                    ['Only one of temporal or spectral data should be ' ...
                    'provided.']);
            end

            import tables.GainFunctionsTableSchema
            import tables.OperatingConditionsTableSchema
            import structs.FrequencyBankMasksSchema

            kFaultGroup = GainFunctionsTableSchema.FAULTGROUP;
            kMasks      = GainFunctionsTableSchema.FREQUENCYBANKMASKS;
            kSfrfs      = GainFunctionsTableSchema.SFRFS;

            kSpeed = OperatingConditionsTableSchema.SPEED;
            kLoad  = OperatingConditionsTableSchema.LOAD;

            kCenter = FrequencyBankMasksSchema.CENTER;
            kSur    = FrequencyBankMasksSchema.SURROUND;

            log = SFRFsLogger.getLogger();

            f = obj.paramsSnapshot.getFrequencyDomain();
            gainTable = obj.rfgfs.gainFunctionsTable;

            requiredVars = [kSpeed, kLoad];
            varNames = string(...
                args.operatingCondition.Properties.VariableNames);
            
            if ~all(ismember(requiredVars, varNames))
                error('sfrfs:SFRFsCompute:MissingColumn', ...
                    'Expected columns %s and %s.', kSpeed, kLoad);
            end


            maskRows = ismember( ...
                gainTable{:, requiredVars}, ...
                args.operatingCondition{:, requiredVars}, ...
                'rows');

            idxs = find(maskRows);
            if isempty(idxs)
                if log.isSevereEnabled()
                    jsonStr = jsonencode(args.operatingCondition);
                    log.severe(sprintf( ...
                        'Operating condition missing in RFGFs: %s', ...
                        jsonStr));
                end
                error('sfrfs:SFRFsCompute:MissingFaultBands', ...
                    'Operating condition missing in RFGFs.');
            end

            selectedBands = gainTable(idxs, :);

            if isempty(args.spectrumSnapshot)
                X = fft(args.temporalSnapshot, [], 1);
            else
                X = args.spectrumSnapshot;
            end

            nFFT = size(X, 1);

            SFRF = cell(height(selectedBands), 1);
            for i = 1:height(selectedBands)
                masks = selectedBands.(kMasks){i};

                centerMask   = masks.(kCenter);
                surroundMask = masks.(kSur);

                if numel(centerMask) ~= nFFT || numel(surroundMask) ~= nFFT
                    error('sfrfs:SFRFsCompute:MaskLength', ...
                        'Mask length does not match FFT length.');
                end

                faultGroup = selectedBands.(kFaultGroup)(i);
                faultType = ...
                    obj.rfgfs.frequencyBands.faultGroupToTypeName( ...
                    faultGroup);

                k = obj.sfrfsParams.(faultType).inhibitionFactor;

                SFRF{i} = obj.computeSingleModeResponse( ...
                    X, centerMask, surroundMask, f, k);
            end

            responseTable = selectedBands;
            responseTable.(kSfrfs) = SFRF;
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