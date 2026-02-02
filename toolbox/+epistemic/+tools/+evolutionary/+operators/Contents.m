% +operators
%
% Genetic variation operators for evolutionary search.
%
% This package provides variation mechanisms that generate new candidate
% solutions from existing ones. Operators act on candidate representations
% (e.g., genotypes or phenotypes) and introduce variation through mutation,
% recombination, or crossover.
%
% Operators are treated instrumentally: they do not encode goals or
% selection criteria. Their role is to expand and perturb the candidate
% space explored by evolutionary processes.
%
% Operator implementations may rely on internal helper routines for
% representation-specific logic. Such helpers are kept in internal
% subpackages and are not part of the public API.
%
% See also +evolutionary
