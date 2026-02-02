% +parents
%
% Parent selection policies for evolutionary search.
%
% This package provides selection policies that choose candidates from the
% current population to form mating pools. Parent selection operates on
% evaluated populations and determines which candidates participate in
% variation operators.
%
% Parent selection policies are decision mechanisms: they do not modify
% candidates directly and do not encode variation or replacement logic.
%
% Instrumental computations required by parent selection (e.g., ranking or
% diversity measures) are delegated to internal subpackages of the parent
% selection context.
%
% See also +evolutionary/+selection
