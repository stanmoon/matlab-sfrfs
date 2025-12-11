classdef FrequencyMask
% FrequencyMask Utility class for computing frequency domain masks
%
% Current support:
%   - Gaussian masks.
%   - Super-Gaussian masks.
%       (Super-Gaussian includes Gaussian as a special case but 
%        is parameterized differently to allow varying shape.)
    
    methods (Static)
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
        
        function G = superGauss(f, band, beta)
        % superGauss Generate super-Gaussian mask over a frequency band.
        %
        % Usage:
        %   G = FrequencyMask.superGauss(f, band, beta)
        %
        % Inputs:
        %   f      Frequency domain vector (Hz)
        %   band   Two-element vector [fMin, fMax] with the frequency band
        %   beta   Positive shape exponent controlling the shape factor of
        %          the mask:
        %               - < 0,  raises an error, mathematically possible
        %                       but results in a minimum at the central
        %                       frequency rather than a maximum.
        %               - = 0,  raises an error, constant value.
        %               - = 1,  Laplacian, close to triangular inside the
        %                       monitoring bandwith
        %               - = 2,  Gaussian, profile.
        %               - > 2,  flatter shape, decays slower than a
        %                       Gaussian.
        %               - >> 2, tends to a square shaped mask. 
        %
        % Output:
        %   G      Super-Gaussian mask vector (same length as f)
        %
        % Note:
        %   The mask width parameter alpha is set equal to the bandwidth:
        %       alpha = bandwidth (fMax - fMin)
            
            arguments
                f (:,1) double
                band (1,2) double {mustBeNonnegative}
                beta (1,1) double {mustBePositive}
            end
            
            f = f(:);
            fMin = band(1);
            fMax = band(2);
            centerFreq = mean(band);
            bandwidth = fMax - fMin;
            
            alpha = bandwidth;
            
            G = exp(-abs((f - centerFreq) / alpha).^beta);
        end

    end
end
