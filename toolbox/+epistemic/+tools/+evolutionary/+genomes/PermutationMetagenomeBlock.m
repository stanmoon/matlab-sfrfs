classdef PermutationMetagenomeBlock < ...
        epistemic.tools.evolutionary.genomes.MetagenomeBlock
% PermutationMetagenomeBlock
% Homogeneous metagenome block backed by an integer matrix with
% no repeated entries per row.
%
% Domain semantics
%   - Each row has length nAtoms.
%   - The ambient sampling domain is 1:n, with n >= nAtoms.
%   - Rows therefore represent ordered samples without replacement from
%     1:n.
%   - The canonical permutation case is recovered when n = nAtoms.
%
% Initialization
%   - Explicit value must be a canonical permutation of 1:nAtoms in each
%     row. In that case, the effective ambient domain is n = nAtoms.
%   - Random initialization draws a length-nAtoms prefix from a
%     permutation of 1:n, with n >= nAtoms.
%
% Exactly one of {value, n} may be specified. If neither is specified,
% random initialization with n = nAtoms is used.
%
% Notes
%   The effective ambient domain size n is retained as block state so that
%   downstream operators can recover the intended genomic domain.

    properties (SetAccess = private)
        n
    end

    methods
        function obj = PermutationMetagenomeBlock(args)
            arguments
                args.nIndividuals (1,1) double
                args.nAtoms (1,1) double
                args.value = []
                args.n = []
            end

            meta = ?epistemic.tools.evolutionary.genomes. ...
                PermutationMetagenomeBlock;

            epistemic.tools.evolutionary.internal. ...
                PermutationMetagenomeBlockValidator. ...
                validateConstructorInputs( ...
                meta, ...
                args.nIndividuals, ...
                args.nAtoms, ...
                args.value, ...
                args.n);

            if ~isempty(args.value)
                epistemic.tools.evolutionary.internal. ...
                    PermutationMetagenomeBlockValidator. ...
                    validateExplicitValue( ...
                    meta, ...
                    args.value, ...
                    args.nIndividuals, ...
                    args.nAtoms);
            end

            nEff = epistemic.tools.evolutionary.internal. ...
                PermutationMetagenomeBlockValidator. ...
                resolveDomainSize( ...
                meta, ...
                args.nAtoms, ...
                args.value, ...
                args.n);

            if ~isempty(args.value)
                G = args.value;
            else
                G = epistemic.tools.evolutionary.genomes. ...
                    PermutationMetagenomeBlock.randomPermMatrix_( ...
                    args.nIndividuals, ...
                    args.nAtoms, ...
                    nEff);
            end

            obj@epistemic.tools.evolutionary.genomes.MetagenomeBlock( ...
                matrix = G);

            obj.n = nEff;
        end

        function values = getAtoms(obj, args)
            arguments
                obj (1,1)
                args.individualIndex (1,1) double
                args.atomIndices (:,1) double
            end

            i = args.individualIndex;
            idx = args.atomIndices(:)';

            meta = ?epistemic.tools.evolutionary.genomes. ...
                PermutationMetagenomeBlock;

            epistemic.tools.evolutionary.internal. ...
                PermutationMetagenomeBlockValidator. ...
                mustBeValidAtomIndices( ...
                meta, obj, i, idx);

            values = obj.matrix(i, idx);
        end

        function setAtoms(obj, args)
            arguments
                obj (1,1)
                args.individualIndex (1,1) double
                args.atomIndices (:,1) double
                args.values
            end

            i = args.individualIndex;
            idx = args.atomIndices(:)';
            v = args.values;

            if isscalar(v)
                v = repmat(v, 1, numel(idx));
            else
                v = reshape(v, 1, []);
            end

            meta = ?epistemic.tools.evolutionary.genomes. ...
                PermutationMetagenomeBlock;

            epistemic.tools.evolutionary.internal. ...
                PermutationMetagenomeBlockValidator. ...
                mustBeValidAtomUpdate( ...
                meta, obj, i, idx, v);

            obj.matrix(i, idx) = v;
        end

        function swapAtoms(obj, args)
        % swapAtoms  Swap two atom positions in one row.
            arguments
                obj (1,1)
                args.individualIndex (1,1) double
                args.atomIndexA (1,1) double
                args.atomIndexB (1,1) double
            end

            i = args.individualIndex;
            a = args.atomIndexA;
            b = args.atomIndexB;

            meta = ?epistemic.tools.evolutionary.genomes. ...
                PermutationMetagenomeBlock;

            epistemic.tools.evolutionary.internal. ...
                PermutationMetagenomeBlockValidator. ...
                mustBeValidSwapArgs( ...
                meta, obj, i, a, b);

            if a == b
                return
            end

            tmp = obj.matrix(i, a);
            obj.matrix(i, a) = obj.matrix(i, b);
            obj.matrix(i, b) = tmp;
        end
    end

    methods (Static, Access = private)

        function G = randomPermMatrix_(nIndividuals, nAtoms, n)
            G = zeros(nIndividuals, nAtoms);

            for i = 1:nIndividuals
                p = randperm(n);
                G(i, :) = p(1:nAtoms);
            end
        end

    end
end