classdef ReceptiveFieldGainFunctions < handle
% ReceptiveFieldGainFunctions  Computes receptive field gain functions
% for fault frequency bands based on provided frequencyBands.
%
%   This class operates on the fault bands and parameters encapsulated
%   in a FrequencyBands instance, enabling computation of frequency masks
%   or gain functions for Spectral Fault Receptive Fields.
%
% Properties:
%   frequencyBands          - Instance of FrequencyBands containing
%                             SFRF parameters and precomputed fault bands.
%   frequencyDomain         - Frequency grid (Hz) on which the receptive
%                             field gain functions were computed.
%                             This domain is stored on first computation
%                             and defines the immutable spectral support
%                             of computed RFGFs.
%
% Example (with bearing example):
%   rfgf = ReceptiveFieldGainFunctions(frequencyBandsObject);
%
% See also BearingFrequencyBands, SFRFsParametersRollingBearings

    properties (Access = private)
        frequencyBandsInternal
    end

    properties
        gainFunctionsTable table = table.empty % initialize empty table
        frequencyDomain double = [];
    end

    properties (Dependent)
        frequencyBands FaultFrequencyBands
    end

    methods
        function obj = ReceptiveFieldGainFunctions(frequencyBands)
        % Constructor storing the frequencyBands instance
            arguments
                frequencyBands FaultFrequencyBands
            end
            obj.frequencyBandsInternal = frequencyBands;
        end

        function val = get.frequencyBands(obj)
            val = obj.frequencyBandsInternal;
        end

        function computeGainFunctions(obj, frequencyDomain)
        % computeGainFunctions
        %
        % Computes frequency masks for each fault and operational
        % condition in the faults frequency bands table available in
        % the frequencyBands property.
        %
        % Inputs:
        %   frequencyDomain - Vector of frequency points (Hz) over
        %                     which to evaluate gain functions.

            numFreqPoints = numel(frequencyDomain);
            if numFreqPoints == 0
                error( ...
                    ['sfrfs:ReceptiveFieldGainFunctions:'...
                     'computeGainFunctions:EmptyFrequencyDomain'], ...
                    'Frequency domain is empty.');
            end


            import tables.FaultBandsTableSchema
            import tables.GainFunctionsTableSchema
            import structs.FrequencyBankMasksSchema

            kFaultGroupT = FaultBandsTableSchema.FAULTGROUP;
            kRfbT        = FaultBandsTableSchema.RECEPTIVEFIELDBANDS;

            kMasksT = GainFunctionsTableSchema.FREQUENCYBANKMASKS;

            kCenter = FrequencyBankMasksSchema.CENTER;
            kSur = FrequencyBankMasksSchema.SURROUND;
            kCon = FrequencyBankMasksSchema.CONTRAST;

            fbt = obj.frequencyBands.bandsTable;
            sfrfsParams = obj.frequencyBands.sfrfsParams;

            N = height(fbt);
            masksNewColumn = cell(N, 1);
            log = SFRFsLogger.getLogger();

            for i = 1:N
                if log.isFineEnabled()
                    log.fine("Computing Mask for row: " + string(i));
                end

                faultGroup = fbt{i, kFaultGroupT};

                if log.isFineEnabled()
                    log.fine("Fault group: " + string(faultGroup));
                end

                faultType = obj.frequencyBands.faultGroupToTypeName( ...
                    faultGroup);

                if log.isFineEnabled()
                    log.fine("Fault type: " + string(faultType));
                end

                centerMaskParams   = sfrfsParams.(faultType).centerMask;
                surroundMaskParams = sfrfsParams.(faultType).surroundMask;

                if log.isFineEnabled()
                    log.fine( ...
                        "Center mask params: " + ...
                        centerMaskParams.toString());
                    log.fine( ...
                        "Surround mask params: " + ...
                        surroundMaskParams.toString());
                end

                bands = FaultFrequencyBands.extractBands(fbt, i);

                if log.isFineEnabled()
                    log.fine( ...
                        "Center bands matrix: " + ...
                        mat2str(bands.CenterBandsMatrix));
                    log.fine( ...
                        "Surround bands matrix: " + ...
                        mat2str(bands.SurroundBandsMatrix));
                end

                centermask = zeros( ...
                    numFreqPoints, 1, 'like', frequencyDomain);
                surroundmask = zeros( ...
                    numFreqPoints, 1, 'like', frequencyDomain);

                for j = 1:bands.NumberOfBands
                    if log.isFineEnabled()
                        log.fine( ...
                            "Number of bands: " + ...
                            string(bands.NumberOfBands));
                    end

                    centerband = bands.CenterBandsMatrix( ...
                        j, [bands.MinFreqColumn, bands.MaxFreqColumn]);

                    if log.isFineEnabled()
                        log.fine("Center Band " + mat2str(centerband));
                    end

                    centermask = max( ...
                        centermask, FrequencyMask.evaluate( ...
                        frequencyDomain, ...
                        centerband, ...
                        centerMaskParams));

                    surroundband = bands.SurroundBandsMatrix( ...
                        j, [bands.MinFreqColumn, bands.MaxFreqColumn]);

                    surroundmask = max( ...
                        surroundmask, FrequencyMask.evaluate( ...
                        frequencyDomain, ...
                        surroundband, ...
                        surroundMaskParams));
                end

                % edit, we add the contrast channel too
                k = sfrfsParams.(faultType).inhibitionFactor;

                contrastmask = centermask - k * surroundmask;

                masksNewColumn{i} = struct( ...
                    kCenter, centermask, ...
                    kSur,    surroundmask, ...
                    kCon,    contrastmask);

            end

            fbt.(kMasksT) = masksNewColumn;

            obj.gainFunctionsTable = removevars(fbt, kRfbT);

            % store frequency domain
            obj.frequencyDomain = frequencyDomain;
        end
    end
end
