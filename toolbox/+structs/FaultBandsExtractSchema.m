classdef FaultBandsExtractSchema
%FaultBandsExtractSchema  Field names for FaultFrequencyBands.extractBands.
%
% Defines the struct fields returned by extractBands(). This schema is
% independent of table schemas to keep computational outputs stable even
% if tabular representations change.
%
% See also: FaultFrequencyBands, tables.FaultBandsTableSchema

    properties (Constant)
        % Numeric fault group identifier
        FAULTGROUP = "FaultGroup"

        % Operating speed associated with the extracted bands (Hz)
        SPEED = "Speed"

        % Operating load associated with the extracted bands (kN)
        LOAD = "Load"

        % Total number of band entries extracted
        NUMBEROFBANDS = "NumberOfBands"

        % Column index for minimum frequency in band matrices
        MINFREQCOLUMN = "MinFreqColumn"

        % Column index for maximum frequency in band matrices
        MAXFREQCOLUMN = "MaxFreqColumn"

        % Column index for harmonic number in band matrices
        HARMONICCOLUMN = "HarmonicColumn"

        % Column index for sideband index in band matrices
        SIDEBANDCOLUMN = "SidebandColumn"

        % Row index of the characteristic (1× fundamental, no sideband)
        CHARACTERISTICFREQUENCYINDEX = ...
            "CharacteristicFrequencyIndex"

        % Sorted matrix of center frequency bands
        CENTERBANDSMATRIX = "CenterBandsMatrix"

        % Sorted matrix of surround frequency bands
        SURROUNDBANDSMATRIX = "SurroundBandsMatrix"
    end
end
