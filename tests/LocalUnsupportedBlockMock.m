classdef LocalUnsupportedBlockMock < ...
        epistemic.tools.evolutionary.genomes.MetagenomeBlock
    % A mock class for unsupported metagenome blocks
    methods
        function obj = LocalUnsupportedBlockMock(args)
            arguments
                args.matrix
            end

            obj@epistemic.tools.evolutionary.genomes.MetagenomeBlock( ...
                matrix = args.matrix);
        end
    end
end