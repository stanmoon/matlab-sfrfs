classdef RealMutators
% RealMutators
% Real-valued mutation via bounded increment laws.

    methods (Static)

        function mutateFcn = infer(args)
        % infer  Return mutateFcn(block,i,idx)
        %
        %   block : RealMetagenomeBlock
        %   i     : individual of the population (row index)
        %   idx   : atom positions (column indices)
        %
        %   The returned function applies bounded real-valued mutation
        %   using a PowerLaw increment law configured from EngineConfig.

            arguments
                args.config (1,1) ...
                    epistemic.tools.evolutionary.EngineConfig
            end

            cfg = args.config;

            alpha = cfg.getConfig(cfg.POWER_LAW_ALPHA);
            rMin = cfg.getConfig(cfg.POWER_LAW_RMIN);

            mutateFcn = @(block, i, idx) ...
                epistemic.tools.evolutionary. ...
                operators.mutation.RealMutators.mutate( ...
                    block, i, idx, alpha, rMin);

        end

        function mutate(block, i, idx, alpha, rMin)
        % mutate  Apply bounded real-valued mutation.
        %
        %   block : RealMetagenomeBlock
        %   i     : individual of the population (row index)
        %   idx   : atom positions (column indices)
        %   alpha : power-law exponent
        %   rMin  : minimal increment magnitude
        %
        %   Reads the current atom values, samples bounded increments from
        %   a PowerLaw law induced by the block domain, and writes back the
        %   mutated values.

            law = epistemic.tools.evolutionary. ...
                operators.mutation.PowerLaw( ...
                lo = block.lo, ...
                hi = block.hi, ...
                alpha = alpha, ...
                rMin = rMin);

            x = block.getAtoms( ...
                individualIndex = i, ...
                atomIndices = idx);

            delta = law.sample(x);

            block.setAtoms( ...
                individualIndex = i, ...
                atomIndices = idx, ...
                values = x + delta);

        end

    end

end