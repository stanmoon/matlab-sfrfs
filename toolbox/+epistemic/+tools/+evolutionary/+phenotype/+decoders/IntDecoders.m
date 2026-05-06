classdef IntDecoders
% IntDecoders
%
% Decoder inference for PhenotypeParameterKind.Int.
%
% Decoder scope:
%   - Structural consistency with the genome representation.
%   - Semantic validity is validated by DEM (PhenotypeParameterValidator).

    methods (Static)

        function decodeFcn = infer(args)
            arguments
                args.sourceBlockType (1,1) string
            end

            switch args.sourceBlockType
                case "bool"
                    decodeFcn = @(block, spec) ...
                        IntDecoders.fromBool(block, spec);

                case "int"
                    decodeFcn = @(block, spec) ...
                        IntDecoders.fromInt(block, spec);

                case "real"
                    decodeFcn = @(block, spec) ...
                        IntDecoders.fromReal(block, spec);

                case "complex"
                    decodeFcn = @(block, spec) ...
                        IntDecoders.fromComplex(block, spec);

                otherwise
                    helpers.Errors.raise( ...
                        classMeta=?epistemic.tools.evolutionary. ...
                            phenotype.decoders.IntDecoders, ...
                        suffix="UnsupportedSourceBlockType", ...
                        format="Unsupported source block type: %s.", ...
                        args={args.sourceBlockType});
            end
        end

        function value = fromInt(block, spec)
            arguments
                block (1,1) epistemic.tools.evolutionary.genomes. ...
                    MetagenomeBlock
                spec (1,1) struct
            end

            import epistemic.tools.evolutionary.internal.DecoderValidator

            classMeta = ...
                ?epistemic.tools.evolutionary.phenotype.decoders. ...
                IntDecoders;

            DecoderValidator.mustHaveAtomCountForShape( ...
                classMeta, block, spec.shape);

            value = double(block.asMatrix());
        end

        function value = fromBool(block, spec)
            arguments
                block (1,1) epistemic.tools.evolutionary.genomes. ...
                    MetagenomeBlock
                spec (1,1) struct
            end

            import epistemic.tools.evolutionary.internal.DecoderValidator

            classMeta = ...
                ?epistemic.tools.evolutionary.phenotype.decoders. ...
                IntDecoders;

            DecoderValidator.mustHaveDomainBounds(classMeta, spec);

            DecoderValidator.mustHaveBitsForShape( ...
                classMeta, block, spec.shape);

            p = prod(spec.shape);
            nBits = block.nAtoms / p;

            lo = spec.domain.lo;
            hi = spec.domain.hi;

            M = hi - lo + 1;

            codes = epistemic.tools.evolutionary.internal. ...
                DecoderTransforms.decodeBinaryCodesRowwise( ...
                block.asMatrix(), p, nBits);

            Y = lo + (M / (2^nBits)) .* codes;

            value = round(Y - 0.5);
        end

        function value = fromReal(block, spec)
            arguments
                block (1,1) epistemic.tools.evolutionary.genomes. ...
                    MetagenomeBlock
                spec (1,1) struct
            end
        
            import epistemic.tools.evolutionary.internal.DecoderValidator
        
            classMeta = ...
                ?epistemic.tools.evolutionary.phenotype.decoders. ...
                IntDecoders;
        
            DecoderValidator.mustHaveAtomCountForShape( ...
                classMeta, block, spec.shape);
        
            DecoderValidator.mustHaveDomainBounds(classMeta, spec);
        
            lo = spec.domain.lo;
            hi = spec.domain.hi;
        
            X = double(block.asMatrix());
        
            Y = epistemic.tools.evolutionary.internal. ...
                DecoderTransforms.wrapToInterval(X, lo, hi + 1);
        
            value = round(Y - 0.5);
        end

        function value = fromComplex(block, spec)
            arguments
                block (1,1) epistemic.tools.evolutionary.genomes. ...
                    MetagenomeBlock
                spec (1,1) struct
            end
        
            import epistemic.tools.evolutionary.internal.DecoderValidator
        
            classMeta = ...
                ?epistemic.tools.evolutionary.phenotype.decoders. ...
                IntDecoders;
        
            DecoderValidator.mustHaveAtomCountForShape( ...
                classMeta, block, spec.shape);
        
            DecoderValidator.mustHaveDomainBounds(classMeta, spec);
        
            lo = spec.domain.lo;
            hi = spec.domain.hi;
        
            X = abs(block.asMatrix());
        
            Y = epistemic.tools.evolutionary.internal. ...
                DecoderTransforms.wrapToInterval(X, lo, hi + 1);
        
            value = round(Y - 0.5);
        end

    end

end