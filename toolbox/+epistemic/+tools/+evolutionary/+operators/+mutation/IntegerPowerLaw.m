classdef IntegerPowerLaw < ...
        epistemic.tools.evolutionary.operators.mutation.IncrementLaw
% IntegerPowerLaw
% Integer-valued bounded power-law increment law.
%
% The law reuses the continuous PowerLaw construction and projects sampled
% increments onto the integer lattice via rounding. 

    properties (SetAccess = protected)
        alpha  % power-law exponent (scalar)
        rMin   % minimal increment magnitude (fixed to 0.5)
    end

    properties (Access = private)
        continuousLaw
    end

    methods

        function obj = IntegerPowerLaw(args)
        % IntegerPowerLaw  Construct integer-valued increment law.

            arguments
                args.lo (1,1) double
                args.hi (1,1) double
                args.alpha (1,1) double
            end

            obj@epistemic.tools.evolutionary.operators. ...
                mutation.IncrementLaw( ...
                args.lo, args.hi);

            classMeta = ?epistemic.tools.evolutionary. ...
                operators.mutation.IntegerPowerLaw;

            checks = ...
                epistemic.tools.evolutionary.internal.ValidationUtils;

            checks.mustBeIntegerScalar( ...
                args.lo, classMeta, "BadLo", ...
                "lo must be an integer scalar.");

            checks.mustBeIntegerScalar( ...
                args.hi, classMeta, "BadHi", ...
                "hi must be an integer scalar.");

            checks.mustBePositiveScalar( ...
                args.alpha, classMeta, "BadAlpha", ...
                "alpha must satisfy alpha > 0.");

            obj.alpha = args.alpha;
            obj.rMin = 0.5;

            obj.continuousLaw = epistemic.tools.evolutionary. ...
                operators.mutation.PowerLaw( ...
                lo = args.lo, ...
                hi = args.hi, ...
                alpha = args.alpha, ...
                rMin = obj.rMin);
        end

        function delta = sample(obj, x)
        % sample
        % Sample integer-valued bounded increments for current values x.

            classMeta = ?epistemic.tools.evolutionary. ...
                operators.mutation.IntegerPowerLaw;

            checks = ...
                epistemic.tools.evolutionary.internal.ValidationUtils;

            checks.mustBeIntegerMatrix( ...
                x, classMeta, "BadCurrentValues", "x");

            checks.mustBeInClosedInterval( ...
                x, obj.lo, obj.hi, classMeta, ...
                "BadCurrentValues", ...
                "x must lie within the bounded integer domain.");

            delta = round(obj.continuousLaw.sample(x));
        end

    end

end