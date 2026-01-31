classdef GainFunctionsTableSchema < tables.FaultBandsTableSchema
% GainFunctionsTableSchema  Column name constants for gain-functions tables
%
% This schema centralizes column names produced and consumed by
% ReceptiveFieldGainFunctions and downstream SFRFsCompute.
%
% See also: ReceptiveFieldGainFunctions, SFRFsCompute,
%           tables.FaultBandsTableSchema

    properties (Constant)
        % Frequency-bank masks per fault condition
        FREQUENCYBANKMASKS = "FrequencyBankMasks"

        % Computed SFRF responses
        SFRFS = "SFRFs"
    end
end
