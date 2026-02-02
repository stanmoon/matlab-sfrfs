% +evolutionary
%
% This package provides evolutionary mechanisms as epistemic tools.
% The components defined here implement population-based generative
% processes driven by variation, selection, and survival. They are used
% to structure, explore, and evaluate candidate solutions or artefacts.
%
% Evolutionary mechanisms are treated instrumentally: their role is to
% induce epistemic structure in the reasoning process of the human
% engineer over sets of candidates, rather than to act as intrinsic
% optimizers or teleological designers.
%
% Scope
% -----
% The implementation focuses on generic evolutionary machinery, including:
%   - population and individual representations,
%   - variation operators (mutation, recombination),
%   - parent and survivor selection policies,
%   - replacement and survival policies,
%   - multiobjective selection instruments (e.g., Pareto fronts),
%   - diversity preservation instruments (e.g., crowding, sharing).
%
% Evaluation objectives, domain-specific evaluators, and application logic
% (e.g., FAHRE) are intentionally kept outside this package and injected
% from above.
%
% Organization
% ------------
% Public components are grouped into small conceptual subpackages:
%   operators
%     Variation mechanisms that generate offspring from parents.
%
%   selection
%     Decision policies that choose parents and survivors. Instrumental
%     routines used by selection policies (e.g., dominance sorting,
%     crowding distance, sharing, clearing) are kept in internal
%     subpackages to preserve a crisp public surface.
%
%   environments
%     The Environment contract is defined here as part of the evolutionary
%     metaphor. Concrete problems may be implemented anywhere else by
%     subclassing this contract.
%
% Internal details
% ----------------
% Implementation details are placed in internal subpackages close to their
% point of use (branch or leaf) to support encapsulation and refactoring.
% Internal components are not part of the supported public API.
%
% Notes
% -----
% This package is agnostic with respect to the mode of use (optimization,
% exploration, design). Such modes emerge from how evolutionary mechanisms
% are parameterized, composed, and coupled to external evaluators.
%
% See also epistemic.tools
