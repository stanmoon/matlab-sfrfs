classdef PhenotypeParameterKind
% PhenotypeParameterKind
%
% Enumeration of semantic kinds for phenotype parameters.
%
% The kind of a parameter determines how its DOMAIN field is interpreted
% during validation and decoding, and how parameter values are mapped from
% genotype to phenotype parameter state.
%
% This enumeration captures *semantic intent*, not encoding details.
% Quantization, bit resolution, and decoding policies are handled elsewhere.
%
% See also:
%   PhenotypeParameterSchema

    enumeration
        % Continuous real-valued parameter.
        %
        % The parameter takes values in a real interval (scalar parameters)
        % or in a Cartesian product of real intervals (array-valued).
        %
        % Domain semantics:
        %   - Scalar parameter (shape = [1 1]):
        %       domain.lo and domain.hi are scalars defining [lo, hi].
        %
        %   - Array-valued parameter (shape ~= [1 1]):
        %       domain.lo and domain.hi are arrays of size `shape`,
        %       defining elementwise bounds. Each element is constrained
        %       independently to its corresponding interval.
        %
        %   - Homogeneous bounds may be specified by providing scalar 
        %     lo/hi. These are implicitly broadcast to all array elements.
        %
        % Implementations may flatten bounds for vectorized computation.
        % This is a representational detail, not a semantic one.
        %
        % Example uses:
        %   gains, scaling factors, continuous coefficients
        %
        Real

        % Discrete integer-valued parameter.
        %
        % The parameter takes integer values in a bounded interval (scalar
        % parameters) or in a Cartesian product of bounded intervals
        % (array-valued).
        %
        % Domain semantics:
        %   - Scalar parameter:
        %       domain.lo and domain.hi define the integer interval.
        %
        %   - Array-valued parameter:
        %       domain.lo and domain.hi are arrays of size `shape`,
        %       defining elementwise integer bounds.
        %
        %   - Scalar bounds may be provided and are interpreted as
        %       homogeneous bounds applied to all elements.
        %
        % Rounding, quantization, and projection are handled by the
        % Developmental Expression Model, not by domain semantics.
        %
        % Example uses:
        %   orders, counts, discrete indices
        %
        Int


        % Logical (boolean) parameter.
        %
        % The parameter takes values true or false.
        % Domain constraints are typically unnecessary.
        %
        % Example uses:
        %   enable/disable flags, binary switches
        %
        Bool

        % Categorical (enumerated) parameter.
        %
        % The parameter takes one value from a finite set specified by
        % domain.values (string array).
        %
        % Example uses:
        %   modes, strategies, configuration labels
        %
        Enum

        % Permutation-valued parameter.
        %
        % The parameter represents a permutation of a finite index set,
        % typically specified by domain.n.
        %
        % Example uses:
        %   orderings, rankings, schedules
        %
        Perm

        % User-defined parameter kind.
        %
        % This entry acts as an explicit placeholder for custom or
        % domain-specific parameter kinds whose semantics are not part of
        % the built-in vocabulary.
        %
        %
        % No assumptions are made by the core engine about the mathematical
        % structure, admissible values, or decoding rules of Custom kinds.
        %
        %
        Custom
    end
end
