% +environments
%
% Environment contracts for evolutionary search.
%
% This package defines the Environment interface used by evolutionary
% mechanisms to evaluate candidate solutions. An Environment specifies
% the semantics of evaluation (e.g., objective values, constraints) but
% does not prescribe how candidates are generated or selected.
%
% The Environment concept is meaningful only within the evolutionary
% metaphor: it represents the fitness landscape or evaluation context
% against which populations adapt.
%
% Concrete problem definitions may be implemented anywhere else, provided
% they respect the interface defined here.
%
% See also evolutionary
