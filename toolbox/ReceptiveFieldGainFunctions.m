classdef ReceptiveFieldGainFunctions < handle
% ReceptiveFieldGainFunctions  Computes receptive field gain functions
% for fault frequency bands based on provided frequencyBands.
%
%   This class operates on the fault bands and parameters encapsulated
%   in a FrequencyBands instance, enabling computation of Gaussian masks or 
%   gain functions for Spectral Fault Receptive Fields.
%
% Properties:
%   frequencyBands          - Instance of FrequencyBands containing  
%                             SFRF parameters and precomputed fault bands.
%
% Example (with bearing example):
%   rfgf = ReceptiveFieldGainFunctions(frequencyBandsObject);
%_
% See also BearingFrequencyBands, SFRFsParametersRollingBearings

    properties (Access = private)
        frequencyBandsInternal
    end

    properties
        gainFunctionsTable table = table.empty % initialize empty table
    end

    properties (Dependent)
        frequencyBands FaultFrequencyBands
    end
    
    methods
        function obj = ReceptiveFieldGainFunctions(frequencyBands)
        % Constructor storing the frequencyBands instance
        %
        % Inputs:
        %   frequencyBands - An instance of FaultFrequencyBands with 
        %                           computed fault bands.
            arguments
                frequencyBands FaultFrequencyBands
            end
            obj.frequencyBandsInternal = frequencyBands;
        end

        function val = get.frequencyBands(obj)
            val = obj.frequencyBandsInternal;
        end
        
        function computeGainFunctions(obj, frequencyDomain)
        %
        % Computes Gaussian frequency masks for each fault and operational
        % condition in the faults frequency bands table available in the
        % frequencyBands property.
        %
        % Inputs:
        %   frequencyDomain - Vector of frequency points (Hz) over which to 
        %                     evaluate gain functions.
        %
            
            numFreqPoints = length(frequencyDomain);
            if numFreqPoints == 0
                error( ...
                    ['sfrfs:ReceptiveFieldGainFunctions:'...
                     'computeGainFunctions:EmptyFrequencyDomain'],...
                    'Frequency domain is empty.');
            end
            % Initialize masks storage
            fbt = obj.frequencyBands.bandsTable;
            sfrfsParams = obj.frequencyBands.sfrfsParams;
            N = height(fbt);
            masksNewColumn = cell(N, 1);
            log = SFRFsLogger.getLogger();
            
            % Main processing loop
            for i = 1:N
                if log.isFineEnabled()
                    log.fine("Computing Mask for row: "+string(i));
                end

                faultGroup = fbt.FaultGroup(i);

                if log.isFineEnabled()
                    log.fine("Fault group: "+string(faultGroup));
                end
                
              
                faultType = obj.frequencyBands.faultGroupToTypeName(...
                    faultGroup);

                if log.isFineEnabled()
                    log.fine("Fault type: "+string(faultType));
                end
                
                 
                % Extract parameters from struct
                sigmaCenter = sfrfsParams.(faultType).sigmaCenter(2);
                sigmaSurround = ...
                    sfrfsParams.(faultType).sigmaSurround(2);
                
                if log.isFineEnabled()
                    log.fine("Sigma Center: "+string(sigmaCenter));
                    log.fine("Sigma Surround: "+string(sigmaSurround));
                end
                

                bands = FaultFrequencyBands.extractBands(fbt, i);

                if log.isFineEnabled()
                    log.fine("Center bands matrix: "+...
                        mat2str(bands.CenterBandsMatrix))
                    log.fine("Surround bands matrix: "+...
                        mat2str(bands.SurroundBandsMatrix))
                end
                
                centermask = ...
                    zeros(numFreqPoints, 1, 'like', frequencyDomain);
                surroundmask = ...
                    zeros(numFreqPoints, 1, 'like', frequencyDomain);

                
                % Process each band
                for j = 1:bands.NumberOfBands

                    log.fine("Number of bands: "+...
                        string(bands.NumberOfBands));

                    % Extract the current frequency band for the center
                    centerband = bands.CenterBandsMatrix(...
                        j, [bands.MinFreqColumn, bands.MaxFreqColumn]);


                    log.fine("Center Band "+mat2str(centerband));

        
                    % Compute the mask and consolidate with max operator
                    % the use of max is to appropriatelly handle possible 
                    % band overlaps, similar to Fuzzy logic OR operation
                    centermask = ...
                        max(centermask, FrequencyMask.gaussian( ...
                        frequencyDomain, centerband, sigmaCenter));
                    
                    % Similarly for surround
                    surroundband = bands.SurroundBandsMatrix( ...
                        j, [bands.MinFreqColumn, bands.MaxFreqColumn]);

                    surroundmask = ...
                        max(surroundmask, FrequencyMask.gaussian( ...
                        frequencyDomain, surroundband, sigmaSurround));
                end
                
                % Store results
                masksNewColumn{i} = struct(...
                    'CenterFrequencyBankMask', centermask,...
                    'SurroundFrequencyBankMask', surroundmask);
            end
            
            % Update and assign output table to property
            fbt.FrequencyBankMasks = masksNewColumn;
            % Drop ReceptiveFieldBands
            obj.gainFunctionsTable = ...
                removevars(fbt, 'ReceptiveFieldBands');

        end
    end
end
