% +epistemic
%
% This package groups components that serve an epistemic role within the
% toolbox, i.e., components whose purpose is to support knowledge
% acquisition, interpretation, and decision-making under uncertainty.
%
% The emphasis is on epistemic function rather than ontological claims:
% models, algorithms, and theories are treated as cognitive tools and
% instruments, not as intrinsic optimizers or teleological entities.
%
% Disclaimer
% ----------
% The epistemic structuring adopted here is necessarily a simplification.
% It reflects a deliberate balance between conceptual clarity, usability,
% and computational practicality. Ontological refinement is traded, where
% appropriate, for architectural agility and maintainability of the
% computational product. Shortcuts and approximations are therefore taken
% consciously, with the intent of preserving flexibility and iterative
% development.
%
% Subpackages
% -----------
% tools (epistemic instruments)
%   Epistemic tools: reusable instruments that generate, transform, or
%   structure hypotheses, candidates, or representations in support of
%   knowing (e.g., evolutionary mechanisms, inference engines).
%
% actions (epistemic processes)
%   Epistemic actions: interventions performed to reduce uncertainty or
%   refine knowledge, such as inspection, diagnosis, or reconfiguration
%   (to be introduced as needed).
%
% Notes
% -----
% The epistemic layer is intentionally agnostic with respect to purpose
% (optimization, exploration, design) and mechanism. Specific modes of
% use emerge from how tools and actions are composed and configured.
%
% See also epistemic.tools
