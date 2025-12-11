classdef OperatingConditions
% OPERATINGCONDITIONS Encapsulates a table of operating conditions.
%
%   This class stores an operating conditions table having columns
%   'Speed' and 'Load'.
%
%   Example:
%       speeds = [35; 37.5; 40];
%       loads  = [12; 11; 10];
%       oc = OperatingConditions(speeds, loads);
%       disp(oc.conditionsTable)
%
%   Properties:
%       conditionsTable     - Table of [N x 2] with 'Speed' and 'Load'.
%
%   Methods:
%       OperatingConditions - Constructor (see below)
%
%   Inputs:
%       speed - Numeric column vector of speeds (Hz)
%       load  - Numeric column vector of loads (kN)
%
%   Raises:
%       'sfrfs:OperatingConditions:DimAgree' if speed and load are not 
%       the same length.
%
%   Reference:
%      B. Wang et al., “A Hybrid Prognostics Approach for Estimating 
%      Remaining Useful Life of Rolling Element Bearings”, 
%      IEEE Trans. Reliability, 2018.
%      DOI: 10.1109/TR.2018.2882682

    properties (SetAccess = immutable)
        conditionsTable table % Table with 'Speed','Load' columns
    end

    methods
        function obj = OperatingConditions(speed, load)
            % OPERATINGCONDITIONS Construct the table from speed and load 
            % vectors.
            arguments
                speed (:,1) double
                load  (:,1) double
            end
            if numel(speed) ~= numel(load)
                error('sfrfs:OperatingConditions:DimAgree', ...
                      'Speed and load dimensions must agree.');
            end
            obj.conditionsTable = table(speed, load, ...
                'VariableNames', {'Speed', 'Load'});

            log = SFRFsLogger.getLogger();
            if log.isFineEnabled()
                log.fine(obj.toString());
            end
        end

        function str = toString(obj)
            % compact JSON string of the operatingConditions table.
            str = "[OperatingConditions: " +...
                jsonencode(obj.conditionsTable) + ...
                "]";
        end
    end
end
