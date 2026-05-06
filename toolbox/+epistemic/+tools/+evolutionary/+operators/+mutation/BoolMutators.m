classdef BoolMutators
% BoolMutators
% Boolean mutation via bit-flip.

    methods (Static)

        function mutateFcn = infer()
        % infer  Return mutateFcn(block,i,idx)
        %
        %   block : BooleanMetagenomeBlock
        %   i     : individual of the population (row index)
        %   idx   : atom positions (column indices)
        %
        %   The returned function applies bit-flip mutation.

            mutateFcn = @(block, i, idx) ...
                epistemic.tools.evolutionary. ...
                operators.mutation.BoolMutators.flip( ...
                    block, i, idx);

        end

        function flip(block, i, idx)
        % flip  Apply bit-flip mutation
        %
        %   block : BooleanMetagenomeBlock
        %   i     : individual of the population (row index)
        %   idx   : atom positions (column indices)
        %
        %   Flips the selected atoms of the individual.

            block.flipAtoms( ...
                individualIndex = i, ...
                atomIndices = idx);

        end

    end

end