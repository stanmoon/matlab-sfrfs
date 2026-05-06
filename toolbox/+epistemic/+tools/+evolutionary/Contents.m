% +evolutionary
%
% This package provides evolutionary mechanisms as epistemic tools.
% The components defined here implement population-based generative
% processes driven by variation, selection, and survival. They are used
% to structure, explore, and evaluate candidate solutions.
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
%   - genotype structures and decoding mechanisms,
%   - variation operators (mutation, recombination),
%   - parent and survivor selection policies,
%   - replacement and survival policies,
%   - diversity preservation instruments.
%
% Evaluation objectives, domain-specific evaluators, and application logic
% are intentionally kept outside this package and injected from above.
%
% Organization
% ------------
% Public components are grouped into conceptual subpackages:
%
%   genomes
%     Representations of individuals at the genotype level.
%
%   phenotype
%     Mechanisms that map genotypes to interpretable parameter
%     representations.
%
%   operators
%     Variation mechanisms that generate offspring from parents.
%
%   selection
%     Decision policies that choose parents and survivors.
%
%   environments
%     Contracts that define how candidate solutions are evaluated.
%
% Internal details
% ----------------
% Implementation details are placed in internal subpackages close to their
% point of use to support encapsulation and refactoring. Internal
% components are not part of the supported public API.
%
% Notes
% -----
% This package is agnostic with respect to the mode of use (optimization,
% exploration, design). Such modes emerge from how evolutionary mechanisms
% are parameterized, composed, and coupled to external evaluators.
%
% See also epistemic.tools