classdef (Abstract) SFRFsParameters < handle
    % SFRFsParameters Abstract base class to store and validate Spectral
    % Fault Receptive Fields (SFRF) parameters.
    %
    %   Stores validated SFRF parameter sets for different fault types
    %   having those fault types defined in the concrete extending classes.
    %
    %   Supports:
    %     - Definition of fault types via an abstract constant property.
    %     - Creation of SFRF parameter structs using a generic fully 
    %       implemented static method.
    %
    % Properties:
    %   (Concrete subclasses define properties specific to domain.)
    %
    % Abstract Constant Properties:
    %   faultTypes - Cell array of fault type names for a given subclass.
    %
    % Static Methods:
    %   createSFRFsParameters - Create parameter struct for SFRFs.
    %
    
    properties (Abstract, Constant)
        faultTypes % Cell array of fault type names specific to subclass
    end

    properties (Constant)
        % SFRF parameter field names 
        ORDER_PARAM_NAME               = 'order'
        NUM_SIDEBANDS_PARAM_NAME       = 'numSidebands'
        NUM_HARMONICS_PARAM_NAME       = 'numHarmonics'
        SIGMA_CENTER_PARAM_NAME        = 'sigmaCenter'
        SIGMA_SURROUND_PARAM_NAME      = 'sigmaSurround'
        INHIBITION_FACTOR_PARAM_NAME   = 'inhibitionFactor'
    
        % Collection of all SFRF parameter field names
        sfrfFields = { ...
            SFRFsParameters.ORDER_PARAM_NAME, ...
            SFRFsParameters.NUM_SIDEBANDS_PARAM_NAME, ...
            SFRFsParameters.NUM_HARMONICS_PARAM_NAME, ...
            SFRFsParameters.SIGMA_CENTER_PARAM_NAME, ...
            SFRFsParameters.SIGMA_SURROUND_PARAM_NAME, ...
            SFRFsParameters.INHIBITION_FACTOR_PARAM_NAME ...
        }
    end
    
    methods (Static)

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
            
            sfrfsParams = struct(...
                'order', args.order, ...
                'numSidebands', args.numSidebands, ...
                'numHarmonics', args.numHarmonics, ...
                'sigmaCenter', args.sigmaCenter, ...
                'sigmaSurround', args.sigmaSurround, ...
                'inhibitionFactor', args.inhibitionFactor);
        end
    end
end

