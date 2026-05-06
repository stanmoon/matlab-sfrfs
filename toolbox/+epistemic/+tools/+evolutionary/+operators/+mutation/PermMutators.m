classdef PermMutators
% PermMutators
% Permutation-valued mutation via positional power-law swaps.
%
% Each target atom index selected by the mutation agenda is interpreted as a
% swap anchor in positional space. A swap partner is chosen by sampling a
% bounded integer power-law increment on the index domain [1, nAtoms].
% The resulting swap preserves permutation validity by construction.

    methods (Static)

        function mutateFcn = infer(args)
        % infer  Construct permutation mutation function handle.
        %
        % Returns a function handle of the form
        %   mutateFcn(block, individualIndex, atomIndices),
        % which applies permutation mutation to the specified atoms of a
        % metagenome block using the provided configuration.
        %
        % The configuration supplies the power-law exponent controlling the
        % distribution of swap distances.

            arguments
                args.config (1,1) ...
                    epistemic.tools.evolutionary.EngineConfig
            end

            mutateFcn = @(block, i, idx) ...
                epistemic.tools.evolutionary. ...
                operators.mutation.PermMutators.apply( ...
                block, i, idx, args.config);
        end

        function apply(block, i, idx, config)
        % apply  Apply permutation mutation via power-law-driven swaps.
        %
        % For each target atom index in idx, a swap partner is selected by
        % sampling an integer displacement from a bounded power-law law 
        % over the positional domain [1, nAtoms]. The value at the anchor 
        % position is exchanged with the value at the sampled partner 
        % position.
        %
        % This operation preserves permutation validity and induces
        % heavy-tailed exploration over positional rearrangements, where
        % small local swaps are more frequent and long-range swaps occur
        % with decreasing probability controlled by the exponent alpha.


            alpha = config.getConfig( ...
                config.POWER_LAW_ALPHA);

            law = epistemic.tools.evolutionary. ...
                operators.mutation.IntegerPowerLaw( ...
                lo = 1, ...
                hi = block.nAtoms, ...
                alpha = alpha);

            G = block.asMatrix();
            row = G(i, :);

            for k = 1:numel(idx)
                anchor = idx(k);
                delta = law.sample(anchor);
                partner = anchor + delta;

                tmp = row(anchor);
                row(anchor) = row(partner);
                row(partner) = tmp;
            end

            block.setAtoms( ...
                individualIndex = i, ...
                atomIndices = (1:block.nAtoms)', ...
                values = row);
        end

    end

end