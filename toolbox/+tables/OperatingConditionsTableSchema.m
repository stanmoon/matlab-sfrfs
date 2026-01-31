classdef OperatingConditionsTableSchema
% OperatingConditionsTableSchema  Column name constants for operating
% conditions tables
%
% This schema centralizes column name constants used by
% OperatingConditions.conditionsTable.
%
% See also OperatingConditions

    properties (Constant)
        % Operating-condition axis: shaft rotational speed (Hz)
        SPEED = "Speed"

        % Operating-condition axis: applied load (kN)
        LOAD = "Load"
    end
end
