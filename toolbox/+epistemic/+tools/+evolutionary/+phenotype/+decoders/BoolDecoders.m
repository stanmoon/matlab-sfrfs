classdef BoolDecoders
% BoolDecoders
%
% Decoder inference for PhenotypeParameterKind.Bool.

    methods (Static)

        function decodeFcn = infer(args)
            arguments
                args.sourceBlockType (1,1) string
            end

            switch args.sourceBlockType
                case {"bool", "int", "real"}
                    decodeFcn = @(block, spec) logical(block);

                otherwise
                    helpers.Errors.raise( ...
                        classMeta=?epistemic.tools.evolutionary. ...
                            phenotype.decoders.BoolDecoders, ...
                        suffix="UnsupportedSourceBlockType", ...
                        format="Unsupported source block type: %s.", ...
                        args={args.sourceBlockType});
            end
        end

    end
end