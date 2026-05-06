classdef ComplexMetagenomeBlock < ...
        epistemic.tools.evolutionary.genomes.MetagenomeBlock
% ComplexMetagenomeBlock
% Homogeneous metagenome block backed by a complex-valued matrix.
%
% Each entry lies in the declared annulus
%     { z in C : lo <= |z| <= hi }.
%
% Notes
%   The declared radial domain is retained as block state so that
%   downstream operators can recover the intended genomic bounds.

    properties (SetAccess = private)
        lo
        hi
    end

    methods
        function obj = ComplexMetagenomeBlock(args)
            arguments
                args.nIndividuals double
                args.nAtoms double
                args.lo double = 0
                args.hi double = 0
                args.value = []
            end

            meta = ?epistemic.tools.evolutionary.genomes. ...
                ComplexMetagenomeBlock;

            epistemic.tools.evolutionary.internal. ...
                ComplexMetagenomeBlockValidator. ...
                validateConstructorInputs( ...
                meta, ...
                args.nIndividuals, ...
                args.nAtoms, ...
                args.lo, ...
                args.hi, ...
                args.value);

            if ~isempty(args.value)
                G = args.value;
            else
                G = epistemic.tools.evolutionary.genomes. ...
                    ComplexMetagenomeBlock.buildMatrix_(args);
            end

            obj@epistemic.tools.evolutionary.genomes.MetagenomeBlock( ...
                matrix=G);

            obj.lo = args.lo;
            obj.hi = args.hi;
        end

        function values = getAtoms(obj, args)
            arguments
                obj (1,1)
                args.individualIndex (1,1) double
                args.atomIndices (:,1) double
            end

            i = args.individualIndex;
            idx = args.atomIndices(:).';

            meta = ?epistemic.tools.evolutionary.genomes. ...
                ComplexMetagenomeBlock;

            epistemic.tools.evolutionary.internal. ...
                ComplexMetagenomeBlockValidator.mustBeValidAtomIndices( ...
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
            idx = args.atomIndices(:).';
            v = args.values;

            if isscalar(v)
                v = repmat(v, 1, numel(idx));
            else
                v = v(:).';
            end

            meta = ?epistemic.tools.evolutionary.genomes. ...
                ComplexMetagenomeBlock;

            epistemic.tools.evolutionary.internal. ...
                ComplexMetagenomeBlockValidator.mustBeValidAtomUpdate( ...
                meta, obj, i, idx, v);

            obj.matrix(i, idx) = v;
        end
    end

    methods (Static, Access = private)
        function G = buildMatrix_(args)
            rho = args.lo + (args.hi - args.lo) .* ...
                rand(args.nIndividuals, args.nAtoms);

            phi = 2 * pi * rand(args.nIndividuals, args.nAtoms);

            G = rho .* exp(1i * phi);
        end
    end
end