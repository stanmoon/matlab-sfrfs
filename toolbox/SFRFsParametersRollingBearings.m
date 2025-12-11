classdef SFRFsParametersRollingBearings < SFRFsParameters
% SFRFsParametersRollingBearings  Store and validate SFRF parameters for 
% bearing fault types.
%
%   This value class stores validated Spectral Fault Receptive Field (SFRF) 
%   parameter sets for:
%      - Outer race (BPFO frequency band)
%      - Inner race (BPFI frequency band)
%      - Ball       (BSF frequency band)
%      - Cage       (FTF frequency band)
%
%   Construction uses named (keyword) arguments and supports two modes:
%
%   Mode 1: Individual SFRF parameters per fault type
%     Mode 1 – Individual parameters for each fault type:
%         paramsOuter = ...
%           SFRFsParameters.createSFRFsParameters(...
%           'order',2, 'sigmaCenter',[5,7]);
%         paramsInner = ...
%           SFRFsParameters.createSFRFsParameters(...
%           'order',1, 'numHarmonics',8);
%         paramsBall  = 
%           SFRFsParameters.createSFRFsParameters(...
%           'order',0, 'sigmaCenter',[4,6]);
%         % use defaults
%         paramsCage  = ...
%           SFRFsParameters.createSFRFsParameters();  
%
%         params = SFRFsParametersRollingBearings( ...
%                 'outerRace', paramsOuter, ...
%                 'innerRace', paramsInner, ...
%                 'ball',      paramsBall, ...
%                 'cage',      paramsCage );
%
%   Mode 2: Shared SFRF parameters for all fault types
%     sharedParams = ...
%         SFRFsParameters.createSFRFsParameters( ...
%         'order', 3, ...
%         'numSidebands', 4, ...
%         'numHarmonics', 8, ...
%         'sigmaCenter', [5, 7], ...
%         'sigmaSurround', [12, 3], ...
%         'inhibitionFactor', 0.6);
%
%     obj = SFRFsParametersRollingBearings( ...
%         'SameForAllFaultTypes', sharedParams);
%
%   Reference:
%       Stan Muñoz Gutiérrez and Franz Wotawa. Optimized Spectral Fault 
%       Receptive Fields for Diagnosis-Informed Prognosis. In 36th 
%       International Conference on Principles of Diagnosis and Resilient 
%       Systems (DX 2025). Open Access Series in Informatics (OASIcs), 
%       Volume 136, pp. 9:1-9:20, Schloss Dagstuhl – Leibniz-Zentrum für 
%       Informatik (2025) DOI:10.4230/OASIcs.DX.2025.9.
%
%   See also: SFRFsParameters         

    properties
        outerRace   % SFRF params for Outer race faults
        innerRace   % SFRF params for Inner race faults
        ball        % SFRF params for Ball faults
        cage        % SFRF params for Cage faults
    end

    properties (Constant)
        % Fault type names
        OUTER_RACE_FAULT_TYPE_NAME = 'outerRace'
        INNER_RACE_FAULT_TYPE_NAME = 'innerRace'
        BALL_FAULT_TYPE_NAME       = 'ball'
        CAGE_FAULT_TYPE_NAME       = 'cage'
    
        % Collection of all supported fault types
        faultTypes = { ...
            SFRFsParametersRollingBearings.OUTER_RACE_FAULT_TYPE_NAME, ...
            SFRFsParametersRollingBearings.INNER_RACE_FAULT_TYPE_NAME, ...
            SFRFsParametersRollingBearings.BALL_FAULT_TYPE_NAME, ...
            SFRFsParametersRollingBearings.CAGE_FAULT_TYPE_NAME ...
        }
    
    end

    methods
        function obj = SFRFsParametersRollingBearings(args)
            arguments
                args.outerRace struct = struct()
                args.innerRace struct = struct()
                args.ball struct = struct()
                args.cage struct = struct()
                args.SameForAllFaultTypes struct = struct()
            end
            
            isEmptyStr = @SFRFsParametersRollingBearings.isEmptyStruct;
            valInputs = @SFRFsParametersRollingBearings.validateInputs;

            % Validate the input arguments
            valInputs(args);
            
            % Assign properties based on validation
            if ~isEmptyStr(args.SameForAllFaultTypes)
                obj.outerRace = args.SameForAllFaultTypes;
                obj.innerRace = args.SameForAllFaultTypes;
                obj.ball = args.SameForAllFaultTypes;
                obj.cage = args.SameForAllFaultTypes;
                % Set consistent values for sidebands
                % Force Outer & Cage to have 0 sidebands
                obj.outerRace.numSidebands = 0;
                obj.cage.numSidebands      = 0;
            else
                obj.outerRace = args.outerRace;
                obj.innerRace = args.innerRace;
                obj.ball = args.ball;
                obj.cage = args.cage;
                % validate no sidebands for OuterRace and Cage
                SFRFsParametersRollingBearings.validateNoSidebands(...
                obj.outerRace, ...
                SFRFsParametersRollingBearings.OUTER_RACE_FAULT_TYPE_NAME);
                SFRFsParametersRollingBearings.validateNoSidebands(...
                    obj.cage, ...
                    SFRFsParametersRollingBearings.CAGE_FAULT_TYPE_NAME);

            end

            log = SFRFsLogger.getLogger();
            if log.isFineEnabled()
                log.fine(obj.toString())
            end
        end

        function str = toString(obj)
            % toString Return a formatted string representation of the 
            % object.
            
            outerRaceStr = jsonencode(obj.outerRace);
            innerRaceStr = jsonencode(obj.innerRace);
            ballStr = jsonencode(obj.ball);
            cageStr = jsonencode(obj.cage);
            
            str = sprintf(['[SFRFsParametersRollingBearings:', ...
                ' outerRace: %s, innerRace: %s, ball: %s, cage: %s]'], ...
                outerRaceStr, innerRaceStr, ballStr, cageStr);
        end
    end

    methods (Access = private, Static)

        function validateInputs(args)
            isEmptyStr = @SFRFsParametersRollingBearings.isEmptyStruct;
            getMissPar = ...
                @SFRFsParametersRollingBearings.getMissingParameters;

            % Validation when SameForAllFaultTypes is provided:
            if ~isEmptyStr(args.SameForAllFaultTypes)
                if ~isEmptyStr(args.outerRace) || ...
                        ~isEmptyStr(args.innerRace) || ...
                        ~isEmptyStr(args.ball) || ...
                        ~isEmptyStr(args.cage)
                    error(...
                        ['sfrfs:SFRFsParametersRollingBearings:' ...
                        'validateInputs:ConflictingArguments'],...
                        ['Not additional arguments allowed for ' ...
                        'SameForAllFaultTypes option']);
                end
                missingSFRFParams = getMissPar(...
                    'SameForAllFaultTypes', args);
            else
                missingFaults = ...
                    SFRFsParametersRollingBearings.getMissingFaultTypes(...
                    args);
                if ~isempty(missingFaults)
                    error(...
                        ['sfrfs:SFRFsParametersRollingBearings:' ...
                        'validateInputs:MissingArguments'], ...
                        'Missing fault type parameters: %s.', ...
                        strjoin(missingFaults, ', '));
                end
                % validate params of fault types
                fts = SFRFsParametersRollingBearings.faultTypes;
                missingSFRFParams = {};
                for i=1:length(fts)
                    misspars = getMissPar(fts(i), args);
                    if ~isempty(misspars)
                        missingSFRFParams = ...
                            [missingSFRFParams, misspars]; %#ok<AGROW>
                    end
                end
            end
            
            if ~isempty(missingSFRFParams)
                error(...
                    ['sfrfs:SFRFsParametersRollingBearings:' ...
                    'validateInputs:MissingSFRFsParameters'], ...
                    'Missing or incomplete SFRF parameters: %s.', ...
                    strjoin(missingSFRFParams, '; '));
            end
        end

        function tf = isEmptyStruct(s)
            % Helper to check if a struct is empty (no fields)
            tf = isempty(fieldnames(s));
        end

        function missingParams = getMissingParameters(name, args)
            missingParams = {};
            fname = string(name);
            missingFields = ...
                SFRFsParametersRollingBearings.missingPars(args.(fname));
            if ~isempty(missingFields)
                missingParams{end+1} = ...
                    sprintf('%s (missing fields: %s)', ...
                    fname, ...
                    strjoin(missingFields, ', '));
            end
        end

        function missingFaults = getMissingFaultTypes(args)
            isEmptyStr = @SFRFsParametersRollingBearings.isEmptyStruct;
            fts = SFRFsParametersRollingBearings.faultTypes;
            argsStructs = {...
                args.outerRace, args.innerRace, args.ball, args.cage};
            isMissing = cellfun(isEmptyStr, argsStructs);
            missingFaults = fts(isMissing);
        end

        function missingFields = missingPars(paramStruct)

            fields = SFRFsParametersRollingBearings.sfrfFields; 

            % Check which required fields are missing
            missingFields = fields(~isfield(paramStruct, fields));

        end

        function validateNoSidebands(paramStruct, faultTypeName)
            if paramStruct.numSidebands > 0
                error(...
                    ['sfrfs:SFRFsParametersRollingBearings:'...
                    'InvalidNumSidebands'], ...
                    '%s fault type must have NumSidebands = 0.', ...
                    faultTypeName);
            end
        end

    end
end