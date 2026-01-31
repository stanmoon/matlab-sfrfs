classdef FrequencyBankMasksSchema
% FrequencyBankMasksSchema  Field name constants for frequency-bank masks
%
% Defines the struct fields stored in the FrequencyBankMasks table column
% produced by ReceptiveFieldGainFunctions.
%
% This schema describes fault-condition record-level frequency masks
% computed by RFGFs.
%
% Notes:
%   - CENTER and SURROUND are primary masks produced by the masking stage.
%   - CONTRAST is the opponent (center–surround) channel stored as a stable,
%     derived artifact for downstream consumers.
%
% See also: ReceptiveFieldGainFunctions, tables.GainFunctionsTableSchema

    properties (Constant)
        % Center (excitatory) frequency-bank gain mask
        CENTER = "CenterFrequencyBankMask"

        % Surround (inhibitory) frequency-bank gain mask
        SURROUND = "SurroundFrequencyBankMask"

        % Opponent / contrast frequency-bank mask (derived)
        CONTRAST = "ContrastFrequencyBankMask"
    end
end
