classdef (Sealed) EnsembleDatastoreRegistry < handle
    % EnsembleDatastoreRegistry
    %   Static factory for registering, retrieving, reconfiguring, and
    %   managing fileEnsembleDatastore objects. Supports persistence,
    %   logging, and ensures that ensembles are globally accessible
    %   across MATLAB sessions.
    %
    %   This class is sealed and provides only static methods; it does
    %   not need to be instantiated.
    %
    %   Features:
    %     - Register new ensembles with addEnsemble
    %     - Retrieve ensembles by name with getEnsemble
    %     - Check existence with hasEnsemble
    %     - List all registered ensemble names with getAllEnsembleNames
    %     - Reconfigure ensemble variables with reconfigureEnsemble
    %     - Remove individual ensembles with removeEnsemble
    %     - Reset all registered ensembles with factoryReset
    %
    %   All registered ensembles are persisted to a MAT-file in the
    %   user preferences directory and loaded automatically when needed.
    %
    %   Usage:
    %       % Add a new ensemble
    %       EnsembleDatastoreRegistry.addEnsemble( ...
    %           name = "myEnsemble", ...
    %           datastore = myFileEnsembleDatastore);
    %
    %       % Retrieve a registered ensemble
    %       ds = EnsembleDatastoreRegistry.getEnsemble("myEnsemble");
    %
    %       % Reconfigure variable sets
    %       ds = EnsembleDatastoreRegistry.reconfigureEnsemble( ...
    %           name = "myEnsemble", ...
    %           DataVariables = ["Signal1", "Signal2"], ...
    %           SelectedVariables = ["Signal1"]);
    %
    %       % Check if an ensemble exists
    %       tf = EnsembleDatastoreRegistry.hasEnsemble("myEnsemble");
    %
    %       % List all ensemble names
    %       names = EnsembleDatastoreRegistry.getAllEnsembleNames();
    %
    %       % Remove an ensemble
    %       EnsembleDatastoreRegistry.removeEnsemble("myEnsemble");
    %
    %       % Reset all ensembles
    %       EnsembleDatastoreRegistry.factoryReset();
    %
    %   See also: fileEnsembleDatastore, SFRFsLogger


    properties (Constant, Access = private)
        ENSEMBLE_FOLDER = fullfile(prefdir, 'sfrfs');
        ENSEMBLE_MAP_FILE = fullfile( ...
            prefdir, 'sfrfs', 'sfrfs-ensembles-map.mat');
    end

    methods (Static)

        function addEnsemble(args)
        % addEnsemble Register a new fileEnsembleDatastore
        %
        %   EnsembleDatastoreRegistry.addEnsemble(Name, Datastore)
        %   registers a new ensemble with the factory. If an ensemble
        %   with the same name already exists, it will be overwritten
        %   and a log message is issued.
        %
        %   Inputs (as Name-Value pairs):
        %       'name'      - Text scalar specifying the ensemble name.
        %       'datastore' - A fileEnsembleDatastore object to register.
        %
        %   The method persists the updated registry to disk and updates
        %   the in-memory map, making the ensemble available for
        %   retrieval in the current and future MATLAB sessions.
        %
        %   Example:
        %       ds = fileEnsembleDatastore(...); % construct datastore
        %       EnsembleDatastoreRegistry.addEnsemble( ...
        %           name = "myEnsemble", ...
        %           datastore = ds);
        %
        %   See also: getEnsemble, reconfigureEnsemble, removeEnsemble,
        %   factoryReset

            arguments
                args.name {mustBeTextScalar}
                args.datastore fileEnsembleDatastore
            end

            logger = SFRFsLogger.getLogger();
            name = string(args.name);
            m = EnsembleDatastoreRegistry.MAP;

            if isKey(m, name)
                logger.info(sprintf( ...
                    'Overwriting ensemble "%s". Previous class: %s', ...
                    char(name), class(m(name))));
            end

            m(name) = args.datastore;
            % update persistent in-memory dictionary
            EnsembleDatastoreRegistry.MAP(m);
            EnsembleDatastoreRegistry.persistMap(m);
            logger.info(sprintf('Ensemble "%s"added.',char(name)));
        end

        function names = getAllEnsembleNames()
        % getAllEnsembleNames Return names of all registered ensembles
        %
        %   names = EnsembleDatastoreRegistry.getAllEnsembleNames()
        %   returns a string array containing the names of all 
        %   ensembles currently registered in the factory.
        %
        %   Output:
        %       names - String array of ensemble names.
        %
        %   Example:
        %       allNames = ...
        %           EnsembleDatastoreRegistry.getAllEnsembleNames();
        %       disp(allNames);
        %
        %   See also: hasEnsemble, getEnsemble, addEnsemble

            m = EnsembleDatastoreRegistry.MAP;
            names = string(keys(m));
        end


        function datastore = getEnsemble(name)
        % getEnsemble Retrieve a registered ensemble by name
        %
        %   datastore = EnsembleDatastoreRegistry.getEnsemble(name)
        %   returns the fileEnsembleDatastore object registered under
        %   the specified name. Throws an error if no ensemble with
        %   that name exists.
        %
        %   Input:
        %       name - Text scalar specifying the ensemble name.
        %
        %   Output:
        %       datastore - The registered fileEnsembleDatastore.
        %
        %   Example:
        %       ds = ...
        %          EnsembleDatastoreRegistry.getEnsemble("myEnsemble");
        %
        %   See also: hasEnsemble, addEnsemble, getAllEnsembleNames

            arguments
                name {mustBeTextScalar}
            end

            name = string(name);
            m = EnsembleDatastoreRegistry.MAP;

            if ~isKey(m, name)
                error('sfrfs:EnsembleFactory:NotFound', ...
                    'No ensemble registered with name "%s".', ...
                    char(name));
            end

            datastore = m(name);
        end


        function tf = hasEnsemble(name)
        % hasEnsemble Check if an ensemble is registered
        %
        %   tf = EnsembleDatastoreRegistry.hasEnsemble(name) returns a
        %   logical true if an ensemble with the specified name is
        %   registered in the factory, and false otherwise.
        %
        %   Input:
        %       name - Text scalar specifying the ensemble name.
        %
        %   Output:
        %       tf - Logical scalar: true if ensemble exists, false if not.
        %
        %   Example:
        %       if EnsembleDatastoreRegistry.hasEnsemble("myEnsemble")
        %           disp("Ensemble exists!");
        %       else
        %           disp("Ensemble not found.");
        %       end
        %
        %   See also: getEnsemble, getAllEnsembleNames, addEnsemble

            arguments
                name {mustBeTextScalar}
            end

            name = string(name);
            m = EnsembleDatastoreRegistry.MAP;
            tf = isKey(m, name);
        end


        function ds = reconfigureEnsemble(args)
        % reconfigureEnsemble Update configuration of a registered ensemble
        %
        %   ds = EnsembleDatastoreRegistry.reconfigureEnsemble(Name, ...)
        %   updates the properties of an existing registered
        %   fileEnsembleDatastore, including DataVariables,
        %   IndependentVariables, ConditionVariables, and 
        %   SelectedVariables.
        %   Any property not specified remains unchanged. After updating,
        %   the ensemble is reset and persisted.
        %
        %   Inputs (Name-Value pairs):
        %       'name'                 - Text scalar specifying the 
        %                                ensemble name.
        %       'DataVariables'        - Cell array of char or string array 
        %                              of variable names for data columns.
        %       'IndependentVariables' - Cell array or string array of
        %                              independent variable names.
        %       'ConditionVariables'   - Cell array or string array of
        %                              condition variable names.
        %       'SelectedVariables'    - Cell array or string array of 
        %                              variables to select for processing.
        %
        %   Output:
        %       ds - The updated fileEnsembleDatastore object.
        %
        %   Behavior:
        %       - Logs before/after values for each updated property.
        %       - Resets the ensemble after updates.
        %       - Updates in-memory map and persists changes to disk.
        %
        %   Example:
        %       ds = EnsembleDatastoreRegistry.reconfigureEnsemble( ...
        %           name = "myEnsemble", ...
        %           DataVariables = ["Signal1", "Signal2"], ...
        %           SelectedVariables = ["Signal1"]);
        %
        %   See also: addEnsemble, removeEnsemble, getEnsemble, hasEnsemble

            arguments
                args.name {mustBeTextScalar}
                args.DataVariables ...
                    {EnsembleDatastoreRegistry.mustBeCellOrString} = {}
                args.IndependentVariables ...
                    {EnsembleDatastoreRegistry.mustBeCellOrString} = {}
                args.ConditionVariables ...
                    {EnsembleDatastoreRegistry.mustBeCellOrString} = {}
                args.SelectedVariables ...
                    {EnsembleDatastoreRegistry.mustBeCellOrString} = {}
            end
        
            name = string(args.name);
            m = EnsembleDatastoreRegistry.MAP;
        
            if ~isKey(m, name)
                error('sfrfs:EnsembleFactory:NotFound', ...
                    'No ensemble registered with name "%s".', char(name));
            end
        
            ds = m(name);  % Retrieve actual datastore object
            logger = SFRFsLogger.getLogger();
        
            % Update DataVariables
            if ~isempty(args.DataVariables)
                oldVal = ds.DataVariables;
                ds.DataVariables = string(args.DataVariables);
                logger.info(sprintf(...
                    ['Ensemble "%s": DataVariables updated.\n' ...
                    'Before: [%s]\nAfter : [%s]'], ...
                    char(name), strjoin(oldVal, ', '), ...
                    strjoin(ds.DataVariables, ', ')));
            end
        
            % Update IndependentVariables
            if ~isempty(args.IndependentVariables)
                oldVal = ds.IndependentVariables;
                ds.IndependentVariables = ...
                    string(args.IndependentVariables);
                logger.info(sprintf(...
                    ['Ensemble "%s": IndependentVariables updated.\n' ...
                    'Before: [%s]\nAfter : [%s]'], ...
                    char(name), strjoin(oldVal, ', '), ...
                    strjoin(ds.IndependentVariables, ', ')));
            end
        
            % Update ConditionVariables
            if ~isempty(args.ConditionVariables)
                oldVal = ds.ConditionVariables;
                ds.ConditionVariables = string(args.ConditionVariables);
                logger.info(sprintf(...
                    ['Ensemble "%s": ConditionVariables updated.\n' ...
                    'Before: [%s]\nAfter : [%s]'], ...
                    char(name), strjoin(oldVal, ', '), ...
                    strjoin(ds.ConditionVariables, ', ')));
            end
        
            % Update SelectedVariables
            if ~isempty(args.SelectedVariables)
                oldVal = ds.SelectedVariables;
                ds.SelectedVariables = string(args.SelectedVariables);
                logger.info(sprintf(...
                    ['Ensemble "%s": SelectedVariables updated.\n' ...
                    'Before: [%s]\nAfter : [%s]'], ...
                    char(name), strjoin(oldVal, ', '), ...
                    strjoin(ds.SelectedVariables, ', ')));
            end
        
            % Reset the ensemble
            logger.info(sprintf('Resetting ensemble %s', char(name)));
            reset(ds);
        
            % Store updated datastore
            m(name) = ds;
        
            % update persistent in-memory dictionary
            EnsembleDatastoreRegistry.MAP(m);
            % Persist updated dictionary
            EnsembleDatastoreRegistry.persistMap(m);
        
            logger.info(...
                sprintf('Reconfigured ensemble "%s".', char(name)));
        end


        function removeEnsemble(name)
        % removeEnsemble Delete a registered ensemble by name
        %
        %   EnsembleDatastoreRegistry.removeEnsemble(name) removes the
        %   ensemble with the specified name from the factory. If the
        %   ensemble exists, it is removed from the in-memory map and
        %   changes are persisted to disk. If the ensemble does not
        %   exist, the function does nothing.
        %
        %   Input:
        %       name - Text scalar specifying the ensemble name to remove.
        %
        %   Example:
        %       EnsembleDatastoreRegistry.removeEnsemble("myEnsemble");
        %
        %   See also: addEnsemble, getEnsemble, hasEnsemble, factoryReset

            arguments
                name {mustBeTextScalar}
            end

            name = string(name);
            m = EnsembleDatastoreRegistry.MAP;

            if isKey(m, name)
                % since m is no handle
                m = remove(m, name);
                EnsembleDatastoreRegistry.persistMap(m);
                % update persistent in-memory dictionary
                EnsembleDatastoreRegistry.MAP(m);

                logger = SFRFsLogger.getLogger();
                logger.info(sprintf( ...
                    'Removed ensemble "%s".', char(name)));
            end
        end

        function factoryReset()
        % factoryReset Remove all registered ensembles from the factory
        %
        %   EnsembleDatastoreRegistry.factoryReset() deletes all
        %   ensembles currently registered in the factory. The in-memory
        %   map is cleared and the changes are persisted to disk. Logs the
        %   number of ensembles removed.
        %
        %   Example:
        %       EnsembleDatastoreRegistry.factoryReset();
        %
        %   See also: removeEnsemble, addEnsemble, getAllEnsembleNames

            m = EnsembleDatastoreRegistry.MAP;

            removedKeys = keys(m);
            m = remove(m, removedKeys);
            EnsembleDatastoreRegistry.persistMap(m);
            % update persistent in-memory dictionary
            EnsembleDatastoreRegistry.MAP(m);

            logger = SFRFsLogger.getLogger();
            logger.info(sprintf( ...
                'EnsembleFactory reset: removed %d ensembles.', ...
                numel(removedKeys)));
        end
    end

    methods (Static, Access = private)

        function m = MAP(newMap)
            persistent MAPobj

            if ~isfolder(EnsembleDatastoreRegistry.ENSEMBLE_FOLDER)
                mkdir(EnsembleDatastoreRegistry.ENSEMBLE_FOLDER);
            end

            if nargin > 0
                MAPobj = newMap;   % update persistent variable
            end

            if isempty(MAPobj)
                mapFile = EnsembleDatastoreRegistry.ENSEMBLE_MAP_FILE;
                if isfile(mapFile)
                    S = load(mapFile, 'm');
                    MAPobj = S.m;
                else
                    MAPobj = ...
                        configureDictionary(...
                        "string", "fileEnsembleDatastore");
                end
            end

            m = MAPobj;
        end


        function persistMap(m)
            mapFile = EnsembleDatastoreRegistry.ENSEMBLE_MAP_FILE;
            logger = SFRFsLogger.getLogger();

            try
                save(mapFile, 'm', '-v7.3');
                logger.info('Ensemble factory saved.');
            catch ME
                logger.severe(sprintf( ...
                    'Failed to persist EnsembleFactory map: %s', ...
                    ME.message));
                rethrow(ME);
            end
        end

        function mustBeCellOrString(x)
            if ~(iscellstr(x) || isstring(x))
                error(...
                    'Expected string array or cell array of char.');
            end
        end
    end
end
