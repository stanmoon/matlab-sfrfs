classdef Metagenome < handle
% Metagenome
% Integrates a collection of MetagenomeBlock objects.
%
% The metagenome stores multiple genotype blocks that share a row axis.
% All blocks must have the same number of individuals (rows).

    properties (Access = private)
        blocks (1,:) cell
    end

    properties (Dependent, SetAccess = private)
        nBlocks (1,1) double
        nIndividuals (1,1) double
    end

    properties (Constant, Access = private)
        blockClass = ?epistemic.tools.evolutionary.genomes.MetagenomeBlock
    end

    methods
        function obj = Metagenome(args)
            arguments
                args.blocks (1,:) cell
            end

            obj.setBlocks(args.blocks);
        end

        function n = get.nBlocks(obj)
            n = numel(obj.blocks);
        end

        function n = get.nIndividuals(obj)
            if isempty(obj.blocks)
                n = 0;
                return
            end
            n = obj.blocks{1}.nIndividuals;
        end

        function B = asBlocks(obj)
            % asBlocks
            % Return the live block cell array (handle objects).
            B = obj.blocks;
        end

        function obj = add(obj, block)
            arguments
                obj
                block (1,1) ...
                    epistemic.tools.evolutionary.genomes.MetagenomeBlock
            end

            obj.admitBlock_(block);
            obj.blocks = [obj.blocks, {block}];
        end

        function obj = addAll(obj, blocks)
            arguments
                obj
                blocks (1,:) cell
            end

            blocks = obj.admitBlocksForAppend_(blocks);
            if isempty(blocks)
                return
            end

            obj.blocks = [obj.blocks, blocks];
        end

        function out = subsref(obj, S)
            import epistemic.helpers.CellContainerIndexingDelegate

            out = CellContainerIndexingDelegate.subsrefOrBuiltin( ...
                obj, obj.blocks, S);
        end

        function obj = subsasgn(obj, S, value)
            import epistemic.helpers.CellContainerIndexingDelegate

            assignFirstHopFn = @(k, v) obj.replaceBlock(k, v);

            [handled, obj.blocks] = ...
                CellContainerIndexingDelegate.trySubsasgnBrace( ...
                    obj.blocks, S, value, assignFirstHopFn);

            if handled
                return
            end

            obj = builtin("subsasgn", obj, S, value);
        end
    end

    methods (Access = private)
        function setBlocks(obj, blocks)
            blocks = obj.admitBlocksForSet_(blocks);
            obj.blocks = blocks;
        end

        function replaceBlock(obj, k, value)
            obj.assertCanReplaceBlock_(k);
            obj.admitBlock_(value);
            obj.blocks{k} = value;
        end

        function blocks = admitBlocksForSet_(obj, blocks)
            import epistemic.tools.evolutionary.internal.MetagenomeValidator

            MetagenomeValidator.mustBeNonEmptyBlocks(blocks);

            MetagenomeValidator.mustAllBeBlocks( ...
                blocks, obj.blockClass);

            MetagenomeValidator.mustShareNIndividuals(blocks);
        end

        function blocks = admitBlocksForAppend_(obj, blocks)
            import epistemic.tools.evolutionary.internal.MetagenomeValidator

            if isempty(blocks)
                return
            end

            MetagenomeValidator.mustAllBeBlocks( ...
                blocks, obj.blockClass);

            obj.assertAppendRowCompatibility_(blocks);
        end

        function admitBlock_(obj, block)
            import epistemic.tools.evolutionary.internal.MetagenomeValidator

            MetagenomeValidator.mustBeBlock( ...
                block, obj.blockClass);

            obj.assertAppendRowCompatibility_(block);
        end

        function assertCanReplaceBlock_(obj, k)
            import epistemic.tools.evolutionary.internal.MetagenomeValidator

            MetagenomeValidator.mustBeIntegerScalarIndex(k, obj.nBlocks);
        end

        function assertAppendRowCompatibility_(obj, x)
            % assertAppendRowCompatibility_
            % Enforce row axis compatibility for append style admissions.
            %
            % If the container is empty, any admitted block(s) define the
            % row axis. If non empty, admitted block(s) must match the
            % current nIndividuals.

            import epistemic.tools.evolutionary.internal.MetagenomeValidator

            if obj.nBlocks == 0
                if iscell(x)
                    MetagenomeValidator.mustShareNIndividuals(x);
                end
                return
            end

            n = obj.nIndividuals;

            if iscell(x)
                for k = 1:numel(x)
                    MetagenomeValidator.mustMatchNIndividuals(x{k}, n);
                end
                return
            end

            MetagenomeValidator.mustMatchNIndividuals(x, n);
        end
    end
end