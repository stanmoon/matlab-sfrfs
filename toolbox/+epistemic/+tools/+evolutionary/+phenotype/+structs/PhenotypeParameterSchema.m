classdef PhenotypeParameterSchema
% PhenotypeParameterSchema  Field name constants for phenotype parameters
%
% A phenotype parameter spec is a scalar struct with a fixed outer shape.
% Semantics depend on the parameter kind. 
% Encoding concerns are out of scope.

    properties (Constant)
        % Human-facing identifier (free-form string, e.g. "\Sigma_1")
        NAME = "name"

        % Discriminator for the semantic type (PhenotypeParameterKind)
        KIND = "kind"

        % Kind-dependent mathematical constraints (struct, may be empty)
        DOMAIN = "domain"

        % Arity of the parameter (default [1 1]; scalar, vector, matrix)
        SHAPE = "shape"

    end

end
