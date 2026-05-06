% +internal
%
% Internal validation and transformation routines for the evolutionary
% engine.
%
% This package contains supporting components used by the evolutionary
% representation and decoding infrastructure. These routines provide
% shared validation logic, schema utilities, and reusable numeric
% transformations used by genomes, phenotype decoders, and parameter
% descriptors.
%
% The components here implement low-level checks and helper operations
% that enforce representation invariants and consistency across the
% evolutionary data model.
%
% Scope
% -----
% The utilities in this package include:
%   - validation helpers for genome and phenotype structures,
%   - descriptor and schema utilities,
%   - reusable decoding transformations,
%   - shared low-level validation primitives.
%
% These routines are intentionally separated from public classes in
% order to keep public APIs concise while centralizing validation and
% transformation logic.
%
% Notes
% -----
% Components in this package are internal implementation details and are
% not part of the supported public API. Their interfaces and behavior may
% change as the evolutionary infrastructure evolves.
%
% See also epistemic.tools.evolutionary