classdef FrequencyMask
% FrequencyMask Utility class for computing frequency domain masks
%
% Current support:
%   - Gaussian masks.
%   - Super-Gaussian masks.
%       (Super-Gaussian includes Gaussian as a special case but
%        is parameterized differently to allow varying shape.)
%
% New unified entry point:
%   G = FrequencyMask.evaluate(f, band, maskParams)
%
% Legacy utilities remain:
%   - G = FrequencyMask.gaussian(f, band, sigmaRule, normalize)
%   - G = FrequencyMask.superGauss(f, band, beta)

    methods (Static)

        function G = evaluate(f, band, maskParams)
            % evaluate  Evaluate a mask given MaskParameters.
            %
            % Usage:
            %   G = FrequencyMask.evaluate(f, band, maskParams)
            %
            % Inputs:
            %   f         Frequency domain vector (Hz)
            %   band      Two element vector [fMin, fMax] defining the 
            %             frequency band (Hz)
            %   maskParams MaskParameters instance 
            %              (e.g., GaussianMaskParameters,
            %                     SuperGaussianMaskParameters)
            %
            % Output:
            %   G         Mask vector (same length as f)

            arguments
                f (:,1) double
                band (1,2) double {mustBeNonnegative}
                maskParams (1,1) MaskParameters
            end

            if isa(maskParams, "GaussianMaskParameters")
                G = FrequencyMask.gaussian( ...
                    f, band, maskParams.sigmaRule, maskParams.normalize);
                return
            end

            if isa(maskParams, "SuperGaussianMaskParameters")
                G = FrequencyMask.superGauss(...
                    f, band, maskParams.alpha, maskParams.beta);
                return
            end

            error("sfrfs:FrequencyMask:evaluate:UnsupportedMaskType", ...
                "Unsupported mask parameters type: %s", class(maskParams));
        end

        function G = gaussian(f, band, sigmaRule, normalize)
            % gaussian Generate Gaussian mask over a frequency band.
            %
            % Usage:
            %   G = FrequencyMask.gaussian(f, band)
            %   G = FrequencyMask.gaussian(f, band, sigmaRule)
            %   G = FrequencyMask.gaussian(f, band, sigmaRule, normalize)
            %
            % Inputs:
            %   f         Frequency domain vector (Hz)
            %   band      Two element vector [fMin, fMax] defining the band
            %             (Hz)
            %   sigmaRule Bandwidth divisor to sigma (default: 3)
            %   normalize Logical to normalize area to 1 (default: false)
            %
            % Output:
            %   G         Gaussian mask vector (same length as f)

            arguments
                f (:,1) double
                band (1,2) double {mustBeNonnegative}
                sigmaRule (1,1) double {mustBePositive} = 3
                normalize (1,1) logical = false
            end

            % Ensure column vector
            f = f(:);

            % Compute parameters
            fMin = band(1);
            fMax = band(2);
            centerFreq = (fMin + fMax) / 2;
            bandwidth = fMax - fMin;
            sigmaF = bandwidth / (2 * sigmaRule);

            % Compute Gaussian
            G = exp(-0.5 * ((f - centerFreq) / sigmaF).^2);

            % Normalize if needed
            if normalize
                df = mean(diff(f));
                if df == 0
                    df = 1;
                end
                area = sum(G) * df;
                G = G / area;
            end
        end

        function G = superGauss(f, band, alpha, beta)
        % superGauss Generate a super-Gaussian frequency mask.
        %
        %   G = FrequencyMask.superGauss(f, band, alpha, beta)
        %
        %   Computes a super-Gaussian mask
        %
        %       G(f) = exp( - |(f - f_c) / alpha|^beta )
        %
        %   where f_c is the center frequency of the band [fMin, fMax].
        %
        %   Semantics:
        %   - The scale parameter alpha is constrained to
        %
        %         alpha = (fMax - fMin) / 2
        %
        %   - The shape parameter beta controls the sharpness of the
        %     profile (beta = 2 corresponds to a Gaussian-equivalent
        %     shape).
        %
        %   Inputs:
        %     f      - Frequency vector (Hz).
        %     band   - Two-element vector [fMin, fMax].
        %     alpha  - Scale parameter (must match half-bandwidth).
        %     beta   - Positive shape exponent.
        %
        %   Output:
        %     G      - Super-Gaussian mask evaluated at f.
        %
        %   Errors:
        %     sfrfs:FrequencyMask:superGauss:AlphaMismatch

            arguments
                f (:,1) double
                band (1,2) double {mustBeNonnegative}
                alpha (1,1) double {mustBePositive}
                beta  (1,1) double {mustBePositive}
            end

            f = f(:);
            fMin = band(1);
            fMax = band(2);
            centerFreq = mean(band);

            % Consistency check: expected half-bandwidth semantics.
            expectedAlpha = (fMax - fMin) / 2;

            % relative tolerance
            tol = 1e-12;
            denom = max(1, abs(expectedAlpha));
            if abs(alpha - expectedAlpha) / denom > tol
                error("sfrfs:FrequencyMask:superGauss:AlphaMismatch", ...
                    ['SuperGaussian alpha mismatch. Expected alpha = ' ...
                    '(fMax - fMin)/2 = %.15g, but got %.15g.'], ...
                    expectedAlpha, alpha);
            end

            G = exp(-abs((f - centerFreq) / alpha).^beta);
        end

    end
end
