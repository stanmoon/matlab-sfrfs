classdef BooleanMetagenomeBlock < ...
        epistemic.tools.evolutionary.genomes.MetagenomeBlock
% BooleanMetagenomeBlock
% Homogeneous metagenome block backed by a logical matrix.

    methods
        function obj = BooleanMetagenomeBlock(args)
            arguments
                args.nIndividuals double
                args.nAtoms double
                args.value = []
                args.probability = []
            end

            meta = ?epistemic.tools.evolutionary.genomes. ...
                BooleanMetagenomeBlock;

            epistemic.tools.evolutionary.internal. ...
                BooleanMetagenomeBlockValidator. ...
                validateConstructorInputs( ...
                meta, ...
                args.nIndividuals, ...
                args.nAtoms, ...
                args.value, ...
                args.probability);

            G = epistemic.tools.evolutionary.genomes. ...
                BooleanMetagenomeBlock.buildMatrix_(args);

            obj@epistemic.tools.evolutionary.genomes.MetagenomeBlock( ...
                matrix=G);
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
                v = repmat(logical(v), 1, numel(idx));
            else
                v = logical(v);
            end

            meta = ?epistemic.tools.evolutionary.genomes. ...
                BooleanMetagenomeBlock;

            epistemic.tools.evolutionary.internal. ...
                BooleanMetagenomeBlockValidator. ...
                mustBeValidAtomUpdate(meta, obj, i, idx, v);

            obj.matrix(i, idx) = v;
        end

        function flipAtoms(obj, args)
            arguments
                obj (1,1)
                args.individualIndex (1,1) double
                args.atomIndices (:,1) double
            end

            i = args.individualIndex;
            idx = args.atomIndices(:)';

            meta = ?epistemic.tools.evolutionary.genomes. ...
                BooleanMetagenomeBlock;

            epistemic.tools.evolutionary.internal. ...
                BooleanMetagenomeBlockValidator. ...
                mustBeValidAtomIndices(meta, obj, i, idx);

            obj.matrix(i, idx) = ~obj.matrix(i, idx);
        end
    end

    methods (Static, Access = private)
        function G = buildMatrix_(args)
            if ~isempty(args.value)

                if islogical(args.value) && isscalar(args.value)
                    G = repmat( ...
                        args.value, ...
                        args.nIndividuals, ...
                        args.nAtoms);
                else
                    G = args.value;
                end

            else

                probability = 0.5;
                if ~isempty(args.probability)
                    probability = args.probability;
                end

                G = rand(args.nIndividuals, args.nAtoms) < probability;
            end
        end
    end
end