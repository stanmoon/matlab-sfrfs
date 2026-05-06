% +epistemic
%
% Root namespace for epistemic tools and supporting utilities.
%
% This package gathers components that support structured reasoning,
% representation, and exploration through reusable computational
% mechanisms. The emphasis is not on a single algorithmic paradigm,
% but on providing building blocks that help engineers organize
% candidate structures, validate assumptions, and compose
% domain-facing workflows.
%
% Scope
% -----
% The package provides:
%   - helper utilities shared across packages,
%   - subpackages implementing specific epistemic mechanisms,
%   - clear separation between public APIs and internal
%     implementation details.
%
% Organization
% ------------
% Public components are grouped into conceptual subpackages:
%
%   helpers
%     General-purpose utilities used by higher-level packages.
%
%   tools
%     Epistemic instruments and mechanisms. This includes specialized
%     tool families such as evolutionary components.
%
% Notes
% -----
% Subpackages define the actual mechanisms and contracts. This root
% package serves as the common namespace and top-level organizational
% entry point.
%
% See also
% --------
% epistemic.helpers
% epistemic.tools