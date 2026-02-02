% +internal
%
% Internal support routines for genetic operators.
%
% This package contains helper routines used by genetic variation operators
% to implement representation-specific or low-level transformation logic.
% Functions defined here support operator implementations but are not
% themselves operators.
%
% Internal operator routines typically handle details such as encoding
% conventions, index manipulations, boundary handling, or specialized
% crossover and mutation mechanics. These details are intentionally hidden
% to keep the public operator interface concise and stable.
%
% Components in this package are not part of the supported public API and
% may change without notice.
%
% See also +evolutionary/+operators
