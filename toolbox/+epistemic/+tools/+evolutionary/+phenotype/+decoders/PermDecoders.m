classdef PermDecoders
% PermDecoders
%
% Decoder inference for PhenotypeParameterKind.Perm.
%
% Decoder scope:
%   - Structural consistency with the genome representation.
%   - Semantic validity is validated by DEM
%     (PhenotypeParameterValidator).
%
% Policy:
%   - Only PermutationMetagenomeBlock is supported.
%   - All other genome types are rejected.

    methods (Static)

        function decodeFcn = infer(args)
            arguments
                args.sourceBlockType (1,1) string
            end

            switch args.sourceBlockType

                case "perm"
                    decodeFcn = @(block, spec) ...
                        PermDecoders.fromPerm(block, spec);

                otherwise
                    helpers.Errors.raise( ...
                        classMeta=?epistemic.tools.evolutionary. ...
                            phenotype.decoders.PermDecoders, ...
                        suffix="UnsupportedSourceBlockType", ...
                        format="Unsupported source block type: %s.", ...
                        args={args.sourceBlockType});
            end
        end


        function value = fromPerm(block, spec)
            arguments
                block (1,1) epistemic.tools.evolutionary.genomes. ...
                    MetagenomeBlock
                spec (1,1) struct
            end
        
            import epistemic.tools.evolutionary.internal.DecoderValidator
        
            classMeta = ...
                ?epistemic.tools.evolutionary.phenotype.decoders. ...
                PermDecoders;
        
            DecoderValidator.mustHavePermutationDomainSize( ...
                classMeta, spec);
        
            DecoderValidator. ...
                mustHavePermutationShapeConsistentWithDomain( ...
                classMeta, spec);
        
            DecoderValidator. ...
                mustHavePermutationBlockConsistentWithDomain( ...
                classMeta, block, spec);
        
            value = block.asMatrix();
        end
    end

end