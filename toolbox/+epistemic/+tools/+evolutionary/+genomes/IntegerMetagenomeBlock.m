classdef IntegerMetagenomeBlock < ...
        epistemic.tools.evolutionary.genomes.MetagenomeBlock
% IntegerMetagenomeBlock
% Homogeneous metagenome block backed by an integer matrix.
%
% Each entry lies in the declared integer domain [lo, hi], inclusive.

    properties (SetAccess = private)
        lo
        hi
    end

    methods

        function obj = IntegerMetagenomeBlock(args)
            arguments
                args.nIndividuals double
                args.nAtoms double
                args.lo double = 0
                args.hi double = 0
                args.value = []
            end

            meta = ?epistemic.tools.evolutionary.genomes. ...
                IntegerMetagenomeBlock;

            epistemic.tools.evolutionary.internal. ...
                IntegerMetagenomeBlockValidator. ...
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
                    IntegerMetagenomeBlock.buildMatrix_(args);
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
                IntegerMetagenomeBlock;

            epistemic.tools.evolutionary.internal. ...
                IntegerMetagenomeBlockValidator. ...
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
                v = v(:)';
            end

            meta = ?epistemic.tools.evolutionary.genomes. ...
                IntegerMetagenomeBlock;

            % Enforce integer lattice explicitly
            v = round(v);

            epistemic.tools.evolutionary.internal. ...
                IntegerMetagenomeBlockValidator. ...
                mustBeValidAtomUpdate( ...
                meta, obj, i, idx, v);

            obj.matrix(i, idx) = v;
        end

    end

    methods (Static, Access = private)

        function G = buildMatrix_(args)
            range = args.hi - args.lo + 1;

            G = args.lo + randi( ...
                range, args.nIndividuals, args.nAtoms) - 1;
        end

    end

end