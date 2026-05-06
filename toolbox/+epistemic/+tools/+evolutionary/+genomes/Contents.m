% +genomes
%
% Genome representations for evolutionary mechanisms.
%
% This package defines the data model used by the evolutionary machinery.
% Genomes are treated as epistemic artefacts: compact, manipulable
% blueprints of candidate solutions. Operators and selection act on
% these representations, while evaluation is provided externally.
%
% Design
% ------
% The primary representation is the Metagenome, a composite genome formed
% by concatenating one or more MetagenomeBlock instances. Each block is a
% homogeneous matrix backed by a concrete numeric type or a logical type.
%
% Blocks are matrix backed by construction. This enables efficient
% population wide operations and makes variation operators easy to
% implement and test.
%
% Public classes
% --------------
% Metagenome
%   Composite genome formed by an ordered collection of blocks. Supports
%   indexing and concatenation semantics at the block level.
%
% MetagenomeBlock
%   Abstract base class for homogeneous blocks. Exposes matrix access and
%   derived dimensions such as nIndividuals and nAtoms.
%
% Concrete blocks
% ---------------
% BooleanMetagenomeBlock
%   Logical matrix-backed block.
%
% IntegerMetagenomeBlock
%   Integer-valued matrix-backed block.
%
% RealMetagenomeBlock
%   Real-valued matrix-backed block.
%
% ComplexMetagenomeBlock
%   Complex-valued matrix-backed block.
%
% PermutationMetagenomeBlock
%   Integer matrix-backed block whose rows encode permutations or
%   permutation prefixes.
%
% Internal details
% ----------------
% Shared validation utilities live in the sibling package
% epistemic.tools.evolutionary.internal.
%
% See also epistemic.tools.evolutionary
