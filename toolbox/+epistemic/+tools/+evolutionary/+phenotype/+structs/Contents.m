% +structs
%
% Structural schemas for phenotype parameters.
%
% This package defines lightweight, declarative data structures that act
% as representational contracts shared by genomes, decoders, and
% environments.
%
% The emphasis is on stable structure and semantics rather than behavior.
%
% In particular, these schemas describe:
%   - phenotype parameter blueprints (names, kinds, domains, shapes),
%   - auxiliary metadata required to assemble, validate, and iterate over
%     parameters in a representation-agnostic way.
%
% The schemas are intentionally:
%   - constructed through validated factories and treated as immutable,
%   - minimal yet extensible,
%   - independent of any specific genome encoding or quantization scheme.
%
% Encoding-level concerns (e.g. bit resolution, rounding, quantization)
% are handled elsewhere.
%
% Public structs
% --------------
% PhenotypeParameterSchema
%   Declarative schema describing a phenotype parameter.
%
% See also
% --------
% epistemic.tools.evolutionary.genomes
% epistemic.tools.evolutionary.environments