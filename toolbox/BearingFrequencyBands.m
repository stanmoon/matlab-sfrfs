classdef BearingFrequencyBands < FaultFrequencyBands
% BearingFrequencyBands  Compute bearing fault characteristic frequency 
%   bands
%
%   Computes characteristic and sideband frequency bands for bearing faults 
%   based on bearing geometry and Spectral Fault Receptive Fields (SFRF) 
%   parameters.
%   Supports configurable harmonics, sidebands, and Gaussian bandwidths for 
%   each fault type.
%
% Properties:
%   bearingParams - ParametersRollingBearings object containing bearing 
%                   geometry
%   sfrfsParams   - SFRFsParametersRollingBearings object configuring SFRF 
%                   settings
%
% Constant Properties:
%   BPFO_CODE - Code for Ball Pass Frequency Outer Race ('Fo')
%   BPFI_CODE - Code for Ball Pass Frequency Inner Race ('Fi')
%   BSF_CODE  - Code for Ball Spin Frequency ('Fb')
%   FTF_CODE  - Code for Fundamental Train Frequency (Cage) ('Fc')
%   FR_CODE   - Code for Shaft Rotational Frequency ('Fr')
%   faultFrequencyCodes - Cell array of all fault frequency codes used
%
% Example:
%   % Define bearing geometry
%   bp = ParametersRollingBearings( ...
%       'numRollingElements', 8, ...
%       'ballDiameter', 7.92, ...
%       'pitchDiameter', 34.55, ...
%       'contactAngle', 0);
%
%   sharedParams = ...
%       SFRFsParametersRollingBearings.createSFRFsParameters( ...
%       'order', 3, ...
%       'numSidebands', 4, ...
%       'numHarmonics', 8, ...
%       'sigmaCenter', [5, 7], ...
%       'sigmaSurround', [12, 3], ...
%       'inhibitionFactor', 0.6);
%
%   sp = SFRFsParametersRollingBearings( ...
%       'SameForAllFaultTypes', sharedParams);
%
%   speed = [35; 37.5; 40];
%       load  = [12; 11; 10];
%       ocObj = OperatingConditions(speed, load);
%
%   % Create the BearingFrequencyBands object using named parameters
%   bfb = BearingFrequencyBands( ...
%       bearingParams = bp, ...
%       sfrfsParams = sp, ...
%       operatingConditions = ocObj);
%
%   % Compute frequency bands for a shaft speed of 1500 Hz
%   bands = bfb.computeForSpeed(1500);
%
% See also ParametersRollingBearings, SFRFsParametersRollingBearings


    properties
        bearingParams ParametersRollingBearings
    end

    properties (Constant)
        BPFO_CODE = 'Fo'  % Ball Pass Frequency Outer Race Code
        BPFI_CODE = 'Fi'  % Ball Pass Frequency Inner Race Code
        BSF_CODE = 'Fb'  % Ball Spin Frequency Code
        FTF_CODE = 'Fc'  % Fundamental Train Frequency Code (Cage)
        FR_CODE = 'Fr'  % Shaft Rotational Frequency Code

        % Fault frequency codes as defined in MATLAB bearingFaultBands
        faultFrequencyCodes = { ...
            BearingFrequencyBands.BPFO_CODE, ...
            BearingFrequencyBands.BPFI_CODE, ...
            BearingFrequencyBands.BSF_CODE, ...
            BearingFrequencyBands.FTF_CODE ...
        }

        % Descriptions used for fault bands table
        faultTypeDescriptions = containers.Map({ ...
            SFRFsParametersRollingBearings.OUTER_RACE_FAULT_TYPE_NAME, ...
            SFRFsParametersRollingBearings.INNER_RACE_FAULT_TYPE_NAME, ...
            SFRFsParametersRollingBearings.BALL_FAULT_TYPE_NAME, ...
            SFRFsParametersRollingBearings.CAGE_FAULT_TYPE_NAME}, ...
            { ...
                "Outer Race Fault", ...
                "Inner Race Fault", ...
                "Ball Fault", ...
                "Cage Fault" ...
            })

        % Fault group numeric IDs compatible with MATLAB bearingFaultBands
        faultTypeGroups = containers.Map({ ...
            SFRFsParametersRollingBearings.OUTER_RACE_FAULT_TYPE_NAME, ...
            SFRFsParametersRollingBearings.INNER_RACE_FAULT_TYPE_NAME, ...
            SFRFsParametersRollingBearings.BALL_FAULT_TYPE_NAME, ...
            SFRFsParametersRollingBearings.CAGE_FAULT_TYPE_NAME}, ...
            { ...
                1, ...  % Outer Race group ID
                2, ...  % Inner Race group ID
                3, ...  % Ball group ID
                4  ...  % Cage group ID
            })

        % Inverse of faultTypeGroups
        faultGroupToTypeName = ...
            BearingFrequencyBands.buildGroupToFaultTypesMap();

    end

    methods

        function obj = BearingFrequencyBands(args)
            arguments
                args.bearingParams (1,1) ParametersRollingBearings
                args.sfrfsParams (1,1) SFRFsParametersRollingBearings
                args.operatingConditions (1,1) OperatingConditions
            end
            
            % Call superclass constructor with named params struct
            obj = obj@FaultFrequencyBands( ...
                operatingConditions=args.operatingConditions, ...
                sfrfsParams = args.sfrfsParams);
            
            % Assign subclass-specific property
            obj.bearingParams = args.bearingParams;
        end


        function computeBands(obj)
        % computeBands  Build fault frequency bands table
        %   computeBands()
        %   computes the fault frequency bands for each row in the
        %   bandsTable table.
        %
        %   Output table columns:
        %       FaultGroup          - numeric index of the fault band entry
        %       Description         - human-readable fault type description 
        %                             (e.g. "Outer Race Fault")
        %       Speed               - shaft rotational speed (Hz)
        %       Load                - load value from operatingConditions
        %       ReceptiveFieldBands - cell containing the bands definition 
        %                             as a collection of instances of 
        %                             containers.Map, each map with keys:
        %                               'Bands', 
        %                               'Harmonic', 
        %                               'Label', 
        %                               'Sideband'
        %
        %   Example:
        %
        %       % 1. Set the operating conditions
        %       speed = [35; 37.5; 40];
        %       load  = [12; 11; 10];
        %       ocObj = OperatingConditions(speed, load);
        % FaultFrequency
        %       % 2. Bearing + SRF params
        %       bp = ParametersRollingBearings( ...
        %           'numRollingElements',8, ...
        %           'ballDiameter',7.92, ...
        %           'pitchDiameter',34.55, ...
        %           'contactAngle',0);
        % 
        %       sharedParams = ...
        %         SFRFsParameters.crFaultFrequencyeateSFRFsParameters( ...
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
        %       bfb = BearingFrequencyBands(...
        %           'bearingParams',bp, ... 
        %           'sfrfsParams',sp, ...
        %           'operatingConditions', ocObj);
        %
        %       % 4. Compute fault bands
        %       bfb.computeBands();
        %
        %   Notes:
        %       FaultGroup numeric index and Label in ReceptiveFieldBands 
        %       entries  are compatible with MATLAB's function 
        %       'bearingFaultBands' introduced in 
        %       Predictive Maintenance Toolbox R2019b


            oc = obj.operatingConditions.conditionsTable;
        
            % Get constant list of fault types
            faultTypes = SFRFsParametersRollingBearings.faultTypes;
            numFaultTypes = numel(faultTypes);

            % Number of operating conditions
            numOC = height(oc);
            
            % Preallocate one row per fault type per operating condition
            totalRows = numOC * numFaultTypes;
            
            faultBandsStruct(totalRows) = struct( ...
                'FaultGroup', [], ...
                'Description', "", ...
                'Speed', [], ...
                'Load', [], ...
                'ReceptiveFieldBands', [] ...
            );

            log = SFRFsLogger.getLogger();

            % Fill rows
            rowIdx = 1;
            for condIdx = 1:numOC
                % speed and load
                oc_speed = oc.Speed(condIdx);
                oc_load  = oc.Load(condIdx);

                % Log context info
                if log.isInfoEnabled()
                    contextMsg = ...
                        sprintf(['Computing fault bands for Speed=%.3f'...
                        ' Hz, Load=%.3f'], ...
                        oc_speed, oc_load);
                    log.info(contextMsg);
                end

                % compute all fault bands for this speed ---
                fbs = obj.computeForSpeed(oc_speed);
            
                % add rows per each fault type
                for ftIdx = 1:numFaultTypes
                    ftName   = faultTypes{ftIdx};
                    description = obj.faultTypeDescriptions(ftName);

                    bands = fbs.(ftName); 

                    % Always enforce cell array
                    if ~iscell(bands)
                        bands = {bands};
                    end
            
                    faultBandsStruct(rowIdx).FaultGroup = ...
                        obj.faultTypeGroups(ftName);
                    faultBandsStruct(rowIdx).Description = description;
                    faultBandsStruct(rowIdx).Speed = oc_speed;
                    faultBandsStruct(rowIdx).Load = oc_load;
                    faultBandsStruct(rowIdx).ReceptiveFieldBands = {bands}; 
            
                    rowIdx = rowIdx + 1;
                end
            end
            
            % Convert struct array to table
            obj.bandsTable = ...
                struct2table(faultBandsStruct, 'AsArray', true);
            
            if log.isFineEnabled()
                log.fine(obj.toString())
            end

        end

        function faultBands = computeForSpeed(obj, speed)
            % Compute fault bands for given shaft speed (Hz)
        
            faultTypes = SFRFsParametersRollingBearings.faultTypes;
            faultBands = struct();
            log = SFRFsLogger.getLogger();
        
            for f = 1:numel(faultTypes)
                ftName       = faultTypes{f};

                description = obj.faultTypeDescriptions(ftName);

                % Log context info
                contextMsg = ...
                    sprintf(['Computing fault bands for Speed=%.3f'...
                    ' Hz, Fault=%s'], speed, description);
                    log.info(contextMsg);
                sfrf_params  = obj.sfrfsParams.(ftName);
                mapsForType  = obj.computeBandsForFaultType(...
                    ftName, speed, sfrf_params);
                faultBands.(ftName) = mapsForType;
            end
        end

        function str = toString(obj)
            % string representation of the BearingFrequencyBands object
            
            % Convert bearingParams and sfrfsParams to strings 
            bpStr = obj.bearingParams.toString();
            spStr = obj.sfrfsParams.toString();
            
            % Convert the bandsTable to JSON string (compact)
            if isempty(obj.bandsTable)
                fbStr = "[]";
            else
                fbStr = jsonencode(obj.bandsTable);
            end
            
            % Compose final string
            str = sprintf(...
                "BearingFrequencyBands:%s,%s[bandsTable:%s]", ...
                bpStr, spStr, fbStr);
        end

    end


    methods (Access = private)

        function mapsForType = computeBandsForFaultType( ...
                obj, ftName, speed, sfrf_params)
            switch ftName
                case ...
                  SFRFsParametersRollingBearings.OUTER_RACE_FAULT_TYPE_NAME
                  mapsForType = ...
                      obj.computeOuterRaceBands(speed, sfrf_params);
    
                case ...
                  SFRFsParametersRollingBearings.INNER_RACE_FAULT_TYPE_NAME
                  mapsForType = ...
                      obj.computeInnerRaceBands(speed, sfrf_params);
    
                case SFRFsParametersRollingBearings.BALL_FAULT_TYPE_NAME
                    mapsForType = obj.computeBallBands(speed, sfrf_params);
    
                case SFRFsParametersRollingBearings.CAGE_FAULT_TYPE_NAME
                    mapsForType = obj.computeCageBands(speed, sfrf_params);
    
                otherwise
                    error( ...
                            ['sfrfs:BearingFrequencyBands:' ...
                            'ModulationCodeRequired'], ...
                            'Unknown fault type: %s', ftName);
            end
        end

        function [NB, DB, DP, phi] = getBearingGeometryParams(obj)
        %GETGEOMETRY Extract common bearing geometry in consistent units
            NB  = obj.bearingParams.numRollingElements;
            DB  = obj.bearingParams.ballDiameter;
            DP  = obj.bearingParams.pitchDiameter;
            phi = deg2rad(obj.bearingParams.contactAngle);
        end

         function f0 = getCentralFrequency(obj, faultCode, speed)
            % Retrieve geometry from this object's state
            [NB, DB, DP, phi] = obj.getBearingGeometryParams();
        
            switch faultCode
                case BearingFrequencyBands.BPFO_CODE % Outer race BPFO
                    f0 = (NB / 2) * speed * (1 - (DB / DP) * cos(phi));
        
                case BearingFrequencyBands.BPFI_CODE % Inner race BPFI
                    f0 = (NB / 2) * speed * (1 + (DB / DP) * cos(phi));
        
                case BearingFrequencyBands.BSF_CODE % Ball spin BSF
                    f0 = (DP / (2 * DB)) * speed * ...
                         (1 - ((DB / DP) * cos(phi)) ^ 2);
        
                case BearingFrequencyBands.FTF_CODE % Cage / FTF
                    f0 = 0.5 * speed * (1 - (DB / DP) * cos(phi));
        
                otherwise
                    error( ...
                        ['sfrfs:BearingFrequencyBands:' ...
                         'UnknownFaultCode'], ...
                        'Unknown fault code: %s', faultCode);
            end
        end

        function maps = computeOuterRaceBands(obj, speed, sfrf_params)
            % Compute band maps for the Outer Race fault type
        
            numH = sfrf_params.numHarmonics;
            maps = cell(1, numH);
        
            % compute central frequency 
            f_bpfo = obj.getCentralFrequency(obj.BPFO_CODE, speed);
        
            for h = 1:numH
                % Frequency of the harmonic
                freqH = h * f_bpfo;
        
                map = BearingFrequencyBands.buildBandMap( ...
                    freqH, sfrf_params, ...
                    HarmonicNumber = h, ...
                    SidebandNumber = 0, ...
                    CentralCode    = obj.BPFO_CODE);
        
                maps{h} = map;
            end

            % Remove bands with negative frequencies
            maps = BearingFrequencyBands.filterInvalidBands(maps);
        end

        function maps = computeInnerRaceBands(obj, speed, sfrf_params)
            % Compute band maps for the Inner Race fault type
        
            numH = sfrf_params.numHarmonics;
            numS = sfrf_params.numSidebands;
            maps = cell(1, numH * (2 * numS + 1));
        
            % Central frequency for Inner Race from single source of truth
            f_bpfi = obj.getCentralFrequency(obj.BPFI_CODE, speed);
        
            % Modulation frequency (shaft rotational speed)
            f_mod = speed;  % Hz
        
            centralCode = obj.BPFI_CODE;
            modCode     = obj.FR_CODE;
        
            idx = 1;
            for h = 1:numH
                f_central = h * f_bpfi;
        
                for sb = -numS:numS
                    if sb == 0
                        % Central harmonic frequency component
                        maps{idx} = BearingFrequencyBands.buildBandMap( ...
                            f_central, sfrf_params, ...
                            HarmonicNumber = h, ...
                            SidebandNumber = sb, ...
                            CentralCode = centralCode);
                    else
                        % Sidebands modulated by shaft rotation frequency
                        f_sb = f_central + sb * f_mod;
                        maps{idx} = BearingFrequencyBands.buildBandMap( ...
                            f_sb, sfrf_params, ...
                            HarmonicNumber = h, ...
                            SidebandNumber = sb, ...
                            CentralCode = centralCode, ...
                            ModulationCode = modCode);
                    end
                    idx = idx + 1;
                end
            end
            % Remove bands with negative frequencies
            maps = BearingFrequencyBands.filterInvalidBands(maps);
        end

        function maps = computeBallBands(obj, speed, sfrf_params)
        % Compute band maps for the Ball Spin fault type
        
            numH = sfrf_params.numHarmonics;
            numS = sfrf_params.numSidebands;
            maps = cell(1, numH * (2 * numS + 1));
        
            % Central frequency for Ball Spin from single source of truth
            f_bsf = obj.getCentralFrequency(obj.BSF_CODE, speed);
        
            % Modulation frequency (shaft rotational speed)
            f_mod = speed;  % Hz
        
            centralCode = obj.BSF_CODE;
            modCode     = obj.FTF_CODE;  % Cage frequency
        
            idx = 1;
            for h = 1:numH
                f_central = h * f_bsf;
        
                for sb = -numS:numS
                    if sb == 0
                        % Central harmonic
                        maps{idx} = BearingFrequencyBands.buildBandMap( ...
                            f_central, sfrf_params, ...
                            HarmonicNumber = h, ...
                            SidebandNumber = sb, ...
                            CentralCode    = centralCode);
                    else
                        % Sidebands (modulated by cage frequency)
                        f_sb = f_central + sb * f_mod;
                        maps{idx} = BearingFrequencyBands.buildBandMap( ...
                            f_sb, sfrf_params, ...
                            HarmonicNumber = h, ...
                            SidebandNumber = sb, ...
                            CentralCode    = centralCode, ...
                            ModulationCode = modCode);
                    end
                    idx = idx + 1;
                end
            end
            % Remove bands with negative frequencies
            maps = BearingFrequencyBands.filterInvalidBands(maps);
        end

        function maps = computeCageBands(obj, speed, sfrf_params)
            % Compute band maps for the Cage fault type
        
            numH = sfrf_params.numHarmonics;
            maps = cell(1, numH);
        
            % Get central frequency for fundamental train frequency from 
            % single source of truth
            f_ftf = obj.getCentralFrequency(obj.FTF_CODE, speed);
        
            for h = 1:numH
                % Frequency of the harmonic
                freqH = h * f_ftf;
        
                map = BearingFrequencyBands.buildBandMap( ...
                    freqH, sfrf_params, ...
                    HarmonicNumber = h, ...
                    SidebandNumber = 0, ...
                    CentralCode    = obj.FTF_CODE);
        
                maps{h} = map;
            end
            % Remove bands with negative frequencies
            maps = BearingFrequencyBands.filterInvalidBands(maps);
        end
    end

    methods (Static, Access = private)

        function map = buildGroupToFaultTypesMap()
            map = containers.Map( ...
                values(BearingFrequencyBands.faultTypeGroups), ...
                keys(BearingFrequencyBands.faultTypeGroups));
        end

        function map = buildBandMap(freq, sfrf_params, opts)
        %BUILDBANDMAP Construct a containers.Map describing one band 
        %   instance.
        %
        %   map = buildBandMap(freq, sfrf_params, opts)
        %
        %   Inputs:
        %       freq        (1,1) double  - Central frequency for the band 
        %                                   (Hz)
        %       sfrf_params               - Per-fault SFRFs parameters 
        %                                   object, specifying
        %                                   SigmaCenter and SigmaSurround
        %
        %   Named Arguments in opts:
        %       HarmonicNumber (1,1) {mustBeInteger, mustBePositive}
        %           Harmonic index (1 = fundamental)
        %
        %       SidebandNumber (1,1) {mustBeInteger}
        %           Sideband index (0 if none)
        %
        %       CentralCode    (1,:) char
        %           Short code string for the central (carrier) frequency
        %           e.g. 'Fo' (Outer), 'Fi' (Inner), 'Fb' (Ball), 
        %           'Fc' (Cage)
        %
        %       ModulationCode (1,:) char = ''
        %           Short code string for the modulation (sideband) 
        %           frequency
        %           Required if SidebandNumber ~= 0.
        %
        %   Output:
        %       map - containers.Map with keys:
        %                 'Bands'    - bandStruct from makeBands()
        %                 'Harmonic' - harmonic index
        %                 'Label'    - fault frequency label string
        %                 'Sideband' - sideband index
        %
        %   Notes:
        %       - This wraps makeBands() to build the band edges.
        %       - Label is generated by buildLabel() using named arguments.
        %
        %   Example:
        %       m = BearingFrequencyBands.buildBandMap(100, params, ...
        %               HarmonicNumber = 1, SidebandNumber = -2, ...
        %               CentralCode    = 'Fo', ...
        %               ModulationCode = 'Fr');
        
            arguments
                freq (1,1) double
                sfrf_params
                opts.HarmonicNumber (1,1) {mustBeInteger, mustBePositive}
                opts.SidebandNumber (1,1) {mustBeInteger}
                opts.CentralCode (1,:) char
                opts.ModulationCode (1,:) char = '' % optional
            end
    
            % Validate modulation code requirement
            if opts.SidebandNumber ~= 0 && isempty(opts.ModulationCode)
                error(...
                    ['sfrfs:BearingFrequencyBands:' ...
                     'ModulationCodeRequired'], ...
                      "ModulationCode required for nonzero sidebands");
            end
    
            % Compute band limits
            bandStruct = ...
                BearingFrequencyBands.makeBands(freq, sfrf_params);
    
            % Generate label via named-argument call
            label = BearingFrequencyBands.buildLabel( ...
                HarmonicNumber = opts.HarmonicNumber, ...
                SidebandNumber = opts.SidebandNumber, ...
                CentralCode    = opts.CentralCode, ...
                ModulationCode = opts.ModulationCode);
    
            % Construct the map
            map = containers.Map( ...
                {'Bands','Harmonic','Label','Sideband'}, ...
                {...
                    bandStruct, ...
                    opts.HarmonicNumber, ...
                    label, ...
                    opts.SidebandNumber} ...
                );
        end

        function label = buildLabel(args)
        %BUILDLABEL Construct a fault frequency label using named 
        %   arguments.
        %
        %   label = buildLabel(args)
        %
        %   Named Arguments (fields of args):
        %       HarmonicNumber   (1,1) integer >= 1
        %           Harmonic of the central (carrier) frequency.
        %
        %       SidebandNumber   (1,1) integer
        %           Sideband index relative to the central frequency.
        %           Zero indicates no sidebands. Positive values produce
        %           a '+' in the label, negative values a '-'.
        %
        %       CentralCode      (1,:) char
        %           Short code identifying the central (carrier) frequency,
        %           e.g. 'Fo' (Outer race), 'Fi' (Inner race), 'Fb' (Ball).
        %
        %       ModulationCode   (1,:) char = ''
        %           Short code for the modulation (sideband) frequency,
        %           e.g. 'Fc' (Cage), 'Fr' (Rotational). Optional; required
        %           only when SidebandNumber ~= 0.
        %
        %   Common codes:
        %       Fo - Outer race (BPFO)
        %       Fi - Inner race (BPFI)
        %       Fb - Ball / rolling element (BSF)
        %       Fc - Cage / fundamental train frequency (FTF)
        %       Fr - Rotational frequency
        %
        %   Output:
        %       label - char array representing the harmonic/sideband in
        %               MATLAB's bearing fault notation, e.g.:
        %                   '1Fo'         - fundamental, no sidebands
        %                   '2Fi+1Fr'     - 2nd harmonic of Fi, +1 Fr 
        %                                   sideband
        %                   '1Fb-2Fc'     - fundamental Fb, -2 Fc sidebands
        %
        %   Example usage:
        %       % 1) Fundamental, no sidebands
        %       lbl = BearingFrequencyBands.buildLabel( ...
        %           HarmonicNumber = 1, ...
        %           SidebandNumber = 0, ...
        %           CentralCode    = 'Fo' )
        %       % returns: '1Fo'
        %
        %       % 2) Positive sideband (+1)
        %       lbl = BearingFrequencyBands.buildLabel( ...
        %           HarmonicNumber = 2, ...
        %           SidebandNumber = 1, ...
        %           CentralCode    = 'Fi', ...
        %           ModulationCode = 'Fr' )
        %       % returns: '2Fi+1Fr'
        %
        %       % 3) Negative sideband (‑2)
        %       lbl = BearingFrequencyBands.buildLabel( ...
        %           HarmonicNumber = 1, ...
        %           SidebandNumber = -2, ...
        %           CentralCode    = 'Fb', ...
        %           ModulationCode = 'Fc' )
        %       % returns: '1Fb-2Fc'
        %   Notes:
        %       - Raises an error if SidebandNumber ~= 0 and ModulationCode
        %         is omitted or empty.
        %       - Sign of SidebandNumber determines the '+' or '-' in the 
        %         label.
        
            arguments
                args.HarmonicNumber (1,1) {mustBeInteger, mustBePositive}
                args.SidebandNumber (1,1) {mustBeInteger}
                args.CentralCode (1,:) char
                args.ModulationCode (1,:) char = ''  % optional
            end
    
            if args.SidebandNumber == 0
                % No sidebands
                label = sprintf(...
                    '%d%s', args.HarmonicNumber, args.CentralCode);
            else
                if isempty(args.ModulationCode)
                    error(...
                        ['sfrfs:BearingFrequencyBands:'...
                        'ModulationCodeRequired'], ...
                        "ModulationCode required for nonzero sidebands");
                end
                % Include + or - automatically
                label = sprintf('%d%s%+d%s', ...
                                args.HarmonicNumber, ...
                                args.CentralCode, ...
                                args.SidebandNumber, ...
                                args.ModulationCode);
            end
        end

        function bandStruct = makeBands(freq, sfrf_params)
        %MAKEBANDS  Build band limit structure from central frequency and 
        %   SFRF parameters
        %
        %   bandStruct = MAKEBANDS(freq, sfrf_params) constructs the
        %   frequency band limits for both the "Center" and "Surround"
        %   bands based on the specified central frequency and the 
        %   sigma widths stored in the SFRF parameters object.
        %
        %   Inputs:
        %       freq        - Scalar central frequency for the band (Hz)
        %       sfrf_params - SFRFs parameters object for a fault type,
        %                     containing SigmaCenter and SigmaSurround.
        %                     Only the first elements in these arrays
        %                     are currently used.
        %
        %   Output:
        %       bandStruct  - Struct with fields:
        %                       .Center   [fLow, fHigh] limits for center band
        %                       .Surround [fLow, fHigh] limits for surround 
        %                       band
        %
        %   Notes:
        %       - Both bands are computed symmetrically around 'freq'.
        %       - Bandwidths are taken as full widths (not half-widths).
        
            bandwidthCenter   = sfrf_params.sigmaCenter(1);
            bandwidthSurround = sfrf_params.sigmaSurround(1);
    
            bandCenter   = ...
                [freq - bandwidthCenter/2,   freq + bandwidthCenter/2];
            bandSurround = ...
                [freq - bandwidthSurround/2, freq + bandwidthSurround/2];

            if bandCenter(1) < 0 || bandSurround(1) < 0
                log = SFRFsLogger.getLogger();
                log.fine(...
                    sprintf(['Negative frequency band detected.'...
                                 'Center band limits: [%g, %g].'...
                                 'Surround band limits: [%g, %g].'], ...
                                 bandCenter(1), bandCenter(2), ...
                                 bandSurround(1), bandSurround(2)));
            end
    
            bandStruct = struct(...
                'Center',   bandCenter, ...
                'Surround', bandSurround);
        end

        function filteredMaps = filterInvalidBands(maps)
            %FILTERINVALIDBANDS Remove bands with negative lower frequency 
            %   limits
            %
            %   filteredMaps = FILTERINVALIDBANDS(maps) filters out any 
            %   band map structures from the input cell array 'maps' whose 
            %   'Bands' frequency limits (either Center or Surround) have 
            %   negative lower bounds.
            %   
            %   This ensures all returned bands have physically meaningful 
            %   frequencies.
            %
            %   Input:
            %       maps - Cell array of containers.Map objects representing 
            %              frequency band info, each with a 'Bands' field 
            %              containing 'Center' and 'Surround' frequency 
            %              limits as [fLow, fHigh].
            %
            %   Output:
            %       filteredMaps - Cell array containing only bands with 
            %                      non-negative lower frequency limits.
            
            isValid = cellfun(@(m) ...
                ~isempty(m) && ...
                m('Bands').Center(1) >= 0 && ...
                m('Bands').Surround(1) >= 0, ...
                maps);
        
            % Number of bands filtered out
            droppedCount = sum(~isValid); 
        
            if droppedCount > 0
                % Collect labels of dropped bands
                labels = cellfun(@(m) m('Label'), ...
                    maps(~isValid), 'UniformOutput', false);
                labelsStr = strjoin(labels, ', ');
        
                log = SFRFsLogger.getLogger();
                msg = sprintf(...
                    'Negative frequency bands dropped (%d): %s',...
                    droppedCount, labelsStr);
                log.info(msg);
            end
        
            filteredMaps = maps(isValid);
        end
    end
end
