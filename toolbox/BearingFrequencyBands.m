classdef BearingFrequencyBands < FaultFrequencyBands
% BearingFrequencyBands  Compute bearing fault characteristic frequency
%   bands
%
% Computes characteristic and sideband frequency bands for bearing faults
% based on bearing geometry and Spectral Fault Receptive Fields (SFRF)
% parameters.
% Supports configurable harmonics, sidebands, and Gaussian bandwidths for
% each fault type.
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
                sfrfsParams=args.sfrfsParams);

            % Assign subclass-specific property
            obj.bearingParams = args.bearingParams;
        end

        function computeBands(obj, operatingConditions)
        % computeBands  Build fault frequency bands table
        %
        %   computeBands(obj) builds the bands table using 
        %   obj.operatingConditions.
        %   computeBands(obj, operatingConditions) uses the provided 
        %   conditions.
        
            arguments
                obj (1,1)
                operatingConditions (1,1) OperatingConditions = ...
                    obj.operatingConditions
            end
        
            import tables.FaultBandsTableSchema
            import tables.OperatingConditionsTableSchema
        
            ocT = operatingConditions.conditionsTable;
        
            kSpeed = OperatingConditionsTableSchema.SPEED;
            kLoad  = OperatingConditionsTableSchema.LOAD;
        
            kFaultGroup = FaultBandsTableSchema.FAULTGROUP;
            kDesc       = FaultBandsTableSchema.DESCRIPTION;
            kSpeedOut   = FaultBandsTableSchema.SPEED;
            kLoadOut    = FaultBandsTableSchema.LOAD;
            kRfb        = FaultBandsTableSchema.RECEPTIVEFIELDBANDS;
        
            faultTypes = SFRFsParametersRollingBearings.faultTypes;
            numFaultTypes = numel(faultTypes);
        
            numOC = height(ocT);
            totalRows = numOC * numFaultTypes;
        
            faultBandsStruct(totalRows) = struct( ...
                kFaultGroup, [], ...
                kDesc, "", ...
                kSpeedOut, [], ...
                kLoadOut, [], ...
                kRfb, [] );
        
            log = SFRFsLogger.getLogger();
        
            rowIdx = 1;
            for condIdx = 1:numOC
                ocSpeed = ocT{condIdx, kSpeed};
                ocLoad  = ocT{condIdx, kLoad};
        
                if log.isInfoEnabled()
                    msg = sprintf([ ...
                        'Computing fault bands for Speed=%.3f Hz, ' ...
                        'Load=%.3f'], ...
                        ocSpeed, ocLoad);
                    log.info(msg);
                end
        
                fbs = obj.computeForSpeed(ocSpeed);
        
                for ftIdx = 1:numFaultTypes
                    ftName = faultTypes{ftIdx};
                    desc = obj.faultTypeDescriptions(ftName);
        
                    maps = fbs.(ftName);
                    if ~iscell(maps)
                        maps = {maps};
                    end
        
                    faultBandsStruct(rowIdx).(kFaultGroup) = ...
                        obj.faultTypeGroups(ftName);
                    faultBandsStruct(rowIdx).(kDesc) = desc;
                    faultBandsStruct(rowIdx).(kSpeedOut) = ocSpeed;
                    faultBandsStruct(rowIdx).(kLoadOut) = ocLoad;
        
                    % Exactly one outer cell for the table column
                    faultBandsStruct(rowIdx).(kRfb) = {maps};
        
                    rowIdx = rowIdx + 1;
                end
            end
        
            obj.bandsTable = struct2table(faultBandsStruct, "AsArray", true);
        
            if log.isFineEnabled()
                log.fine(obj.toString());
            end
        end

        function faultBands = computeForSpeed(obj, speed)
        % Compute fault bands for given shaft speed (Hz)

            faultTypes = SFRFsParametersRollingBearings.faultTypes;
            faultBands = struct();
            log = SFRFsLogger.getLogger();

            for f = 1:numel(faultTypes)
                ftName = faultTypes{f};

                description = obj.faultTypeDescriptions(ftName);

                % Log context info
                contextMsg = sprintf(...
                    ['Computing fault bands for Speed=%.3f' ...
                     ' Hz, Fault=%s'], speed, description);
                log.info(contextMsg);

                sfrf_params = obj.sfrfsParams.(ftName);
                mapsForType = obj.computeBandsForFaultType( ...
                    ftName, speed, sfrf_params);
                faultBands.(ftName) = mapsForType;
            end
        end

        function str = toString(obj)
        % string representation of the BearingFrequencyBands object

            bpStr = obj.bearingParams.toString();
            spStr = obj.sfrfsParams.toString();

            if isempty(obj.bandsTable)
                fbStr = "[]";
            else
                fbStr = jsonencode(obj.bandsTable);
            end

            str = sprintf( ...
                "BearingFrequencyBands:%s,%s[bandsTable:%s]", ...
                bpStr, spStr, fbStr);
        end

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
        % Extract common bearing geometry in consistent units
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

            % compute central frequency
            f_bpfo = obj.getCentralFrequency(obj.BPFO_CODE, speed);

            maps = BearingFrequencyBands.buildHarmonicsOnly( ...
                f_bpfo, numH, sfrf_params, obj.BPFO_CODE);
        end

        function maps = computeInnerRaceBands(obj, speed, sfrf_params)
        % Compute band maps for the Inner Race fault type

            numH = sfrf_params.numHarmonics;
            numS = sfrf_params.numSidebands;

            % Central frequency for Inner Race from single source of truth
            f_bpfi = obj.getCentralFrequency(obj.BPFI_CODE, speed);

            % Modulation frequency (shaft rotational speed)
            f_mod = speed;  

            centralCode = obj.BPFI_CODE;
            modCode = obj.FR_CODE;

            maps = BearingFrequencyBands.buildHarmonicsWithSidebands( ...
                f_bpfi, numH, numS, f_mod, sfrf_params, ...
                centralCode, modCode);
        end

        function maps = computeBallBands(obj, speed, sfrf_params)
        % Compute band maps for the Ball Spin fault type

            numH = sfrf_params.numHarmonics;
            numS = sfrf_params.numSidebands;

            % Central frequency for Ball Spin from single source of truth
            f_bsf = obj.getCentralFrequency(obj.BSF_CODE, speed);

            % Modulation frequency (Fundamental train frequency)
            f_mod = obj.getCentralFrequency(obj.FTF_CODE, speed); 

            centralCode = obj.BSF_CODE;
            modCode = obj.FTF_CODE;  % Aka Cage frequency

            maps = BearingFrequencyBands.buildHarmonicsWithSidebands( ...
                f_bsf, numH, numS, f_mod, sfrf_params, ...
                centralCode, modCode);
        end

        function maps = computeCageBands(obj, speed, sfrf_params)
            % Compute band maps for the Cage fault type

            numH = sfrf_params.numHarmonics;

            % Get central frequency for fundamental train frequency
            f_ftf = obj.getCentralFrequency(obj.FTF_CODE, speed);

            maps = BearingFrequencyBands.buildHarmonicsOnly( ...
                f_ftf, numH, sfrf_params, obj.FTF_CODE);
        end
    end

    methods (Static, Access = private)

        function map = buildGroupToFaultTypesMap()
            map = containers.Map( ...
                values(BearingFrequencyBands.faultTypeGroups), ...
                keys(BearingFrequencyBands.faultTypeGroups));
        end

        function maps = buildHarmonicsOnly(freq0, numH, sfrf_params, code)
            maps = cell(1, numH);
            for h = 1:numH
                freqH = h * freq0;

                maps{h} = BearingFrequencyBands.buildBandMap( ...
                    freqH, sfrf_params, ...
                    HarmonicNumber = h, ...
                    SidebandNumber = 0, ...
                    CentralCode = code);
            end

            maps = BearingFrequencyBands.filterInvalidBands(maps);
        end

        function maps = buildHarmonicsWithSidebands( ...
                freq0, numH, numS, f_mod, sfrf_params, ...
                centralCode, modCode)

            maps = cell(1, numH * (2 * numS + 1));
            idx = 1;

            for h = 1:numH
                f_central = h * freq0;

                for sb = -numS:numS
                    if sb == 0
                        maps{idx} = BearingFrequencyBands.buildBandMap( ...
                            f_central, sfrf_params, ...
                            HarmonicNumber = h, ...
                            SidebandNumber = 0, ...
                            CentralCode = centralCode);
                    else
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

            maps = BearingFrequencyBands.filterInvalidBands(maps);
        end

        function map = buildBandMap(freq, sfrf_params, opts)
        % Construct a containers.Map describing one band instance.

            arguments
                freq (1,1) double
                sfrf_params
                opts.HarmonicNumber (1,1) {mustBeInteger, mustBePositive}
                opts.SidebandNumber (1,1) {mustBeInteger}
                opts.CentralCode (1,:) char
                opts.ModulationCode (1,:) char = '' % optional
            end

            if opts.SidebandNumber ~= 0 && isempty(opts.ModulationCode)
                error(...
                    ['sfrfs:BearingFrequencyBands:' ...
                     'ModulationCodeRequired'], ...
                      "ModulationCode required for nonzero sidebands");
            end

            bandStruct = ...
                BearingFrequencyBands.makeBands(freq, sfrf_params);

            label = BearingFrequencyBands.buildLabel( ...
                HarmonicNumber = opts.HarmonicNumber, ...
                SidebandNumber = opts.SidebandNumber, ...
                CentralCode    = opts.CentralCode, ...
                ModulationCode = opts.ModulationCode);

            import dicts.BandMapSchema

            kBands = BandMapSchema.BANDS;
            kHar = BandMapSchema.HARMONIC;
            kLbl = BandMapSchema.LABEL;
            kSide = BandMapSchema.SIDEBAND;

            map = containers.Map( ...
                {kBands, kHar, kLbl, kSide}, ...
                {bandStruct, ...
                opts.HarmonicNumber, ...
                label, opts.SidebandNumber});

        end

        function label = buildLabel(args)
        %BUILDLABEL Construct a fault frequency label using named
        %   arguments.

            arguments
                args.HarmonicNumber (1,1) {mustBeInteger, mustBePositive}
                args.SidebandNumber (1,1) {mustBeInteger}
                args.CentralCode (1,:) char
                args.ModulationCode (1,:) char = ''  % optional
            end

            if args.SidebandNumber == 0
                label = sprintf( ...
                    '%d%s', args.HarmonicNumber, args.CentralCode);
            else
                if isempty(args.ModulationCode)
                    error(...
                        ['sfrfs:BearingFrequencyBands:'...
                        'ModulationCodeRequired'], ...
                        "ModulationCode required for nonzero sidebands");
                end

                label = sprintf('%d%s%+d%s', ...
                                args.HarmonicNumber, ...
                                args.CentralCode, ...
                                args.SidebandNumber, ...
                                args.ModulationCode);
            end
        end

        function bandStruct = makeBands(freq, sfrf_params)
            %MAKEBANDS Build band limit structure using mask reference
            %bandwidths.

            centerMask   = sfrf_params.centerMask;
            surroundMask = sfrf_params.surroundMask;

            bandwidthCenter   = centerMask.getReferenceBandwidth();
            bandwidthSurround = surroundMask.getReferenceBandwidth();

            bandCenter = ...
                [freq - bandwidthCenter/2, freq + bandwidthCenter/2];
            bandSurround = ...
                [freq - bandwidthSurround/2, freq + bandwidthSurround/2];

            if bandCenter(1) < 0 || bandSurround(1) < 0
                log = SFRFsLogger.getLogger();
                log.fine(sprintf([ ...
                    'Negative frequency band detected. ' ...
                    'Center band limits: [%g, %g]. ' ...
                    'Surround band limits: [%g, %g].'], ...
                    bandCenter(1), ...
                    bandCenter(2), ...
                    bandSurround(1), ...
                    bandSurround(2)));
            end

            import structs.OpponentBandsSchema
            bandStruct = struct( ...
                OpponentBandsSchema.CENTER, bandCenter, ...
                OpponentBandsSchema.SURROUND, bandSurround);

        end

        function filteredMaps = filterInvalidBands(maps)
            %FILTERINVALIDBANDS Remove bands with negative lower frequency
            %   limits

            import dicts.BandMapSchema
            import structs.OpponentBandsSchema

            kBands = BandMapSchema.BANDS;
            kLbl = BandMapSchema.LABEL;

            kCenter = OpponentBandsSchema.CENTER;
            kSur = OpponentBandsSchema.SURROUND;

            isValid = cellfun(@(m) ...
                ~isempty(m) && ...
                m(kBands).(kCenter)(1) >= 0 && ...
                m(kBands).(kSur)(1) >= 0, ...
                maps);

            droppedCount = sum(~isValid);

            if droppedCount > 0
                labels = cellfun(@(m) m(kLbl), maps(~isValid), ...
                    'UniformOutput', false);
                labelsStr = strjoin(labels, ', ');

                log = SFRFsLogger.getLogger();
                msg = sprintf( ...
                    'Negative frequency bands dropped (%d): %s', ...
                    droppedCount, labelsStr);
                log.info(msg);
            end

            filteredMaps = maps(isValid);
        end
    end
end
