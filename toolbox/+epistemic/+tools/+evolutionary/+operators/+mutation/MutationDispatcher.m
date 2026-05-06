classdef MutationDispatcher
% MutationDispatcher
%
% Execute agenda-defined mutation for one generation.
%
% Purpose
%   Resolve mutation operationally for a fixed generation by:
%     1. iterating individuals,
%     2. consuming agenda iterators,
%     3. dispatching row-local atom indices to block mutators.
%
% Notes
%   - Mutation targets come from MutationAgenda.
%   - Mutation geometry is induced by block type.
%   - Mutation is executed strictly in genome space.

    methods (Static)

        function executeGeneration(args)
            arguments
                args.metagenome (1,1) ...
                    epistemic.tools.evolutionary.genomes.Metagenome
                args.agenda (1,1) ...
                    epistemic.tools.evolutionary. ...
                    operators.mutation.MutationAgenda
                args.config (1,1) ...
                    epistemic.tools.evolutionary.EngineConfig
                args.generationIndex (1,1) double
            end

            g = args.generationIndex;
            nIndividuals = args.metagenome.nIndividuals;
            nBlocks = args.metagenome.nBlocks;
            blocks = args.metagenome.asBlocks();

            mutateFcns = cell(1, nBlocks);

            for b = 1:nBlocks
                mutateFcns{b} = epistemic.tools.evolutionary. ...
                    operators.mutation.Mutators.infer( ...
                    block=blocks{b}, ...
                    config=args.config);
            end

            for i = 1:nIndividuals
                next = args.agenda.iterator(g, i);

                while true
                    [ok, b, atomIndices] = next();

                    if ~ok
                        break
                    end

                    mutateFcns{b}(blocks{b}, i, atomIndices);
                end
            end
        end

    end
end