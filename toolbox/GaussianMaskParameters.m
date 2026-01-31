classdef GaussianMaskParameters < MaskParameters
% GaussianMaskParameters
%
% Parameter container for Gaussian mask profiles.
%
% The associated (continuous) Gaussian mask profile is:
%
%   G(f) = exp( -1/2 * ((f - f_c) / sigma)^2 )
%
% where:
%   - f_c     is the mask center frequency (defined externally),
%   - sigma   is derived from the reference bandwidth and sigmaRule as
%             sigma = bandwidth / (2 * sigmaRule).
%
% This class stores parameters in the inherited struct dictionary while
% providing a stable, explicit ontology for the Gaussian family.
%
% Expected parameter keys (conventions are local to this toolbox):
%   - bandwidth   : positive scalar, in Hz (reference width)
%   - sigmaRule   : positive scalar, dimensionless
%   - normalize   : logical scalar (optional)
%
% Notes:
%   - Mask evaluation and discretization are handled elsewhere
%     (e.g., FrequencyMask.gaussian).
%

    properties (Constant)
        BANDWIDTH_PARAM_NAME  = 'bandwidth'
        SIGMARULE_PARAM_NAME  = 'sigmaRule'
        NORMALIZE_PARAM_NAME  = 'normalize'
    end

    properties (Dependent)
        bandwidth
        sigmaRule
        normalize
    end

    methods
        function obj = GaussianMaskParameters(args)
            % Construct Gaussian mask parameters.
            arguments
                args.bandwidth (1,1) double {mustBePositive} = 4
                args.sigmaRule (1,1) double {mustBePositive} = 3
                args.normalize (1,1) logical = false
            end

            p = struct( ...
                GaussianMaskParameters.BANDWIDTH_PARAM_NAME, ...
                args.bandwidth, ...
                GaussianMaskParameters.SIGMARULE_PARAM_NAME, ...
                args.sigmaRule, ...
                GaussianMaskParameters.NORMALIZE_PARAM_NAME, ...
                args.normalize);

            obj@MaskParameters(p);
        end

        function bw = getReferenceBandwidth(obj)
            % Return the reference bandwidth (Hz).
            bw = obj.bandwidth;
        end

        function v = get.bandwidth(obj)
            % Reference bandwidth.
            v = obj.params.(GaussianMaskParameters.BANDWIDTH_PARAM_NAME);
        end

        function v = get.sigmaRule(obj)
            % Sigma rule.
            v = obj.params.(GaussianMaskParameters.SIGMARULE_PARAM_NAME);
        end

        function v = get.normalize(obj)
            % Normalization flag.
            v = obj.params.(GaussianMaskParameters.NORMALIZE_PARAM_NAME);
        end
    end
end
