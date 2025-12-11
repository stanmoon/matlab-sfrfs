classdef EnsembleBroker < handle
% EnsembleBroker Concrete wrapper for ensemble-like objects.
%
%   Wraps an arbitrary ensemble object and delegates the getFiles call
%   to a provided method handle.
%   Example:
%       broker = SFRFsEnsembleBroker( ...
%           'ensembleObject', fileEnsembleDS, ...
%           'getFilesFunction', fcnHandle, ...
%           'temporalSnapshotColumns', temporalSnapshotColumns)
%
%   See also: EnsembleBroker/getFiles
    
    properties (Access = private)
        % Wrapped ensemble object.
        ensembleInternal         
        % Function handle for member files.
        getFilesFcn function_handle                     
        % sortField Field column name in ensemble
        % (default: 'SnapshotIndex')
        sortFieldInternal (1,1) string = "SnapshotIndex"
        % memberTableVarName Variable name in MAT-files 
        % (default: 'ensembleMemberTable')
        memberTableVarNameInternal (1,1) string = "ensembleMemberTable"
        % Column names containing the snapshots in the time domain.
        temporalSnapshotColumnsInternal (1,:) cell = {}
        % Suffix for column names of snapshots' spectra
        spectralSuffixInternal (1,1) string = "_FFT"      
    end

    properties (Dependent)
        ensemble {mustBeNonempty}
        sortField (1,1) string
        memberTableVarName (1,1) string
        temporalSnapshotColumns (1,:) cell
        spectralSuffix (1,1) string
    end
    
    methods

        function obj = EnsembleBroker(args)
        % EnsembleBroker Construct an EnsembleBroker wrapper.
        %
        %   obj = EnsembleBroker(...
        %           'ensembleObject', ensembleObject, ...
        %           'getFilesFunction', functionHandle, ...
        %           'temporalSnapshotColumns', columns) creates an 
        %   EnsembleBroker instance wrapping ENSEMBLEOBJ.
        %
        %   Inputs:
        %     ensembleObject         -  The underlying ensemble object to 
        %                               wrap.
        %     getFilesFunction       -  Function handle, returns member 
        %                               files.
        %     temporalSnapshotColumns - Cell array of char vectors 
        %                               specifying 
        %                               ensemble table column names that 
        %                               contain temporal signal snapshots. 
        %     sortField              -  Field name used for sorting the 
        %                               ensemble tables.
        %                               Default is "SnapshotIndex".
        %     memberTableVarName     -  Variable name inside MAT-files 
        %                               storing member table. 
        %                               Default is "ensembleMemberTable".
        %     spectralSuffix          - Suffix for spectral column names.
        %                               Default: "_FFT".
        %
        %   This wrapper delegates file listing to GETFILESFNC and stores 
        %   metadata about temporal signal snapshot columns.
        %
            arguments
                args.ensembleObject {mustBeNonempty}
                args.getFilesFunction function_handle
                args.temporalSnapshotColumns (1,:) cell ...
                    {EnsembleBroker.mustBeCellOfTextScalars}
                args.sortField (1,1) string = "SnapshotIndex"
                args.memberTableVarName (1,1) string = ...
                    "ensembleMemberTable"
                args.spectralSuffix (1,1) string = "_FFT"
            end
            obj.ensembleInternal = args.ensembleObject;
            obj.getFilesFcn = args.getFilesFunction;
            obj.temporalSnapshotColumnsInternal = ...
                args.temporalSnapshotColumns;
            obj.sortFieldInternal = args.sortField;
            obj.memberTableVarNameInternal = args.memberTableVarName;
            obj.spectralSuffixInternal = string(args.spectralSuffix);
        end


        function files = getFiles(obj)
        % getFiles Retrieve ensemble member file identifiers.
        %
        %   files = obj.getFiles() calls the stored function handle 
        %   'getFilesFcn' on the wrapped ensemble object to obtain a 
        %   cell array of member file names or identifiers.
        %
        %   Output:
        %     files - Cell array of strings representing member files.
        %
        %   Usage:
        %     memberFiles = obj.getFiles();
        %
        %   Note:
        %     The getFilesFcn function handle must accept the ensemble 
        %     object as input and return the member files.
            
            files = obj.getFilesFcn(obj.ensemble);
        end
        
        function val = get.ensemble(obj)
        % Getter for ensemble property.
        %
        %   val = obj.ensemble returns the wrapped ensemble object
        %   stored internally.
        %
        %   Output:
        %     val - The ensemble object wrapped by this broker instance.
            
            val = obj.ensembleInternal;
        end

        function val = get.sortField(obj)
            val = obj.sortFieldInternal;
        end

        function val = get.memberTableVarName(obj)
            val = obj.memberTableVarNameInternal;
        end

        function columns = get.temporalSnapshotColumns(obj)
        % Getter for temporalSnapshotColumns property.
        %
        %   val = obj.temporalSnapshotColumns returns the wrapped 
        %   cell array with temporal snapshot column names.
        %
        %   Output:
        %     val - The column names.
            columns = obj.temporalSnapshotColumnsInternal;
        end

        function suffix = get.spectralSuffix(obj)
        % Getter for spectralSuffix property.
        %
        % Returns the suffix string used for spectral column names.

            suffix = obj.spectralSuffixInternal;
        end

        function spectralName = mapToSpectralColumn(obj, columnName) 
        % mapToSpectralColumn Return the spectral column name for a given 
        %   temporal column.
        %
        %   spectralName = obj.mapToSpectralColumn(columnName)
        %
        % Inputs:
        %   columnName - time-domain column name (char or string).
        %
        % Output:
        %   spectralName - corresponding spectral column name.

            suffix = obj.spectralSuffix;
            spectralName = EnsembleUtil.appendSuffix(columnName, suffix);
        end

        function temporalName = mapToTemporalColumn(obj, spectralName)
        % mapToTemporalColumn Return the temporal column name for a given 
        % spectral column.
        %
        %   temporalName = obj.mapToTemporalColumn(spectralName)
        %
        % Inputs:
        %   spectralName - spectral column name (char or string).
        %
        % Output:
        %   temporalName - corresponding time-domain column name.
    
            suffix = obj.spectralSuffix;
            temporalName = EnsembleUtil.removeSuffix(spectralName, suffix);
        end

    
    end

    methods (Static)
        
        function saveEnsembleMember(filename, tableVarName, tbl)
        % saveEnsembleMember Save an ensemble member table to a  
        % MAT-file (.mat).
        %
        %   EnsembleBroker.saveEnsembleMember(...
        %       filename, tableVarName, tbl)
        %   saves the input table 'tbl' with the name defined in 
        %   tableVarName
        %   in the MAT-file specified by 'filename', 
        %   using the -v7.3 format (necessary for big tables).
        %ensemble
        %   Inputs:
        %     filename      - String or character vector specifying the 
        %                     full
        %                     path to the MAT-file where the table will 
        %                     be saved.
        %     tableVarName  - Name of the variable under which to save 
        %                     the table.
        %     tbl           - Table to be saved.
        %
        %   This method centralizes the save logic for ensemble member 
        %   tables, ensuring consistency and simplifying future 
        %   maintenance.
        %
        %   Example:
        %     EnsembleBroker.saveEnsembleMember(...
        %         'member_1.mat', 'ensembleMemberTable', tbl);
        %
        %   See also: save
            arguments
                filename {mustBeTextScalar}
                tableVarName {mustBeTextScalar}
                tbl table
            end
            if ~isvarname(tableVarName)
                error(...
                    'sfrfs:EnsembleBroker:InvalidVarName', ...
                    ['Table variable name "%s" is not a valid MATLAB'''...
                     'identifier.'], tableVarName);
            end

            dataToSave = struct();
            dataToSave.(tableVarName) = tbl;
            save(filename, '-struct', 'dataToSave', '-v7.3');
        end
        
        function tbl = loadEnsembleMember(args)
            % loadEnsembleMember Load (and optionally sort) an ensemble 
            % member table.
            %
            %   tbl = EnsembleBroker.loadEnsembleMember(args)
            %   loads the variable specified by args.MemberTableVarName 
            %   from the MAT-file at args.Filename. If args.Sort is true, 
            %   sorts the table by args.SortField.
            %
            %   Name-Value Arguments:
            %     'filename'           - Path to the MAT-file.
            %     'memberTableVarName' - Variable name to load (default: 
            %                            'ensembleMemberTable').
            %     'sort'               - Logical flag to sort the table 
            %                            (default: true).
            %     'sortField'          - Field name to sort by (default: 
            %                            'SnapshotIndex').
            %
            %   Output:
            %     tbl - Table loaded from the file (sorted if requested).
            %
            %   Example:
            %     tbl = EnsembleBroker.loadEnsembleMember(...
            %         'filename', 'member.mat', ...
            %         'memberTableVarName', 'memberTable', ...
            %         'sort', true, ...
            %         'sortField', 'SnapshotIdx');
            %
            %   See also: load, sortrows
        
            arguments
                args.filename (1,:) {mustBeTextScalar}
                args.memberTableVarName (1,:) {mustBeTextScalar} = ...
                    'ensembleMemberTable'
                args.sort (1,1) logical = true
                args.sortField (1,:) {mustBeTextScalar} = 'SnapshotIndex'
            end
        
            member = load(args.filename, args.memberTableVarName);
        
            if ~isfield(member, args.memberTableVarName)
                error(...
                    ['sfrfs:EnsembleBroker:loadEnsembleMember:',...
                     'MemberTableNotFound'], ...
                     'Member table ''%s'' not found in file %s.', ...
                    args.memberTableVarName, args.filename);
            end

            tbl = member.(args.memberTableVarName);

            if args.sort
                if ~ismember(args.sortField, tbl.Properties.VariableNames)
                    error(...
                        ['sfrfs:EnsembleBroker:',...
                         'loadEnsembleMember:SortingFieldNotFound'], ...
                        ['Sort field ''%s'' not found in table',...
                         ' loaded from %s.'],...
                        args.sortField, args.filename);
                end
                tbl = sortrows(tbl, args.sortField);
            end
        end

    end

    methods (Static, Access = private)
        function mustBeCellOfTextScalars(x)
            if ~iscell(x) || ...
                    ~all(cellfun(@(c) ischar(c) || isStringScalar(c), x))
                error(...
                    'sfrfs:EnsembleBroker:InvalidColumnNames', ...
                    'A cell array with column names is expected')
            end
        end
    end
end
