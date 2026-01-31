classdef ReceptiveFieldResponseFunctions
% ReceptiveFieldResponseFunctions  A standard library with common receptive
% field response functions (RFRFs)
%
% Static factory methods returning function handles with signature:
%   r = fcn(X, f)
% where:
%   X is a (real or complex) spectrum matrix [nBins x nSnapshots]
%   f is a frequency axis vector            [nBins x 1] (or [1 x nBins])
%
% The returned r contains one scalar response per snapshot/column.

    methods (Static)
        function fcn = integralAbs()
        %integralAbs Response: integral ∘ abs over frequency.
        %
        % r = integralAbs()(X, f) returns:
        %   r(j) = ∫ |X(:,j)| df

            fcn = @(X, f) ...
                ReceptiveFieldResponseFunctions.doIntegralAbs(X, f);
        end

        function fcn = entropy(args)
        %entropy Response: spectral entropy over frequency.
        %
        % Computes Shannon entropy of the magnitude spectrum |X| per
        % snapshot, after normalization to a discrete distribution.
        %
        % r = entropy()(X, f) returns a row vector [1 x nSnapshots].
        %
        % Name-Value:
        %   normalize - If true, divide by log(nBins) to map to [0, 1]
        %               (default: true).
        %   eps       - Positive floor to avoid log(0) (default: 1e-12).

            arguments
                args.normalize (1,1) logical = true
                args.eps (1,1) double {mustBePositive} = 1e-12
            end

            nrm = args.normalize;
            e0  = args.eps;

            fcn = @(X, f) ...
                ReceptiveFieldResponseFunctions.doEntropy(X, f, nrm, e0);
        end

        function fcn = velocityLike(args)
        %velocityLike Convenience: integralAbsFreqScaled with order=1.
            arguments
                args.freqFloorHz (1,1) double {mustBePositive} = 1e-3
            end
            fcn = ReceptiveFieldResponseFunctions.integralAbsFreqScaled(...
                order=1, ...
                freqFloorHz=args.freqFloorHz);
        end
        
        function fcn = displacementLike(args)
        %displacementLike Convenience: integralAbsFreqScaled with order=2.
            arguments
                args.freqFloorHz (1,1) double {mustBePositive} = 1e-3
            end
            fcn = ReceptiveFieldResponseFunctions.integralAbsFreqScaled(...
                order=2, ...
                freqFloorHz=args.freqFloorHz);
        end



        function fcn = integralAbsFreqScaled(args)
        %integralAbsFreqScaled Response: 
        % integral ∘ abs ∘ freqScaling.
        %
        % r(j) = ∫ |(j*2*pi*f)^(-order) X(:,j)| df

        % integral of the absolute value after frequency scaling the 
        % spectrum.
        %
        % This response function implements a one-parameter family of
        % frequency-scaled spectral readouts. It is designed to support the
        % "integral-domain view of signal representations", where classical
        % kinematic representations (velocity, displacement) and fractional
        % accumulation are realized by simple multiplicative scaling in the
        % frequency domain if the spectra corresponds with FFT of 
        % acceleration signals.
        %
        % Given a measured signal with spectrum X(f), define an order 
        % parameter 'order' >= 0 and construct:
        %
        %   X_order(f) = (j*2*pi*f)^(-order) * X(f)
        %
        % This yields anchor points (for spectra of acceleration signals):
        %   order = 0  : measured representation (no scaling)
        %   order = 1  : velocity-like representation
        %   order = 2  : displacement-like representation
        %   order > 0  : fractional/generalized accumulation
        %
        % The response returned by this factory is:
        %
        %   r(j) = ∫ |X_order(:,j)| df
        %
        % i.e., apply the scaling pointwise across frequency, 
        % take magnitude, and integrate over frequency for each snapshot j.
        %
        % Inputs to the returned function handle:
        %   X - complex spectrum [nBins x nSnapshots]
        %   f - frequency axis  [nBins x 1] (Hz), matching size(X,1)
        %
        % Name-Value:
        %   order         - nonnegative scalar controlling scaling power
        %                   (default: 0).
        %   freqFloorHz   - positive scalar frequency floor (Hz) used to
        %                   regularize near f = 0 (default: 1e-3).
        %
        % Low-frequency behavior:
        %   The factor |f|^(-order) amplifies low-frequency content as 
        %   order increases. 
        %   To avoid singular behavior at DC, this implementation uses:
        %       f_eff = max(|f|, freqFloorHz)
        %   before applying the power law scaling.
        %
        % Notes:
        %   - When X is an acceleration spectrum, order=1 and order=2 
        %     correspond to velocity-like and displacement-like spectra up 
        %     to constants and the chosen floor at low frequency.
        %
        % See also: integralAbs, velocityLike, displacementLike

            arguments
                    args.order (1,1) double {mustBeNonnegative} = 0
                    args.freqFloorHz (1,1) double {mustBePositive} = 1e-3
                end
            
                o0 = args.order;
                f0 = args.freqFloorHz;
            
                fcn = @(X, f) ...
                    ReceptiveFieldResponseFunctions.doIntegralAbsFS( ...
                        X, f, o0, f0);
            end
    end

    methods (Static, Access = private)
        function r = doIntegralAbs(X, f)
            f = ReceptiveFieldResponseFunctions.validateXF(X, f);
            r = trapz(f, abs(X), 1);
        end

        function r = doEntropy(X, f, doNormalize, epsVal)
            ReceptiveFieldResponseFunctions.validateXF(X, f); 
            ReceptiveFieldResponseFunctions.validateEps(epsVal);
        
            A = abs(X);
            sumA = max(sum(A, 1), epsVal);
            P = A ./ sumA;
        
            r = -sum(P .* log(P + epsVal), 1);
        
            if doNormalize
                nBins = size(X, 1);
                if nBins > 1
                    r = r ./ log(nBins);
                else
                    r(:) = 0;
                end
            end
        end


        function r = doIntegralAbsFS(X, f, order, freqFloorHz)
            f = ReceptiveFieldResponseFunctions.validateXF(X, f);
        
            ff = max(abs(f), freqFloorHz);
        
            % Convert to angular frequency inside; keep API in Hz.
            omega = 2*pi*ff;
            scale = omega .^ (-order);
        
            A = abs(X) .* scale;
            r = trapz(f, A, 1);
        end

        function f = validateXF(X, f)
            f = f(:);
        
            if ~isnumeric(X) || isempty(X)
            error(['sfrfs:ReceptiveFieldResponseFunctions:' ...
                   'InvalidSpectrum'], ...
                "X must be a nonempty numeric spectrum matrix.");
            end
        
            if numel(f) ~= size(X, 1)
                error(['sfrfs:ReceptiveFieldResponseFunctions:' ...
                       'FreqAxisMismatch'], ...
                    "f length must match size(X,1).");
            end
        
            if any(~isfinite(f))
                error(['sfrfs:ReceptiveFieldResponseFunctions:' ...
                       'InvalidFreqAxis'], ...
                    "f must be finite.");
            end
        end

        function validateEps(epsVal)
            if ~(isscalar(epsVal) && isfinite(epsVal) && epsVal > 0)
                error(['sfrfs:ReceptiveFieldResponseFunctions:' ...
                       'InvalidEps'], ...
                    "eps must be a positive finite scalar.");
            end
        end
    end
end