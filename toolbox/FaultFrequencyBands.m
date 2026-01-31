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
        %   The band matrices are sorted lexicographically by minimum 
        %   frequency, harmonic, and sideband index.

            arguments
                faultBandsTable table
                row (1,1) {mustBeInteger, mustBePositive}
            end

            if row > height(faultBandsTable)
                error("sfrfs:extractBands:Badsubscript", ...
                    "Row index exceeds number of table rows.");
            end

            import tables.FaultBandsTableSchema
            import structs.FaultBandsExtractSchema
            import dicts.BandMapSchema
            import structs.OpponentBandsSchema

            % Schema keys (table)
            kFaultGroupT = FaultBandsTableSchema.FAULTGROUP;
            kSpeedT = FaultBandsTableSchema.SPEED;
            kLoadT = FaultBandsTableSchema.LOAD;
            kRfbT = FaultBandsTableSchema.RECEPTIVEFIELDBANDS;

            % Schema keys (band map)
            kBands = BandMapSchema.BANDS;
            kHar = BandMapSchema.HARMONIC;
            kSide = BandMapSchema.SIDEBAND;

            % Schema keys (opponent bands struct)
            kCenterBand = OpponentBandsSchema.CENTER;
            kSurBand = OpponentBandsSchema.SURROUND;

            % Schema keys (output struct)
            kFaultGroup = FaultBandsExtractSchema.FAULTGROUP;
            kSpeed = FaultBandsExtractSchema.SPEED;
            kLoad = FaultBandsExtractSchema.LOAD;

            kN = FaultBandsExtractSchema.NUMBEROFBANDS;

            kMinCol = FaultBandsExtractSchema.MINFREQCOLUMN;
            kMaxCol = FaultBandsExtractSchema.MAXFREQCOLUMN;
            kHarCol = FaultBandsExtractSchema.HARMONICCOLUMN;
            kSideCol = FaultBandsExtractSchema.SIDEBANDCOLUMN;

            kCfIdx = FaultBandsExtractSchema.CHARACTERISTICFREQUENCYINDEX;

            kCenterMat = FaultBandsExtractSchema.CENTERBANDSMATRIX;
            kSurMat = FaultBandsExtractSchema.SURROUNDBANDSMATRIX;

            faultGroup = faultBandsTable{row, kFaultGroupT};
            speed = faultBandsTable{row, kSpeedT};
            load = faultBandsTable{row, kLoadT};

            cellarraybands = faultBandsTable{row, kRfbT};

            if isa(cellarraybands, "containers.Map")
                cellarraybands = {cellarraybands};

            elseif iscell(cellarraybands)
                if isscalar(cellarraybands) && iscell(cellarraybands{1})
                    cellarraybands = cellarraybands{1};
                end

                isMap = cellfun(@(x) isa(x, "containers.Map"), ...
                    cellarraybands);
                if ~all(isMap)
                    error("sfrfs:extractBands:InvalidBandContainer", ...
                        "%s must contain containers.Map objects.", kRfbT);
                end
            else
                error("sfrfs:extractBands:InvalidBandContainer", ...
                    "Unexpected type in %s.", kRfbT);
            end

            N = numel(cellarraybands);

            bands = struct();
            bands.(kFaultGroup) = faultGroup;
            bands.(kSpeed) = speed;
            bands.(kLoad) = load;

            bands.(kN) = N;

            bands.(kMinCol) = 1;
            bands.(kMaxCol) = 2;
            bands.(kHarCol) = 3;
            bands.(kSideCol) = 4;

            bands.(kCfIdx) = NaN;

            minCol = bands.(kMinCol);
            maxCol = bands.(kMaxCol);
            harCol = bands.(kHarCol);
            sideCol = bands.(kSideCol);

            centerMat = [zeros(N, 4), (1:N)'];
            surMat = centerMat;

            characteristicOriginalIdx = NaN;

            for i = 1:N
                m = cellarraybands{i};
                b = m(kBands);

                centerMat(i, minCol) = b.(kCenterBand)(1);
                centerMat(i, maxCol) = b.(kCenterBand)(2);

                surMat(i, minCol) = b.(kSurBand)(1);
                surMat(i, maxCol) = b.(kSurBand)(2);

                h = m(kHar);
                sb = m(kSide);

                centerMat(i, harCol) = h;
                centerMat(i, sideCol) = sb;

                surMat(i, harCol) = h;
                surMat(i, sideCol) = sb;

                if h == 1 && sb == 0
                    characteristicOriginalIdx = i;
                end
            end

            sortedCenter = sortrows(centerMat, [minCol, harCol, sideCol]);
            perm = sortedCenter(:, end);

            bands.(kCenterMat) = sortedCenter(:, 1:end-1);
            bands.(kSurMat) = surMat(perm, 1:end-1);

            if ~isnan(characteristicOriginalIdx)
                bands.(kCfIdx) = ...
                    find(perm == characteristicOriginalIdx, 1);
            end

            bands = orderfields(bands);
        end

    end
end
