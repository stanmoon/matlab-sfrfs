classdef SFRFsEnsembleBroker < EnsembleBroker
% SFRFSENSEMBLEBROKER  EnsembleBroker specialization for SFRF data.
%
%   SFRFsEnsembleBroker extends EnsembleBroker by introducing a dedicated
%   naming convention for Spectral Fault Receptive Field (SFRF) columns. In
%   addition to the temporal and spectral (FFT) mappings provided by the
%   superclass, this class defines and manages an SFRF-specific suffix for
%   consistent identification of SFRF-derived signals.
%
%   Key features:
%     • Inherits full ensemble management, metadata handling, and file
%       retrieval capabilities from EnsembleBroker.
%     • Adds a configurable SFRF suffix (default: "_SFRFs").
%     • Provides bidirectional mapping between temporal and SFRF column 
%       names.
%
%   See also: EnsembleBroker, EnsembleUtil

    
    properties (SetAccess = private)
        % Suffix for column names of SFRFs
        sfrfsSuffixInternal (1,1) string = "_SFRFs"
    end
    
    methods
        function obj = SFRFsEnsembleBroker(args)
            arguments
                args.EnsembleObject {mustBeNonempty}
                args.GetFilesFunction function_handle
                args.TemporalSnapshotColumns (1,:) cell
                args.SpectralSuffix string = "_FFT"
                args.sfrfsSuffix (1,1) string = "_SFRFs"
            end
            % Call to the superclass constructor
            obj@EnsembleBroker( ...
                ensembleObject = args.EnsembleObject, ...
                getFilesFunction = args.GetFilesFunction, ...
                temporalSnapshotColumns = args.TemporalSnapshotColumns, ...
                spectralSuffix = args.SpectralSuffix ...
            );
            obj.sfrfsSuffixInternal = args.sfrfsSuffix;
        end
        
        function sfrfsName = mapToSFRFColumn(obj, columnName)
        % mapToSFRFColumn Return the SFRF column name for a given temporal 
        % column.
        %
        %   sfrfsName = obj.mapToSFRFColumn(columnName)
        %
        % Inputs:
        %   columnName - time-domain column name (char or string).
        %
        % Output:
        %   sfrfsName - corresponding SFRF column name.

            suffix = obj.sfrfsSuffixInternal;
            sfrfsName = EnsembleUtil.appendSuffix(columnName, suffix);
        end
        
        function temporalName = mapToTemporalFromSFRFColumn(obj, sfrfsName)
        % mapToTemporalFromSFRFColumn Return the temporal column name for 
        % a given SFRF column.
        %
        %   temporalName = obj.mapToTemporalFromSFRFColumn(sfrfsName)
        %
        % Inputs:
        %   sfrfsName - SFRF spectral column name (char or string).
        %
        % Output:
        %   temporalName - corresponding time-domain column name.
        
            suffix = obj.sfrfsSuffixInternal;
            temporalName = EnsembleUtil.removeSuffix(sfrfsName, suffix);
        end
    end
end
