classdef SFRFsEnsembleProcessor < EnsembleProcessor
% SFRFsEnsembleProcessor Processes ensemble data for 
%   Spectral Fault Receptive Fields (SFRFs).
%
% This class manages parallel or sequential processing of ensemble members 
% to compute SFRF responses based on input parameters encapsulating 
% frequency bands, snapshot parameters, and receptive field gain functions.
%
%
% Properties:
%   frequencyBands      - Object specifying frequency band definitions.
%   snapshotParameters  - Object specifying sampling and snapshot details.
%
% Methods:
%   compute            - Update a single ensemble member with computed 
%                        SFRFs.
%   process            - Process all ensemble members.
%
% See also: SFRFsCompute, ReceptiveFieldGainFunctions, EnsembleProcessor
%   data.createXJTUSYEnsemble, data.getXJTUSYEnsemble

    properties (Access = private)
        frequencyBandsInternal 
        snapshotParametersInternal ParametersSnapshot = ...
            ParametersSnapshot.empty
    end

    properties (Dependent)
        frequencyBands FaultFrequencyBands
        snapshotParameters ParametersSnapshot
    end

    methods
        function obj = SFRFsEnsembleProcessor(args)
        % SFRFsEnsembleProcessor Construct an instance of the class.
        %
        %   obj = SFRFsEnsembleProcessor(Name, Value, ...)
        %   creates an SFRFsEnsembleProcessor object configured with the
        %   specified input arguments.
        %
        %   Inputs (Name-Value pairs):
        %     'numWorkers'         - Number of parallel workers to use 
        %                            (positive integer, default: 2).
        %     'ensemble'           - SFRFsEnsembleBroker object.
        %     'frequencyBands'     - FaultFrequencyBands object specifying 
        %                            frequency band definitions.
        %     'snapshotParameters' - ParametersSnapshot object specifying 
        %                            snapshot details.
        %
        %   Output:
        %     obj                 Instance of SFRFsEnsembleProcessor class.

            arguments
                args.numWorkers (1,1) double ...
                    {mustBePositive, mustBeInteger} = 2
                args.ensemble SFRFsEnsembleBroker {mustBeNonempty}
                args.frequencyBands FaultFrequencyBands {mustBeNonempty}
                args.snapshotParameters ParametersSnapshot {mustBeNonempty}
            end

            % Call superclass constructor with validated args
            obj@EnsembleProcessor(...
                numWorkers = args.numWorkers, ...
                ensemble = args.ensemble);
            obj.frequencyBandsInternal = args.frequencyBands;
            obj.snapshotParametersInternal = args.snapshotParameters;
        end

        % Getter for frequencyBands
        function fb = get.frequencyBands(obj)
            fb = obj.frequencyBandsInternal;
        end
    
        % Getter for snapshotParameters
        function sp = get.snapshotParameters(obj)
            sp = obj.snapshotParametersInternal;
        end

        function params = getProcessParams(obj)
        % getProcessParams Get parameters for ensemble processing.
        %
        %   params = getProcessParams() returns a struct with
        %   all relevant parameters for the processing workflow.
        %
        %   Output Arguments:
        %     params - Struct with fields:
        %              frequencyBands     - Frequency bands.
        %              snapshotParameters - Snapshot parameters.
        %              rfgfs              - Receptive Field Gain
        %                                   Functions.
        %              sfrfsCompute       - SFRFs' Compute object.
        %   Note:
        %       FrequencyBands object includes SFRFs parameters and
        %       operation conditions
        %   Example:
        %     params = obj.getProcessParams();
        
            log = SFRFsLogger.getLogger();
            params.ensemble = obj.ensemble;
            params.snapshotParameters = obj.snapshotParameters;
            params.frequencyBands = obj.frequencyBands;
            % check if frequency bands have been computed
            if isempty(params.frequencyBands.bandsTable)
                if log.isInfoEnabled()
                    log.info(...
                        "Empty frequency bands, computing bands.");
                end
                params.frequencyBands.computeBands();
            end
            % create spectral mask object
            params.rfgfs = ReceptiveFieldGainFunctions(...
                params.frequencyBands);
            % compute masks
            params.rfgfs.computeGainFunctions(...
                params.snapshotParameters.getFrequencyDomain());
            % create SFRFsCompute instance
            params.sfrfsCompute = SFRFsCompute( ...
            snapshotParameters = params.snapshotParameters, ...
            rfgfs = params.rfgfs);
        end

        function process(obj, computeHandle)
        % process Process ensemble members.
        %
        %   process() computes SFRFs for all members in the ensemble.
        %
        %   process(computeHandle) overrides the default compute method
        %   used during processing with a custom function handle.
        %
        %   This method injects compute handle but delegates control to
        %   parents process method.
        %
        % Inputs:
        %   computeHandle - Optional function handle 
        %                   @(memberTable, params)
        %                   Default: @SFRFsEnsembleProcessor.compute
        % See also: EnsembleProcessor/process

            arguments
                obj
                computeHandle (1,1) function_handle = ...
                    @(memberTable, params) ...
                    SFRFsEnsembleProcessor.compute(memberTable, params)
            end
            
            % Delegate processing to superclass method
            process@EnsembleProcessor(obj, computeHandle);
        end

    end

    methods (Static, Access = private)

        function responseTable = computeMemberSFRFs(...
                memberTable, params, signalColumn)
        % COMPUTEMEMBERSFRFS Compute SFRF responses for a specified signal 
        %   column.
        %
        %   responseTable = computeMemberSFRFs(...
        %       memberTable, params, signalColumn)
        %
        % Inputs:
        %   memberTable: Table containing ensemble member data.
        %   params     : Struct with fields:
        %                 - frequencyBands    : Frequency bands info.
        %                 - snapshotParameters: Snapshot parameters.
        %                 - rfgfs             : Receptive Field Gain 
        %                                       Functions.
        %                 - sfrfsCompute      : SFRFs' Compute object
        %   signalColumn: String, name of the signal column in memberTable
        %
        % Outputs:
        %   responseTable : Table of computed SFRF responses
        %
        % Example:
        %   responseTable = computeMemberSFRFs(...
        %       tbl, params, 'HorizontalAcceleration');
        %
        % See also: SFRFsCompute/compute
        
            % Extract operating condition(constant in run-to-failure tests)
            oc = memberTable(1, {'Speed', 'Load'});
        
            % Extract FFT spectral column name for the current signal
            spectralCol = ...
                params.ensemble.mapToSpectralColumn(...
                signalColumn);
        
            % Extract spectral data
            x_fft = [memberTable.(spectralCol){:}];
        
            % Call the compute method on sfrfsCompute object
            responseTable = params.sfrfsCompute.compute(...
                operatingCondition = oc, spectrumSnapshot = x_fft);
        end

        function tbl = extendTableWithSFRFs(...
                tbl, responseTable, sfrfColName)
        % EXTENDTABLEWITHSFRFS Add or update SFRF results column for any 
        %   signal axis.
        %
        %   tbl = extendTableWithSFRFs(tbl, responseTable, sfrfColName)
        %   Adds or updates tbl storing SFRFs in column named sfrfColName.
        %   Each cell in the column contains a [1 x nFaultModes] row vector
        %   of SFRF responses for each snapshot.
        %
        % Inputs:
        %   tbl           - Original ensemble member table.
        %   responseTable - Table with SFRF results for the specified axis.
        %                   Must include a 'SFRFs' cell column 
        %                   (cell arrays of row vectors).
        %   sfrfColName   - Name for the SFRF result column.
        %
        % Output:
        %   tbl - Table extended or updated with the specified SFRF column.
        
            % Convert SFRF table cell array to matrix for easier handling
            responseRF = cell2mat(responseTable.SFRFs);
        
            % Determine size for cell partitioning
            nFaultModes = size(responseRF, 1);
            nSnapshots = size(responseRF, 2);
        
            % Create cell column for the table: [nSnapshots x 1] cell, 
            % each cell is [1 x nFaultModes]
            % Transpose because each cell should hold a row vector for that 
            % snapshot
            tbl.(sfrfColName) = mat2cell(...
                responseRF.', ones(nSnapshots, 1), nFaultModes);
        end

    end

    methods (Static, Access = protected)

        function updatedMember = compute(memberTable, params)
        % COMPUTE: Update ensemble member table with SFRF responses for each 
        % temporal column.
        %
        %   updatedMember = SFRFsEnsembleProcessor.compute(memberTable, params)
        %
        % Inputs:
        %   memberTable - Table of ensemble member data (single condition).
        %                 Must include 'Speed' and 'Load' columns.
        %   params      - Struct with fields:
        %                   - frequencyBands
        %                   - snapshotParameters
        %                   - rfgfs
        %                   - sfrfsCompute
        %
        % Output:
        %   updatedMember - table with new SFRF results columns.
        
            
        
            % Retrieve temporal signal columns from ensemble context
            ensemble = params.ensemble;  
            signalColumns = ensemble.temporalSnapshotColumns;
            log = SFRFsLogger.getLogger();

            % Validate FFT columns are present and correct
            SFRFsEnsembleProcessor.validatePrecomputedFFTColumns(...
                memberTable, ensemble);
            
            for i = 1:numel(signalColumns)
                signalColumn = signalColumns{i};
                sfrfColName = ensemble.mapToSFRFColumn(signalColumn);
        
                if log.isFineEnabled()
                    log.fine(sprintf(...
                        'Processing input: "%s", output: "%s"...', ...
                        signalColumn, sfrfColName));
                end
        
                % Compute SFRF responses for the signal column
                responseTable = ...
                    SFRFsEnsembleProcessor.computeMemberSFRFs(...
                        memberTable, params, signalColumn);
        
                % Extend the table with new SFRF results for this signal
                memberTable = ...
                    SFRFsEnsembleProcessor.extendTableWithSFRFs(...
                        memberTable, responseTable, sfrfColName);
        
                if log.isFineEnabled()
                    log.fine(sprintf('Done processing "%s"', signalColumn));
                end
            end
        
            updatedMember = memberTable;
        end

        function validatePrecomputedFFTColumns(memberTable, broker)
        % Validate FFT columns exist and have been precomputed

           arguments
               memberTable table
               broker SFRFsEnsembleBroker
           end

            % Helper internal function
            function tf = isValidFFTColumn(col)
                tf = iscell(col) && ...
                    all(cellfun(@(x) isnumeric(x) && ~isempty(x), col));
                if tf
                    sizes = cellfun(@size, col, 'UniformOutput', false);
                    tf = all(cellfun(@(x) isequal(x, sizes{1}), sizes));
                end
            end
    
            % Validate all expected spectral columns are present and valid
            colList = broker.temporalSnapshotColumns;
            for i = 1:numel(colList)
                column = broker.mapToSpectralColumn(colList{i});
                if ~ismember(...
                        column, memberTable.Properties.VariableNames) || ...
                        ~isValidFFTColumn(memberTable.(column))
                    error('sfrfs:EnsembleProcessor:MissingFFTColumn', ...
                        'FFT column "%s" missing or invalid', column);
                end
            end
        end
    end

    methods (Static, Access=public)
        function stackedSFRFs = bufferSFRFs(SFRF, Order)
        % BUFFERSFRFS Generate higher-order SFRFs for a single axis/sensor.
        %
        %   STACKEDSFRFS = BUFFERSFRFS(SFRF, ORDER) returns a matrix
        %   where each row contains the current and previous ORDER SFRF 
        %   vectors for a single axis or sensor, stacked for temporal 
        %   context.
        %
        %   To indicate insufficient history at the start of the sequence,
        %   the initial rows are padded with NaN values. This explicit use 
        %   of NaN (rather than zero) avoids introducing artificial values 
        %   that could bias downstream analysis or machine learning models.
        %
        %   INPUTS:
        %       SFRF   - [nFaultModes x nSnapshots] numeric matrix of SFRFs 
        %                for one axis/sensor.
        %       ORDER  - Non-negative integer specifying the number of 
        %                previous time steps.
        %
        %   OUTPUT:
        %       STACKEDSFRFS - [nSnapshots x nFaultModes*(ORDER+1)] matrix 
        %                      of stacked SFRFs.
        %
        %   EXAMPLE:
        %       % Suppose SFRF is [4 x 10] (4 fault modes, 10 snapshots)
        %       order = 2;
        %       stackedSFRFs = SFRFsEnsembleProcessor.bufferSFRFs(SFRF, ... 
        %                       order);
        %       % stackedSFRFs is [10 x 12] (since 4*(2+1) = 12)
        %
        %   SEE ALSO:
        %       SFRFsEnsembleProcessor.computeMemberSFRFs, 
        %       SFRFsEnsembleProcessor.extendTableWithSFRFs
        
            arguments
                SFRF (:,:) {mustBeNumeric}
                Order (1,1) {mustBeInteger, mustBeNonnegative}
            end
        
            nFaultModes = size(SFRF,1);
        
            if Order == 0
                % No temporal stacking, just transpose 
                stackedSFRFs = SFRF.'; % [nSnapshots x nFaultModes]
                return
            end
        
            SFRF_vec = SFRF(:);
        
            windowLength = nFaultModes * (Order + 1);
            overlap = windowLength - nFaultModes;
        
            pad = NaN(windowLength - nFaultModes, 1);
            SFRF_padded = [pad; SFRF_vec];
        
            B = buffer(SFRF_padded, windowLength, overlap, 'nodelay');
            % B is [windowLength x nSnapshots]

            stackedSFRFs = B.'; % [nSnapshots x nFaultModes*(Order+1)]
        end
    end
end
