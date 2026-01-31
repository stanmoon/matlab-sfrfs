classdef BandMapSchema
% BandMapSchema  Key constants for receptive-field band map entries

    properties (Constant)
        % Opponent band definition struct (see structs.OpponentBandsSchema)
        BANDS = 'Bands'

        % Harmonic index (1 = fundamental)
        HARMONIC = 'Harmonic'

        % Human-readable fault frequency label (e.g. '2Fi+1Fr')
        LABEL = 'Label'

        % Sideband index (0 = none, ±k = modulation order)
        SIDEBAND = 'Sideband'
    end
end
