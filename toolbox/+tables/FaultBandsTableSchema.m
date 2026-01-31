classdef FaultBandsTableSchema < tables.FaultConditionTableMetaSchema
%FaultBandsTableSchema  Schema for fault frequency bands tables.
%
% Extends FaultConditionTableSchema with columns specific to fault
% frequency band definitions.
%
% See also: FaultFrequencyBands, tables.FaultConditionTableMetaSchema

    properties (Constant)
        % Reference frequency band definitions used to construct
        % receptive fields
        RECEPTIVEFIELDBANDS = "ReceptiveFieldBands"
    end
end