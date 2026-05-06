classdef MutationAgenda < handle
% MutationAgenda
%
% Domain-aware mutation agenda for evolutionary runs.
%
% Purpose
%   Encodes mutation *admission* independently of mutation semantics.
%   For each (generation, individual), stores the loci to be mutated.
%
% Structure
%   (g,i) -> [(block, atom); ...]
%
% Notes
%   - Sampling is binomial per block with rate rho.
%   - Atom selection is uniform without replacement.
%   - No mutation semantics are applied here (agenda only).
%   - iterator(g,i) returns a consumable stateful callable that yields
%     contiguous block runs as (blockIndex, atomIndices).

    properties (Access = private)

        % Domain
        nGenerations
        nIndividuals
        nBlocks

        % Block structure
        nAtomsPerBlock

        % Mutation parameter
        rho

        % Agenda storage
        % size: {G x P}
        % each cell: [k x 2] -> (block, atom)
        Agenda

    end

    methods

        function obj = MutationAgenda(args)

            arguments
                args.nGenerations   (1,1) double
                args.nIndividuals   (1,1) double
                args.nAtomsPerBlock double
                args.rho            (1,1) double
            end

            epistemic.tools.evolutionary.internal. ...
                MutationAgendaValidator.validateConstructorInputs( ...
                ?epistemic.tools.evolutionary. ...
                    operators.mutation.MutationAgenda, ...
                args.nGenerations, ...
                args.nIndividuals, ...
                args.nAtomsPerBlock, ...
                args.rho);

            obj.nGenerations   = args.nGenerations;
            obj.nIndividuals   = args.nIndividuals;
            obj.nAtomsPerBlock = args.nAtomsPerBlock(:)';
            obj.nBlocks        = numel(obj.nAtomsPerBlock);
            obj.rho            = args.rho;

            obj.Agenda = cell(obj.nGenerations, obj.nIndividuals);

            obj.buildAgenda();
        end

        function T = getTargets(obj, g, i)

            T = obj.Agenda{g, i};

        end

        function k = getTargetCount(obj, g, i)

            k = size(obj.Agenda{g, i}, 1);

        end

        function next = iterator(obj, g, i)
        % iterator
        %
        % Return a consumable iterator over mutation targets for (g,i).
        %
        % Purpose
        %   Provide a sequential, block-grouped traversal of the agenda 
        %   slice without exposing representation details.
        %
        % Behavior
        %   Each call yields the next contiguous block run:
        %       (blockIndex, atomIndices)
        %
        %   The iterator is consumable:
        %       - internal state advances on each call,
        %       - a new iterator must be requested for a new traversal.
        %
        % Output
        %   next : function handle
        %       Callable as:
        %           [hasNext, b, atoms] = next()
        %
        %       where:
        %           hasNext : logical
        %               true if a block run is available
        %           b : double
        %               block index
        %           atoms : column vector
        %               atom indices within block b
        %
        % Notes
        %   - Safe on empty targets: first call returns hasNext = false.
        %   - Block runs follow construction order (grouped by block).
        %   - No allocation beyond the returned function handle.
        %
        % Example
        %   next = agenda.iterator(g, i);
        %
        %   while true
        %       [ok, b, atoms] = next();
        %       if ~ok
        %           break
        %       end
        %
        %       mutateFcns{b}(blocks{b}, i, atoms);
        %   end
        %
        % See also
        %   getTargets

            T = obj.Agenda{g, i};
            p = 1;
            n = size(T, 1);

            next = @step;

            function [hasNext, blockIndex, atomIndices] = step()

                if p > n
                    hasNext = false;
                    blockIndex = [];
                    atomIndices = [];
                    return
                end

                blockIndex = T(p, 1);
                q = p + 1;

                while q <= n && T(q, 1) == blockIndex
                    q = q + 1;
                end

                atomIndices = T(p:q - 1, 2);

                p = q;
                hasNext = true;

            end

        end

    end

    methods (Access = private)

        function buildAgenda(obj)

            G = obj.nGenerations;
            P = obj.nIndividuals;
            K = obj.nBlocks;

            for b = 1:K

                n = obj.nAtomsPerBlock(b);
                Mb = binornd(n, obj.rho, G, P);

                for g = 1:G
                    for i = 1:P

                        m = Mb(g, i);

                        if m == 0
                            continue
                        end

                        atoms = randperm(n, m);

                        obj.Agenda{g, i} = [ ...
                            obj.Agenda{g, i}; ...
                            [b * ones(m, 1), atoms(:)]];

                    end
                end
            end

        end

    end

end