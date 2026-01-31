classdef OpponentBandsSchema
% OpponentBandsSchema  Field name constants for opponent frequency bands

    properties (Constant)
        % Center (excitatory) opponent band [fLow, fHigh] in Hz
        CENTER = "Center"

        % Surround (inhibitory) opponent band [fLow, fHigh] in Hz
        SURROUND = "Surround"
    end
end
