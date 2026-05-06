classdef IntMutators
% IntMutators
% Integer-valued mutation using a bounded power-law on the integer lattice.
%
% Mutation is performed by sampling increments from IntegerPowerLaw, which
% wraps a continuous power-law law and projects increments via rounding.
% This guarantees:
%   - integer-valued steps,
%   - domain compliance [lo, hi],
%   - heavy-tailed exploration controlled by alpha.
%
% The mutator operates on selected atoms of a metagenome block and updates
% them in place.

    methods (Static)

        function mutateFcn = infer(args)
            arguments
                args.config (1,1) ...
                    epistemic.tools.evolutionary.EngineConfig
            end
        
            mutateFcn = @(block, i, idx) ...
                epistemic.tools.evolutionary. ...
                operators.mutation.IntMutators.apply( ...
                block, i, idx, args.config);
        end

        function apply(block, i, idx, config)
        % apply  Apply integer mutation

            x = block.getAtoms( ...
                individualIndex = i, ...
                atomIndices = idx);

            alpha = config.getConfig( ...
                config.POWER_LAW_ALPHA);

            law = epistemic.tools.evolutionary. ...
                operators.mutation.IntegerPowerLaw( ...
                lo = block.lo, ...
                hi = block.hi, ...
                alpha = alpha);

            delta = law.sample(x);
            xNew = x + delta;

            block.setAtoms( ...
                individualIndex = i, ...
                atomIndices = idx, ...
                values = xNew);
        end

    end

end