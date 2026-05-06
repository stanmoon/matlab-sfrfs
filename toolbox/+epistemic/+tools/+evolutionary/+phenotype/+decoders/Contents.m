% +decoders
%
% Decoding mechanisms for phenotype parameters.
%
% This package contains the mechanisms that transform genome
% representations into concrete values of phenotype parameters.
%
% Decoders operate on MetagenomeBlock instances and produce matrices
% whose rows correspond to individuals and whose columns correspond to
% the flattened shape of the associated phenotype parameter.
%
% The decoding strategy depends on the PhenotypeParameterKind declared
% in the phenotype descriptor.
%
% Organization
% ------------
% Decoders
%   Dispatcher that selects the appropriate decoding routine based on
%   the phenotype parameter kind.
%
% BoolDecoders
%   Decoding rules for logical phenotype parameters.
%
% IntDecoders
%   Decoding rules for integer-valued phenotype parameters.
%
% RealDecoders
%   Decoding rules for real-valued phenotype parameters.
%
% EnumDecoders
%   Decoding rules for enumerated phenotype parameters.
%
% PermDecoders
%   Decoding rules for permutation-valued phenotype parameters.
%
% Internal details
% ----------------
% Structural validation and reusable numeric transforms used by the
% decoders are implemented in the sibling package
% epistemic.tools.evolutionary.internal.
%
% See also
% --------
% epistemic.tools.evolutionary.genomes
% epistemic.tools.evolutionary.phenotype