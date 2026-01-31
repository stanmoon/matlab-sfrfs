classdef (Abstract) EnsembleProcessor < handle
% EnsembleProcessor Abstract base for ensemble processing classes.
%
%   Defines the interface for classes that process ensembles using
%   parallel workers.
%
% Properties:
%   numWorkers           Number of parallel workers to use 
%                        (positive integer, default: 2).
%
%   ensemble             Ensemble Broker object.
%
% Methods (Abstract):
%   getProcessParams     Return a struct with required parameters.
%
% Methods:
%   process              Apply a function handle to ensemble members using
%                        parallel execution.

    properties (Access = private)
        % numWorkers Number of parallel workers (default: 2)
        numWorkersInternal (1,1) double ...
            {mustBePositive, mustBeInteger} = 2
    
    
        % ensemble EnsembleBroker instance
        % (MATLAB has no 'null', empty is available for concrete classes)
        ensembleInternal = EnsembleBroker.empty
    end

    properties (Dependent)
        % to implement read-only operations on properties but for ensemble
        numWorkers double
        ensemble EnsembleBroker
    end

    
    methods
        % getter methods

        function val = get.numWorkers(obj)
            val = obj.numWorkersInternal;
        end

        function val = get.ensemble(obj)
            val = obj.ensembleInternal;
        end

        %setter for ensemble object
        function set.ensemble(obj, val)
            % Setter for ensemble property
            % Ensures the assigned value is a nonempty EnsembleBroker 
            % instance
            
            if isempty(val)
                error('sfrfs:EnsembleProcessor:EmptyEnsemble', ...
                    'Ensemble cannot be empty.');
            end
            if ~isa(val, 'EnsembleBroker')
                error('sfrfs:EnsembleProcessor:InvalidEnsembleType', ...
                    'Ensemble must be an instance of EnsembleBroker.');
            end
            
            obj.ensembleInternal = val;
        end
    end

    methods (Abstract)

        % getProcessParams Get parameters for the process method.
        %
        %   params = getProcessParams(obj) returns a struct containing all
        %   relevant parameters required for processing the ensemble.
        %
        %   Output Arguments:
        %     params - Struct with processing parameters. 
        %
        %   Example:
        %     function params = getProcessParams(obj)
        %         params.memberFiles = obj.ensemble.Files;
        %         params.sf = obj.samplingFrequency;
        %         params.fbt = obj.faultBandsTable;
        %         % other params...
        %     end
        %
        %   See also: process
    
        params = getProcessParams(obj)
    end

    methods

        function obj = EnsembleProcessor(args)
        % Constructor for EnsembleProcessor.
        % Argument Descriptions:
        %
        %   numWorkers           Number of parallel workers 
        %                    (1,:) char   (positive integer).
        %                        Default is 2.
        %
        %   ensemble             Ensemble.
        %                        Default is EnsembleBroker.empty.
            arguments
                args.numWorkers (1,1) double ...
                    {mustBePositive, mustBeInteger} = 2
                args.ensemble EnsembleBroker = EnsembleBroker.empty
            end
            obj.numWorkersInternal = args.numWorkers;
            obj.ensemble = args.ensemble;
        end

        function process(obj, computeHandle)
            %PROCESS Process ensemble members using a provided compute 
            % handle.
            %   process(obj, computeHandle) processes all members in the 
            %   ensemble, applying the function handle 'computeHandle' to 
            %   each member. Parallel or sequential execution is determined 
            %   by the number of workers.
            %
            %   Input Arguments:
            %     obj           - EnsembleProcessor instance.
            %     computeHandle - Function handle to apply to each member,
            %                     e.g., 
            %                     @(tbl, params) SubClass.compute(...
            %                           tbl, params)
            %
            %   Example (make compute Static):
            %     processor.process(@(tbl, params) ...
            %       SubClass.compute(tbl, params));
            %
            %   See also: parfor, EnsembleProcessor

            arguments
                obj
                computeHandle (1,1) function_handle
            end
            
            % runtime check
            if isempty(obj.ensemble)
                error('sfrfs:EnsembleProcessor:EmptyEnsemble',...
                      'Cannot process: Ensemble has not been assigned.');
            end
            memberFiles = EnsembleProcessor.sortFilesBySizeDesc( ...
                obj.ensemble.getFiles());
            params = obj.getProcessParams();
            mtvn = obj.ensemble.memberTableVarName;
            sortf = obj.ensemble.sortField;

            compute = parallel.pool.Constant(@() computeHandle);

            % Dimension parallel pool

            c = parcluster('Processes');

            % Fail fast on worker-count misconfiguration (no silent clamp)
            if obj.numWorkers > c.NumWorkers
                log = SFRFsLogger.getLogger();
                if log.isSevereEnabled()
                    log.severe([ ...
                        'Parallel worker misconfiguration: ' ...
                        'requested=%d, maxSupported=%d, profile=%s'], ...
                        obj.numWorkers, c.NumWorkers, 'Processes');

                end

                error('sfrfs:EnsembleProcessor:TooManyWorkers', ...
                    ['Requested %d workers but ''Processes'' supports ' ...
                     'at most %d. Reduce numWorkers or increase ' ...
                     'cluster NumWorkers.'], ...
                    obj.numWorkers, c.NumWorkers);
            end

            p = gcp('nocreate');

            % Enforce exact pool size (restart pool if size differs)
            if isempty(p) || p.NumWorkers ~= obj.numWorkers
                if ~isempty(p), delete(p); end
                parpool('Processes', obj.numWorkers);
            end

            nWorkers = numel(memberFiles);
            exceptions = cell(nWorkers,1);

            parfor kIdx = 1:nWorkers

                log = SFRFsLogger.getLogger();
                if log.isInfoEnabled()
                    log.info(sprintf('Worker processing %s ...', ...
                        memberFiles{kIdx}));
                end

                try
                    % Load member and sort
                    tbl = EnsembleBroker.loadEnsembleMember(...
                        'filename', memberFiles{kIdx}, ...
                        'memberTableVarName', mtvn, ...
                        'sort', true, ...
                        'sortField', sortf);

                    tbl = compute.Value(tbl,params);
                    
                    % Save the updated table
                    EnsembleBroker.saveEnsembleMember(...
                     memberFiles{kIdx}, mtvn, tbl);
                catch ME
                    if log.isWarningEnabled()
                        log.warning('Error processing file %s: %s', ...
                            memberFiles{kIdx}, ME.message);
                        log.warning('%s', getReport(ME, 'extended'));
                    end
                    exceptions{kIdx} = ME;
                end
            end
            EnsembleProcessor.throwIfParallelErrors(exceptions);    
        end
    end

    methods (Static, Access=private)
        function throwIfParallelErrors(exceptions)
        % Aggregate any exceptions thrown by workers
            log = SFRFsLogger.getLogger();
        
            failedIdx = find(~cellfun('isempty', exceptions));
            nExcep = numel(failedIdx);
        
            if nExcep > 0
                % Compose messages from actual failed workers
                msgs = cell(nExcep,1);
                for i = 1:nExcep
                    idx = failedIdx(i);
                    msgs{i} = sprintf(...
                        'Worker %d: %s', idx, exceptions{idx}.message);
                end
        
                combinedMsg = strjoin(msgs, '; ');
                if log.isWarningEnabled()
                    log.warning(combinedMsg);
                end
        
                % Create aggregated MException
                ME = MException(...
                    'SFRFsProcessor:ProcessingError', combinedMsg);
        
                % Add all individual exceptions as causes
                for i = 1:nExcep
                    ME = addCause(ME, exceptions{failedIdx(i)});
                end
        
                throwAsCaller(ME);
            end
        end

        function filesOut = sortFilesBySizeDesc(filesIn)
        % sortFilesBySizeDesc  Sort file paths by size (descending).
        %
        %   filesOut = sortFilesBySizeDesc(filesIn) sorts the input file 
        %   list from largest to smallest, using file size in bytes.
        
            arguments
                filesIn
            end
        
            isString = isstring(filesIn);
            files = cellstr(filesIn);
        
            n = numel(files);
            sizes = zeros(n, 1);
        
            for k = 1:n
                info = dir(files{k});
                if isempty(info)
                    error('sfrfs:EnsembleProcessor:FileNotFound', ...
                        'File not found: %s', files{k});
                end
                sizes(k) = info.bytes;
            end
        
            [~, idx] = sort(sizes, 'descend');
            filesOut = files(idx);
        
            if isString
                filesOut = string(filesOut);
            end
        end

    end
end
