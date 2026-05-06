% +phenotype
%
% Phenotype-side representations and schemas for the evolutionary engine.
%
% This package defines the structures used to describe phenotype
% parameters and their concrete values as produced by decoding and
% developmental expression.
%
% Conceptual alignment
% --------------------
%   genome  -> genotype representation
%   phenotype parameters (x) -> phenotype
%
% Accordingly, this package focuses on:
%   - phenotype parameter schemas (names, kinds, domains, shapes),
%   - descriptors that freeze phenotypic blueprints,
%   - expressions that hold concrete parameter values,
%   - contracts used by environments to evaluate phenotypes.
%
% Encoding-level concerns (e.g. mutation, quantization, resolution)
% belong to genome-side representations or decoding mechanisms.
%
% Public classes
% --------------
% DevelopmentalExpressionModel
%   Produces phenotype parameter values from decoded genome
%   representations.
%
% PhenotypeParametersDescriptor
%   Immutable descriptor defining the structure of phenotype parameters.
%
% PhenotypeParameterExpression
%   Representation holding concrete phenotype parameter values.
%
% PhenotypeParameterKind
%   Enumeration of supported phenotype parameter kinds.
%
% PhenotypeParametersConstraints
%   Structural constraints applied to phenotype descriptors.
%
% Subpackages
% -----------
% decoders
%   Mechanisms that transform genome representations into phenotype
%   parameter values.
%
% structs
%   Declarative schemas defining the structure and semantics of phenotype
%   parameters and descriptors.
%
% See also
% --------
% epistemic.tools.evolutionary.genomes
% epistemic.tools.evolutionary.environments