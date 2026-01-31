classdef (Abstract) SFRFsParameters < handle
% SFRFsParameters
%
% Abstract base class to store and validate Spectral Fault Receptive Fields
% (SFRF) parameters.
%
% Concrete subclasses define the available fault types. Mask
% parameterization is represented explicitly via MaskParameters.
%
% Example (recommended):
%   params = SFRFsParameters.buildSFRFsParameters( ...
%       order = 2, ...
%       centerMask = ...
%           GaussianMaskParameters(bandwidth = 5), ...
%       surroundMask = ...
%           SuperGaussianMaskParameters(alpha = 12, beta = 4));

    properties (Abstract, Constant)
        faultTypes % Cell array of fault type names specific to subclass
    end

    properties (Constant)
        % SFRF parameter field names
        ORDER_PARAM_NAME             = 'order'
        NUM_SIDEBANDS_PARAM_NAME     = 'numSidebands'
        NUM_HARMONICS_PARAM_NAME     = 'numHarmonics'
        CENTER_MASK_PARAM_NAME       = 'centerMask'
        SURROUND_MASK_PARAM_NAME     = 'surroundMask'
        INHIBITION_FACTOR_PARAM_NAME = 'inhibitionFactor'
        % Legacy
        SIGMA_CENTER_PARAM_NAME        = 'sigmaCenter'
        SIGMA_SURROUND_PARAM_NAME      = 'sigmaSurround'

        % Collection of SFRF parameter field names (backward compatibility)
        sfrfFields = { ...
            SFRFsParameters.ORDER_PARAM_NAME, ...
            SFRFsParameters.NUM_SIDEBANDS_PARAM_NAME, ...
            SFRFsParameters.NUM_HARMONICS_PARAM_NAME, ...
            SFRFsParameters.SIGMA_CENTER_PARAM_NAME, ...
            SFRFsParameters.SIGMA_SURROUND_PARAM_NAME, ...
            SFRFsParameters.INHIBITION_FACTOR_PARAM_NAME ...
        }

        % Collection of SFRF parameter field names (new interface)
        sfrfFieldsForMasks = { ... 
            SFRFsParameters.ORDER_PARAM_NAME, ... 
            SFRFsParameters.NUM_SIDEBANDS_PARAM_NAME, ...
            SFRFsParameters.NUM_HARMONICS_PARAM_NAME, ...
            SFRFsParameters.CENTER_MASK_PARAM_NAME, ...
            SFRFsParameters.SURROUND_MASK_PARAM_NAME, ...
            SFRFsParameters.INHIBITION_FACTOR_PARAM_NAME}
    end

    methods (Abstract)
        params = getParamsForFaultType(obj, faultTypeName)
        % getParamsForFaultType Return the parameter struct for a given 
        % fault type.
        %
        % This method provides a uniform accessor across all 
        % SFRFsParameters subclasses. 
        %
        % Inputs:
        %   faultTypeName - fault type identifier as string scalar or 
        %                   char vector
        %
        % Output:
        %   params - struct containing the SFRF parameters for the fault 
        %            type
        %
        % Implementations must:
        %   - validate the faultTypeName is supported by the subclass
        %   - return a struct with at least the core fields required by the
        %     subclass contract (order, numSidebands, numHarmonics,
        %     inhibitionFactor, either sigmaCenter or centerMask, and 
        %     either sigmaSurround or surroundMask)
    end

    methods (Static)

        function sfrfsParams = buildSFRFsParameters(args)
        % buildSFRFsParameters Builds parameters for Spectral Fault
        % Receptive Fields.
        %
        % sfrfsParams = buildSFRFsParameters('Name',Value,...) creates a
        % struct of parameters for SFRFs with specified values. Unspecified
        % parameters use default values.
        %
        % Parameters:
        %   'order'           - SFRFs order
        %                       (default: 0, integer >= 0)
        %   'numSidebands'    - Number of sidebands
        %                       (default: 2, integer >= 0)
        %   'numHarmonics'    - Number of harmonics
        %                       (default: 10, integer >= 1)
        %   'centerMask'      - MaskParameters instance for the center
        %                       (default: GaussianMaskParameters())
        %   'surroundMask'    - MaskParameters instance for the surround
        %                       (default: GaussianMaskParameters())
        %   'inhibitionFactor'- Inhibition factor
        %                       (default: 0.8, 0 <= value <= 1)
        %


            arguments
                args.order (1,1) ...
                    {mustBeInteger, mustBeNonnegative} = 0
                args.numSidebands (1,1) ...
                    {mustBeInteger, mustBeNonnegative} = 2
                args.numHarmonics (1,1) ...
                    {mustBeInteger, mustBePositive} = 10
                args.centerMask (1,1) MaskParameters = ...
                    GaussianMaskParameters()
                args.surroundMask (1,1) MaskParameters = ...
                    GaussianMaskParameters()
                args.inhibitionFactor (1,1) double { ...
                    mustBeGreaterThanOrEqual(args.inhibitionFactor,0), ...
                    mustBeLessThanOrEqual(args.inhibitionFactor,1)} = 0.8
            end

            sfrfsParams = struct( ...
                SFRFsParameters.ORDER_PARAM_NAME, ...
                args.order, ...
                SFRFsParameters.NUM_SIDEBANDS_PARAM_NAME, ...
                args.numSidebands, ...
                SFRFsParameters.NUM_HARMONICS_PARAM_NAME, ...
                args.numHarmonics, ...
                SFRFsParameters.CENTER_MASK_PARAM_NAME, ...
                args.centerMask, ...
                SFRFsParameters.SURROUND_MASK_PARAM_NAME, ...
                args.surroundMask, ...
                SFRFsParameters.INHIBITION_FACTOR_PARAM_NAME, ...
                args.inhibitionFactor);
        end


        function sfrfsParams = createSFRFsParameters(args)
        % createSFRFsParameters Create parameters for Spectral Fault
        % Receptive Fields.
        %
        % sfrfsParams = createSFRFsParameters('Name',Value,...) creates
        % a struct of parameters for SFRFs with specified values.
        % Unspecified parameters use default values.
        %
        % Parameters:
        %   'order'           - SFRFS order
        %                       (default: 0, integer >= 0)
        %   'numSidebands'    - Number of sidebands
        %                       (default: 2, integer >= 0)
        %   'numHarmonics'    - Number of harmonics
        %                       (default: 10, integer >= 1)
        %   'sigmaCenter'     - [bandwidth, sigmaRule] vector.
        %                       Bandwidth sets the width of the
        %                       Gaussian mask. sigmaRule sets how the
        %                       frequency band limits are handled; for
        %                       example, sigmaRule = 3 means the band
        %                       covers ±3 times the bandwidth,
        %                       99.7% of the Gaussian area falls within
        %                       the band. (default: [4, 6])
        %   'sigmaSurround'   - [bandwidth, sigmaRule] vector. Same
        %                       structure and meaning as sigmaCenter.
        %                       (default: [12, 1])
        %   'inhibitionFactor'- Inhibition factor
        %                       (default: 0.8, 0 <= value <= 1)
        %
        % Example:
        %   params = ...
        %      SFRFsParameters.createSFRFsParameters(...
        %      'order', 2, 'sigmaCenter', [5, 7]);
        %

            arguments
                args.order (1,1) ...
                    {mustBeInteger, mustBeNonnegative} = 0;
                args.numSidebands (1,1) ...
                    {mustBeInteger, mustBeNonnegative} = 2;
                args.numHarmonics (1,1) ...
                    {mustBeInteger, mustBePositive} = 10;
                args.sigmaCenter (1,2) double {mustBePositive} = [4, 6];
                args.sigmaSurround (1,2) double {mustBePositive} = [12, 1];
                args.inhibitionFactor (1,1) double { ...
                    mustBeGreaterThanOrEqual(args.inhibitionFactor,0), ...
                    mustBeLessThanOrEqual(args.inhibitionFactor,1)} = 0.8;
            end

            centerMask = GaussianMaskParameters( ...
                bandwidth = args.sigmaCenter(1), ...
                sigmaRule = args.sigmaCenter(2));

            surroundMask = GaussianMaskParameters( ...
                bandwidth = args.sigmaSurround(1), ...
                sigmaRule = args.sigmaSurround(2));


            sfrfsParams = struct(...
                SFRFsParameters.ORDER_PARAM_NAME, ...
                args.order, ...
                SFRFsParameters.NUM_SIDEBANDS_PARAM_NAME, ...
                args.numSidebands, ...
                SFRFsParameters.NUM_HARMONICS_PARAM_NAME, ...
                args.numHarmonics, ...
                SFRFsParameters.SIGMA_CENTER_PARAM_NAME, ...
                args.sigmaCenter, ...
                SFRFsParameters.SIGMA_SURROUND_PARAM_NAME, ...
                args.sigmaSurround, ...
                SFRFsParameters.CENTER_MASK_PARAM_NAME, ...
                centerMask, ...
                SFRFsParameters.SURROUND_MASK_PARAM_NAME, ...
                surroundMask, ...
                SFRFsParameters.INHIBITION_FACTOR_PARAM_NAME, ...
                args.inhibitionFactor);

        end
    end
end