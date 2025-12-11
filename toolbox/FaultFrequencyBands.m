classdef (Abstract) FaultFrequencyBands < handle
    % FaultFrequencyBands Abstract frequency bands class agnostic to the
    %   system or component.
    %
    %   Provides a contract for classes representing characteristic
    %   fault frequency bands, including common properties and abstract
    %   interfaces for fault type descriptions and mappings.
    %
    % Properties (Abstract, Constant):
    %   faultFrequencyCodes       - Struct or map of fault frequency codes.
    %   faultTypeDescriptions     - Cell array of fault type description 
    %                               strings.
    %   faultTypeGroups           - Numeric or categorical grouping of 
    %                               fault types.
    %   faultGroupToTypeName      - Inverse of faultTypeGroups
    %
    %
    % Concrete Properties:
    %   operatingConditions       - OperatingConditions object
    %   sfrfsParams               - Parameters for SFRFs computation
    %   bandsTable                - Table with computed fault bands.
    %
    % Methods (Abstract):
    %   computeBands 
    %                             - Abstract signature 
    %                               the method should build the fault 
    %                               frequency bands table.
    %
    %   computeBands( operatingConditions)
    %   computes the fault frequency bands for each row in the
    %   faultBandsTable table.
    %
    %   Output table columns:
    %       FaultGroup          - numeric index of the fault band entry
    %       Description         - human-readable fault type description 
    %                             (e.g. "Outer Race Fault")
    %       Speed                - shaft rotational speed (Hz)
    %       Load                - load value from operatingConditions
    %       ReceptiveFieldBands - cell containing the bands definition 
    %                             as a collection of instances of 
    %                             containers.Map, each map with keys:
    %                               'Bands', 
    %                               'Harmonic', 
    %                               'Label', 
    %                               'Sideband'
    %
    %   Example (usage with rolling bearings, for implementation example
    %            see code in BearingFrequencyBands/computeBands):
    %
    %       % 1. Set the operating conditions
    %       speed = [35; 37.5; 40];
    %       load  = [12; 11; 10];
    %       ocObj = OperatingConditions(speed, load);
    % 
    %       % 2. Bearing + SRF params
    %       bp = ParametersRollingBearings( ...
    %           'numRollingElements',8, ...
    %           'ballDiameter',7.92, ...
    %           'pitchDiameter',34.55, ...
    %           'contactAngle',0);
    % 
    %       sharedParams = ...
    %         SFRFsParameters.createSFRFsParameters( ...
    %           'order', 3, ...
    %           'numSidebands', 4, ...
    %           'numHarmonics', 8, ...
    %           'sigmaCenter', [5, 7], ...
    %           'sigmaSurround', [12, 3], ...
    %           'inhibitionFactor', 0.6);
    %
    %       sp = SFRFsParametersRollingBearings( ...
    %           'SameForAllFaultTypes', sharedParams);
    %
    %
    %       % 3. Create object instance
    %       bfb = BearingFrequencyBands( ...
    %           bearingParams = bp, ...
    %           sfrfsParams = sp, ...
    %           operatingConditions = ocObj);
    %
    %       % 4. Compute fault bands
    %       bfb.computeBands();
    %
    %   Notes:
    %       FaultGroup numeric index and Label in ReceptiveFieldBands 
    %       entries  are compatible with MATLAB's function 
    %       'bearingFaultBands' introduced in 
    %       Predictive Maintenance Toolbox R2019b
    %
    % See also: BearingFrequencyBands, ReceptiveFieldGainFunctions

    
    properties (Abstract, Constant)
        faultFrequencyCodes
        faultTypeDescriptions
        faultTypeGroups
        faultGroupToTypeName
    end
    
    properties (Access = private)
        % sfrfsParamsInternal stores the actual data internally.
        % It bypasses MATLAB limitations on abstract typed properties,
        % preventing runtime instantiation errors.
        % Type validation is enforced only once in the constructor.
        sfrfsParamsInternal 
    end

    properties (Dependent)
        % sfrfsParams exposes read-only access to sfrfsParamsInternal.
        % Declared as Dependent to avoid internal storage conflicts.
        % This pattern avoids MATLAB runtime errors related to abstract
        % property validation and allows association visibility in the 
        % 'Class Diagram Viewer'.
        % Clients should access sfrfsParams only; direct assignment is 
        % prohibited.
        %
        % A getter method returns sfrfsParamsInternal transparently.
        %
        % Validation of assigned values is performed only on the private 
        % property.
        sfrfsParams SFRFsParameters
    end

    properties 
        operatingConditions OperatingConditions
        bandsTable table = table.empty()
    end

        methods

        function obj = FaultFrequencyBands(args)
            arguments
                args.operatingConditions (1,1) OperatingConditions
                args.sfrfsParams (1,1) SFRFsParameters
            end
            obj.operatingConditions = args.operatingConditions;
            if isa(args.sfrfsParams,'SFRFsParameters')
                obj.sfrfsParamsInternal = args.sfrfsParams;
            else
                error( ...
                    ['sfrfs:FaultFrequencyBands:'...
                     'TypeMismatchError'],...
                    'object must be instance of SFRFsParameters.');
            end
        end

        % Getter only to enforce validation at construction time
        % circunventing limitations of abstract classes in properties
        function val = get.sfrfsParams(obj)
            val = obj.sfrfsParamsInternal; 
        end

    end
    
    methods (Abstract)

        computeBands( obj, operatingConditions)
        % computeBands  Abstract signature 
        %   the method should build the fault frequency bands table.
        %
        %   computeBands( operatingConditions)
        %   computes the fault frequency bands for each row in the
        %   faultBandsTable table.
        %
        %   Output table columns:
        %       FaultGroup          - numeric index of the fault band entry
        %       Description         - human-readable fault type description 
        %                             (e.g. "Outer Race Fault")
        %       Speed                - shaft rotational speed (Hz)
        %       Load                - load value from operatingConditions
        %       ReceptiveFieldBands - cell containing the bands definition 
        %                             as a collection of instances of 
        %                             containers.Map, each map with keys:
        %                               'Bands', 
        %                               'Harmonic', 
        %                               'Label', 
        %                               'Sideband'
        %
        %   Example (with rolling bearings):
        %
        %       % 1. Set the operating conditions
        %       speed = [35; 37.5; 40];
        %       load  = [12; 11; 10];
        %       ocObj = OperatingConditions(speed, load);
        % 
        %       % 2. Bearing + SRF params
        %       bp = ParametersRollingBearings( ...
        %           'numRollingElements',8, ...
        %           'ballDiameter',7.92, ...
        %           'pitchDiameter',34.55, ...
        %           'contactAngle',0);
        % 
        %       sharedParams = ...
        %         SFRFsParameters.createSfrfsParameters( ...
        %           'order', 3, ...
        %           'numSidebands', 4, ...
        %           'numHarmonics', 8, ...
        %           'sigmaCenter', [5, 7], ...
        %           'sigmaSurround', [12, 3], ...
        %           'inhibitionFactor', 0.6);
        %
        %       sp = SFRFsParametersRollingBearings( ...
        %           'SameForAllFaultTypes', sharedParams);
        %
        %
        %       % 3. Create object instance
        %       bfb = BearingFrequencyBands(bp, sp);
        %
        %       % 4. Compute fault bands
        %       bfb .computeBands(ocObj);
        %
        %   Notes:
        %       FaultGroup numeric index and Label in ReceptiveFieldBands 
        %       entries  are compatible with MATLAB's function 
        %       'bearingFaultBands' introduced in 
        %       Predictive Maintenance Toolbox R2019b
    end

    methods (Static)

        function bands = extractBands(faultBandsTable, row)
        %EXTRACTBANDS Extract and sort band matrices from a table row.
        %   bands = extractBands(faultBandsTable, row) extracts band 
        %   information from the specified row of faultBandsTable and 
        %   returns a struct with metadata and sorted matrices for center 
        %   and surround frequency bands.
        %
        %   Parameters:
        %       faultBandsTable - Table containing fault band data, 
        %                         including a 'ReceptiveFieldBands' column 
        %                         with band definitions.
        %       row             - Row index (positive integer) specifying 
        %                         which row to extract and process.
        %
        %   Output:
        %       bands - Struct with fields:
        %           FaultGroup                   - Fault group identifier
        %           Speed                        - Operating speed
        %           Load                         - Operating load
        %           NumberOfBands                - Number of bands in this 
        %                                          row
        %           MinFreqColumn                - Index for minimum 
        %                                          frequency
        %           MaxFreqColumn                - Index for maximum 
        %                                          frequency
        %           HarmonicColumn               - Index for harmonic 
        %                                          column
        %           SidebandColumn               - Index for sideband 
        %                                          column
        %           CharacteristicFrequencyIndex - Index of characteristic 
        % band
        %           CenterBandsMatrix            - Sorted matrix for center 
        %                                          bands
        %           SurroundBandsMatrix          - Sorted matrix for 
        %                                          surround bands
        %
        %   The band matrices are sorted lexicographically by minimum 
        %   frequency, harmonic, and sideband index.
        %
        %   Example:
        %     speeds = [35; 37.5; 40];
        %     loads  = [12; 11; 10];
        %     operatingConditions = ...
        %       createOperatingConditions(speeds, loads);
        %     bearingParams = bearingParameters(...
        %       'NumRollingElements',8,...
        %       'BallDiameter',7.92,...
        %       'PitchDiameter',34.55,...
        %       'ContactAngle',0);
        %     sfrfsParams = sfrfsParameters(...
        %       'NumHarmonics', 10,... 
        %       'NumSidebands', 2,... 
        %       'SigmaCenter', [4, 6],... 
        %       'SigmaSurround', [12, 1]);
        %     faultBandsTable = computeFaultFrequencyBands(...
        %       operatingConditions, ...
        %       bearingParams, ...
        %       sfrfsParams);
        %       bands = extractBands(faultBandsTable, 2);
        %   See also: bearingParameters, createOperatingConditions,
        %     sfrfsParameters, computeFaultFrequencyBands
        
            arguments
                faultBandsTable table
                row (1,1) {mustBeInteger, mustBePositive}
            end
        
            if row > height(faultBandsTable)
                error('sfrfs:extractBands:Badsubscript',...
                    'Row index exceeds number of table rows.');
            end
        
            % Extract the nested cell array structure
            faultGroup = faultBandsTable{row,'FaultGroup'};
            speed = faultBandsTable{row,'Speed'};
            load = faultBandsTable{row,'Load'};


            cellarraybands = faultBandsTable{row, 'ReceptiveFieldBands'};

            % Normalise to 1×N cell array of containers.Map
            if isa(cellarraybands, 'containers.Map')
                % Single map → wrap into cell
                cellarraybands = {cellarraybands};

            elseif iscell(cellarraybands)

                % Unwrap single nested cell: {{maps...}}
                if isscalar(cellarraybands) && iscell(cellarraybands{1})
                    cellarraybands = cellarraybands{1};
                end

                % Final safety: must be cell of maps
                if ~all(cellfun(@(x) ...
                        isa(x,'containers.Map'), cellarraybands))
                    error('sfrfs:extractBands:InvalidBandContainer', ...
                        'ReceptiveFieldBands must contain containers.Map');
                end
            else
                error('sfrfs:extractBands:InvalidBandContainer', ...
                    'Unexpected type in ReceptiveFieldBands.');
            end

            N = numel(cellarraybands);
        
            % Create info object for the user
            bands = struct();
            bands.FaultGroup = faultGroup;
            bands.Speed = speed;
            bands.Load = load;
            bands.NumberOfBands = N;
            bands.MinFreqColumn = 1;
            bands.MaxFreqColumn = 2;
            bands.HarmonicColumn = 3;
            bands.SidebandColumn = 4;
            bands.CharacteristicFrequencyIndex = NaN; 
        
            % create the double matrix to contain the output
            bands.CenterBandsMatrix = [zeros(N,4),(1:N)'];
            bands.SurroundBandsMatrix = bands.CenterBandsMatrix;
        
            % fill the matrix first, in the order they are in the cell 
            % array
            for i=1:N
                celldict = cellarraybands{i};
                bands.CenterBandsMatrix(i,bands.MinFreqColumn) = ...
                    celldict('Bands').Center(1);
                bands.CenterBandsMatrix(i,bands.MaxFreqColumn) = ...
                    celldict('Bands').Center(2);
                bands.CenterBandsMatrix(i,bands.HarmonicColumn) = ...
                    celldict('Harmonic');
                bands.CenterBandsMatrix(i,bands.SidebandColumn) = ...
                    celldict('Sideband');
                bands.SurroundBandsMatrix(i,bands.MinFreqColumn) = ...
                    celldict('Bands').Surround(1);
                bands.SurroundBandsMatrix(i,bands.MaxFreqColumn) = ...
                    celldict('Bands').Surround(2);
                bands.SurroundBandsMatrix(i,bands.HarmonicColumn) = ...
                    celldict('Harmonic');
                bands.SurroundBandsMatrix(i,bands.SidebandColumn) = ...
                    celldict('Sideband');      
                if celldict('Harmonic') == 1 && celldict('Sideband') == 0
                    bands.CharacteristicFrequencyIndex = i;
                end
            end
            
            % Sort lexicographically by lower frequency, harmonic, then 
            % sideband
            sortedMat = sortrows(bands.CenterBandsMatrix, ...
                [bands.MinFreqColumn, bands.HarmonicColumn, ...
                 bands.SidebandColumn]);
            % remove auxiliary column
            bands.CenterBandsMatrix = sortedMat(:,1:end-1);
            bands.SurroundBandsMatrix = ...
                bands.SurroundBandsMatrix(sortedMat(:,end), 1:end-1);
            bands = orderfields(bands);
        end
    end
end
