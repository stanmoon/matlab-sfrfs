% +selection
%
% Selection and replacement policies for evolutionary search.
%
% This package provides decision policies that choose candidates from a
% population for reproduction and survival. Selection operates on evaluated
% populations and determines which candidates act as parents and which are
% retained as survivors across generations.
%
% Subpackages
% -----------
% parents
%   Parent selection policies used to construct mating pools from the
%   current population (e.g., tournament, roulette).
%
% survivors
%   Survivor selection and replacement policies that determine which
%   candidates persist into the next generation (e.g., elitist).
%
% Instrumental routines required by selection policies (e.g., dominance
% relations, multiobjective ranking, crowding, sharing, clearing) are kept
% in internal subpackages. These routines support decision-making but are
% not exposed as part of the public API.
%
% See also +evolutionary
