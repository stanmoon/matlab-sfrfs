classdef MutationLocusSchema
% MutationLocusSchema  Field name constants for mutation locus structs
%
% A mutation locus identifies a single mutation target as the pair
% (block index, atom index).

    properties (Constant)

        % Block index of the mutation locus
        BLOCK_INDEX = "blockIndex"

        % Atom index within the block
        ATOM_INDEX = "atomIndex"

    end

end