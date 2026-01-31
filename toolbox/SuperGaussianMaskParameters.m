classdef SuperGaussianMaskParameters < MaskParameters
% SuperGaussianMaskParameters
%
% Parameter container for super-Gaussian mask profiles.
%
% The associated (continuous) super-Gaussian mask profile is:
%
%   G(f) = exp( - |(f - f_c) / alpha|^beta )
%
% where:
%   - f_c    is the mask center frequency (defined externally),
%   - alpha  is a positive scale parameter,
%   - beta   is a positive shape exponent controlling profile sharpness.
%
% Relation to GaussianMaskParameters:
%   The Gaussian mask defined in GaussianMaskParameters corresponds to the
%   special case beta = 2 of the super-Gaussian family, where:
%
%     Gaussian:       G(f) = exp( -1/2 * ((f - f_c) / sigma)^2 )
%     Super-Gaussian: G(f) = exp( - ((f - f_c) / alpha)^2 )
%
%   To obtain a super-Gaussian mask equivalent to a Gaussian mask
%   parameterized by (bandwidth, sigmaRule):
%
%     sigma = bandwidth / (2 * sigmaRule)
%     alpha = sqrt(2) * sigma = bandwidth / (sqrt(2) * sigmaRule)
%
%   With beta = 2 and this alpha mapping, both masks are identical.
%
% Parameter keys:
%   - alpha     : positive scalar, scale parameter
%   - beta      : positive scalar, shape exponent
%   - bandwidth : positive scalar, reference width (bandwidth = 2*alpha)
%
% Notes:
%   - Mask evaluation is handled elsewhere (FrequencyMask.superGauss).
%

    properties (Constant)
        BANDWIDTH_PARAM_NAME = 'bandwidth'
        ALPHA_PARAM_NAME     = 'alpha'
        BETA_PARAM_NAME      = 'beta'
    end

    properties (Dependent)
        bandwidth
        alpha
        beta
    end

    methods
        function obj = SuperGaussianMaskParameters(args)
            % Construct super-Gaussian mask parameters.
            arguments
                args.alpha (1,1) double {mustBePositive} = 4
                args.beta  (1,1) double {mustBePositive} = 2
            end

            p = struct( ...
                SuperGaussianMaskParameters.ALPHA_PARAM_NAME, ...
                args.alpha, ...
                SuperGaussianMaskParameters.BETA_PARAM_NAME, ...
                args.beta, ...
                SuperGaussianMaskParameters.BANDWIDTH_PARAM_NAME, ...
                args.alpha*2);

            obj@MaskParameters(p);
        end

        function bw = getReferenceBandwidth(obj)
            % Return the reference bandwidth (Hz).
            bw = obj.bandwidth;
        end

        function v = get.bandwidth(obj)
            % Reference bandwidth.
            v = obj.params.(...
                SuperGaussianMaskParameters.BANDWIDTH_PARAM_NAME);
        end

        function v = get.alpha(obj)
            % Scale parameter.
            v = obj.params.(SuperGaussianMaskParameters.ALPHA_PARAM_NAME);
        end

        function v = get.beta(obj)
            % Shape exponent.
            v = obj.params.(SuperGaussianMaskParameters.BETA_PARAM_NAME);
        end
    end
end
