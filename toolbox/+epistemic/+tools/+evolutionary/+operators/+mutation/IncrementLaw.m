classdef (Abstract) IncrementLaw
% IncrementLaw
% Abstract base class for bounded increment laws.

    properties (SetAccess = protected)
        lo  % lower bound (scalar)
        hi  % upper bound (scalar)
    end

    methods
        function obj = IncrementLaw(lo, hi)
        % IncrementLaw
        % Construct bounded increment law.

            classMeta = ...
                ?epistemic.tools.evolutionary.operators.mutation. ...
                IncrementLaw;

            epistemic.tools.evolutionary.internal.ValidationUtils. ...
                mustHaveStrictOrder( ...
                lo, hi, classMeta, "BadBounds", ...
                "Require finite bounds with lo < hi.");

            obj.lo = lo;
            obj.hi = hi;
        end
    end

    methods (Abstract)
        % sample
        % Sample increments for current values x.
        %
        %   x     : current values
        %   delta : sampled increments, same size as x
        delta = sample(obj, x)
    end
end