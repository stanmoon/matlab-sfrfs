% +survivors
%
% Survivor selection and replacement policies for evolutionary search.
%
% This package provides policies that determine which candidates persist
% into the next generation. Survivor selection operates on evaluated
% populations and may consider parents, offspring, or combined pools,
% depending on the evolutionary engine configuration.
%
% Survivor selection is a decision mechanism: it selects candidates for
% retention and does not implement variation operators or evaluation.
%
% Instrumental computations required by survivor selection (e.g.,
% dominance sorting, crowding, sharing, clearing) are delegated to internal
% subpackages of the selection context.
%
% See also +evolutionary/+selection
