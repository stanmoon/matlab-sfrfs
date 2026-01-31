classdef FaultConditionTableMetaSchema
%FaultConditionTableMetaSchema  Column name definitions for fault-condition
% tables.
%
% A fault-condition table stores fault-specific records evaluated at
% concrete operating conditions and is uniquely selectable by the key:
%   (FaultGroup, Speed, Load)
%
% This class centralizes column name constants for fault-condition tables,
% avoiding hardcoded string literals.
%
% See also: FaultFrequencyBands, ReceptiveFieldGainFunctions

    properties (Constant)
        % Fault identifier (numeric group code defining the fault type)
        FAULTGROUP = "FaultGroup"

        % Operating-condition axis: shaft rotational speed (Hz)
        SPEED = "Speed"

        % Operating-condition axis: applied load (kN)
        LOAD = "Load"

        % Human-readable fault description (e.g. "Outer Race Fault")
        DESCRIPTION = "Description"
    end
end
