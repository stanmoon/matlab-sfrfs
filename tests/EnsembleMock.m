classdef EnsembleMock < handle
    properties
        numMembers (1,1) double {mustBePositive, mustBeInteger} = 3
        minSnapshots (1,1) double {mustBePositive, mustBeInteger} = 5
        maxSnapshots (1,1) double {mustBePositive, mustBeInteger} = 10
        nSamples (1,1) double {mustBePositive, mustBeInteger} = 32768
        speeds double = [35; 37.5; 40]
        loads double = [12; 11; 10]
        temporalSnapshotColumns cell = ...
            {'HorizontalAcceleration', 'VerticalAcceleration'}
        ensembleDataFolder char = ''
        fileEnsembleDS
    end
    
    methods
        function obj = EnsembleMock(args)
            arguments
                args.numMembers (1,1) double ...
                    {mustBePositive, mustBeInteger} = 15
                args.minSnapshots (1,1) double ...
                    {mustBePositive, mustBeInteger} = 5
                args.maxSnapshots (1,1) double ...
                    {mustBePositive, mustBeInteger} = 10
                args.nSamples (1,1) double ...
                    {mustBePositive, mustBeInteger} = 32768
                args.speeds double = [35; 37.5; 40]
                args.loads double = [12; 11; 10]
                args.temporalSnapshotColumns cell = ...
                    {'HorizontalAcceleration', 'VerticalAcceleration'}
            end
            obj.numMembers = args.numMembers;
            obj.minSnapshots = args.minSnapshots;
            obj.maxSnapshots = args.maxSnapshots;
            obj.nSamples = args.nSamples;
            obj.speeds = args.speeds;
            obj.loads = args.loads;
            obj.temporalSnapshotColumns = args.temporalSnapshotColumns;
        end
        
        function prepare(obj)
            % Creates temp folder and saves ensemble files with random data
            if ~isempty(obj.ensembleDataFolder) && ...
                    isfolder(obj.ensembleDataFolder)
                rmdir(obj.ensembleDataFolder,'s');
            end
            obj.ensembleDataFolder = tempname;
            mkdir(obj.ensembleDataFolder);
        
            for i = 1:obj.numMembers
                nSnapshots = randi([obj.minSnapshots, obj.maxSnapshots]);
                HorizontalAcceleration = cell(nSnapshots,1);
                VerticalAcceleration = cell(nSnapshots,1);
                for j = 1:nSnapshots
                    HorizontalAcceleration{j} = randn(obj.nSamples,1);
                    VerticalAcceleration{j} = randn(obj.nSamples,1);
                end
        
                SnapshotIndex = (1:nSnapshots).';
                Speed = repmat(obj.speeds(min(i,end)), nSnapshots,1);
                Load = repmat(obj.loads(min(i,end)), nSnapshots,1);
        
                ensembleMemberTable = table( ...
                    HorizontalAcceleration, ...
                    VerticalAcceleration, ...
                    Speed, ...
                    Load, ...
                    SnapshotIndex);
        
                filename = fullfile(...
                    obj.ensembleDataFolder, ...
                    sprintf('member_%03d.mat', i));
                save(filename, 'ensembleMemberTable');
            end
        
            % Create datastore
            ds = fileEnsembleDatastore(obj.ensembleDataFolder, '.mat');
            
            % Set categories
            ds.DataVariables = obj.temporalSnapshotColumns;          
            ds.ConditionVariables = {'Speed', 'Load'};
            ds.IndependentVariables = {'SnapshotIndex'};
            
            % SelectedVariables
            ds.SelectedVariables = [...
                ds.DataVariables.', ...
                ds.ConditionVariables.', ...
                ds.IndependentVariables];

            ds.ReadFcn = @EnsembleMock.readMember;
            ds.WriteToMemberFcn = @EnsembleMock.writeMember;


            obj.fileEnsembleDS = ds;
        end


        function cleanup(obj)
            % Delete the ensemble data folder and contents
            if ~isempty(obj.ensembleDataFolder) && ...
                    isfolder(obj.ensembleDataFolder)
                rmdir(obj.ensembleDataFolder, 's');
                obj.ensembleDataFolder = '';
            end
        end
    end

    methods (Static)
        function data = readMember(filename, selectedVars)
            tbl = ...
                load(filename, 'ensembleMemberTable').ensembleMemberTable;
            data = tbl(:, ...
                intersect(...
                selectedVars, tbl.Properties.VariableNames, 'stable'));
            SFRFsLogger.getLogger().info(...
                sprintf('Reading %s: %s', ...
                filename, strjoin(selectedVars, ', ')));
        end

        function writeMember(filename, data)
            % Load existing table
            S = load(filename, 'ensembleMemberTable');
            tbl = S.ensembleMemberTable;

            % Add or overwrite each field in the table
            fields = fieldnames(data);
            for k = 1:numel(fields)
                tbl.(fields{k}) = data.(fields{k});
            end

            % Save back
            ensembleMemberTable = tbl;
            save(filename, 'ensembleMemberTable');

            % Logging
            SFRFsLogger.getLogger().info( ...
                sprintf('Writing %s: %s', filename, strjoin(fields, ', ')));
        end

    end

end
