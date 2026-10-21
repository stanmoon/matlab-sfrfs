classdef ContrastPolarityFilter
%CONTRASTPOLARITYFILTER Cross-sensor contrast polarity agreement filter.
%
% Resolves harmonic contrast from two sensors using signed polarity
% agreement and a quantile-based agreement floor with asymmetric
% temporal smoothing.
%
% The static apply method returns retained harmonic indices, the
% updated floor history, resolved contrast, and shared magnitudes.
%
% Reference:
% Muñoz Gutiérrez, S., and Wotawa, F. (2026).
% Spectral Contrast Polarity Analysis and Adaptive Sensor Fusion
% for Bearing Degradation Monitoring.
% In Proceedings of the 2026 IEEE International Conference on
% Dependable Systems and Applications (DSA 2026). IEEE.
% (To appear.)

    methods (Static)

        function [Hrel, tau, c, s] = apply( ...
                cV, cH, t, tau, q, alphaUp, alphaDown)

            arguments
                cV {mustBeNumeric, mustBeReal}
                cH {mustBeNumeric, mustBeReal}
                t (1,1) {mustBeInteger, mustBePositive}
                tau {mustBeNumeric, mustBeReal}
                q (1,1) { ...
                    mustBeNumeric, ...
                    mustBeReal, ...
                    mustBeGreaterThanOrEqual(q, 0), ...
                    mustBeLessThanOrEqual(q, 1)}
                alphaUp (1,1) { ...
                    mustBeNumeric, ...
                    mustBeReal, ...
                    mustBeGreaterThanOrEqual(alphaUp, 0), ...
                    mustBeLessThanOrEqual(alphaUp, 1)}
                alphaDown (1,1) { ...
                    mustBeNumeric, ...
                    mustBeReal, ...
                    mustBeGreaterThanOrEqual(alphaDown, 0), ...
                    mustBeLessThanOrEqual(alphaDown, 1)}
            end

            ContrastPolarityFilter.mustHaveSameSize(cV, cH);
            ContrastPolarityFilter.mustBeFiniteContrast(cV, cH);
            ContrastPolarityFilter.mustHaveValidFloor(tau, t);

            s = min(abs(cV), abs(cH));

            p = sign(cV) .* sign(cH);

            r = p .* s;

            tauHat = max(0, quantile(r(:), q));

            tau = ContrastPolarityFilter.updateFloor( ...
                tau, t, tauHat, alphaUp, alphaDown);

            c = zeros(size(cV), "like", cV);

            reliableMask = (p == 1) & (s >= tau(t));

            c(reliableMask) = 0.5 .* ...
                (cV(reliableMask) + cH(reliableMask));

            Hrel = find(reliableMask);

        end

    end

    methods (Static, Access = private)

        function tau = updateFloor(tau, t, tauHat, alphaUp, alphaDown)

            if numel(tau) < t
                tau(t) = 0;
            end

            if t == 1
                tau(t) = tauHat;
                return
            end

            delta = tauHat - tau(t - 1);

            if delta > 0
                tau(t) = tau(t - 1) + alphaUp * delta;
            else
                tau(t) = tau(t - 1) + alphaDown * delta;
            end

        end

        function mustHaveSameSize(cV, cH)

            if ~isequal(size(cV), size(cH))
                error( ...
                    "sfrfs:ContrastPolarityFilter:SizeMismatch", ...
                    "Contrast vectors must have the same size.");
            end

        end

        function mustBeFiniteContrast(cV, cH)

            if any(~isfinite(cV(:))) || any(~isfinite(cH(:)))
                error( ...
                    "sfrfs:ContrastPolarityFilter:InvalidContrast", ...
                    "Contrast vectors must contain only finite values.");
            end

        end

        function mustHaveValidFloor(tau, t)

            if isempty(tau)
                error( ...
                    "sfrfs:ContrastPolarityFilter:InvalidFloor", ...
                    "Agreement floor must not be empty.");
            end

            if any(~isfinite(tau(:))) || any(tau(:) < 0)
                error( ...
                    "sfrfs:ContrastPolarityFilter:InvalidFloor", ...
                    "Agreement floor must contain finite nonnegative values.");
            end

            if t > 1 && numel(tau) < t - 1
                error( ...
                    "sfrfs:ContrastPolarityFilter:InvalidFloor", ...
                    "Agreement floor history is shorter than t - 1.");
            end

        end

    end

end