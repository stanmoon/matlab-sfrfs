classdef PowerLaw < epistemic.tools.evolutionary.operators. ...
        mutation.IncrementLaw
% PowerLaw
% Truncated bounded power-law increment law.

    properties (SetAccess = protected)
        alpha  % power-law exponent (scalar)
        rMin   % minimal increment magnitude (scalar)
    end

    methods

        function obj = PowerLaw(args)
        % PowerLaw  Construct bounded power-law increment law.

            arguments
                args.lo (1,1) double
                args.hi (1,1) double
                args.alpha (1,1) double
                args.rMin (1,1) double = 1.0e-10
            end

            obj@epistemic.tools.evolutionary.operators. ...
                mutation.IncrementLaw( ...
                args.lo, args.hi);

            classMeta = ...
                ?epistemic.tools.evolutionary.operators.mutation.PowerLaw;

            span = args.hi - args.lo;

            checks = ...
                epistemic.tools.evolutionary.internal.ValidationUtils;

            checks.mustBePositiveScalar( ...
                args.alpha, classMeta, "BadAlpha", ...
                "alpha must satisfy alpha > 0.");

            checks.mustBePositiveScalar( ...
                args.rMin, classMeta, "BadRMin", ...
                "rMin must satisfy rMin > 0.");

            checks.mustBeInClosedInterval( ...
                args.rMin, 0, span / 2, classMeta, "BadRMin", ...
                "rMin must satisfy rMin <= (hi - lo) / 2.");

            obj.alpha = args.alpha;
            obj.rMin = args.rMin;
        end

        function delta = sample(obj, x)
        % sample
        % Sample bounded increments for current values x.

            classMeta = ...
                ?epistemic.tools.evolutionary.operators.mutation.PowerLaw;

            epistemic.tools.evolutionary.internal.ValidationUtils. ...
                mustBeInClosedInterval( ...
                x, obj.lo, obj.hi, classMeta, ...
                "BadCurrentValues", ...
                "x must lie within the bounded domain.");

            delta = zeros(size(x));

            for k = 1:numel(x)
                L = x(k) - obj.lo;
                R = obj.hi - x(k);

                delta(k) = obj.sampleOne_(L, R);
            end
        end
    end

    methods (Access = private)

        function r = sampleOne_(obj, L, R)

            if L >= obj.rMin
                aL = obj.accumulatedMass_(L);
            else
                aL = 0;
            end

            if R >= obj.rMin
                aR = obj.accumulatedMass_(R);
            else
                aR = 0;
            end

            total = aL + aR;
            u = rand();

            if u < aL / total
                a = aL - u * total;
                mag = obj.inverseAccumulatedMass_(a);
                r = -mag;
            else
                a = u * total - aL;
                mag = obj.inverseAccumulatedMass_(a);
                r = mag;
            end
        end

        function a = accumulatedMass_(obj, S)

            if S < obj.rMin
                a = 0;
                return
            end

            if obj.alpha == 1
                a = log(S / obj.rMin);
                return
            end

            p = 1 - obj.alpha;
            a = (S^p - obj.rMin^p) / p;
        end

        function s = inverseAccumulatedMass_(obj, a)

            if a < 0
                a = 0;
            end

            if obj.alpha == 1
                s = obj.rMin * exp(a);
                return
            end

            p = 1 - obj.alpha;
            s = (obj.rMin^p + p * a)^(1 / p);
        end
    end
end