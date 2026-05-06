classdef RealMetagenomeBlock < ...
        epistemic.tools.evolutionary.genomes.MetagenomeBlock
% RealMetagenomeBlock
% Homogeneous metagenome block backed by a real-valued matrix.
%
% Each entry lies in the declared real domain [lo, hi].
%
% Notes
% - Provided mainly for completeness; real-valued phenotypes are usually
%   obtained via decoding mappings from discrete genomes.
% - The declared domain is retained as block state so that downstream
%   operators can recover the intended genomic bounds.

    properties (SetAccess = private)
        lo
        hi
    end

    methods
        function obj = RealMetagenomeBlock(args)
            arguments
                args.nIndividuals double
                args.nAtoms double
                args.lo double = 0
                args.hi double = 0
                args.value = []
            end

            import epistemic.tools.evolutionary.genomes.RealMetagenomeBlock

            meta = ?epistemic.tools.evolutionary.genomes. ...
                RealMetagenomeBlock;

            epistemic.tools.evolutionary.internal. ...
                RealMetagenomeBlockValidator.validateConstructorInputs( ...
                meta, ...
                args.nIndividuals, ...
                args.nAtoms, ...
                args.lo, ...
                args.hi, ...
                args.value);

            if ~isempty(args.value)
                G = args.value;
            else
                G = RealMetagenomeBlock.buildMatrix_(args);
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
            idx = args.atomIndices(:)';

            meta = ?epistemic.tools.evolutionary.genomes. ...
                RealMetagenomeBlock;

            epistemic.tools.evolutionary.internal. ...
                RealMetagenomeBlockValidator.mustBeValidAtomIndices( ...
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
                v = v(:)';
            end

            meta = ?epistemic.tools.evolutionary.genomes. ...
                RealMetagenomeBlock;

            epistemic.tools.evolutionary.internal. ...
                RealMetagenomeBlockValidator.mustBeValidAtomUpdate( ...
                meta, obj, i, idx, v);

            obj.matrix(i, idx) = v;
        end
    end

    methods (Static, Access = private)
        function G = buildMatrix_(args)
            span = args.hi - args.lo;

            G = args.lo + span .* ...
                rand(args.nIndividuals, args.nAtoms);
        end
    end
end