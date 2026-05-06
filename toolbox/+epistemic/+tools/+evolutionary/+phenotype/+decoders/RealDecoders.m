classdef RealDecoders
% RealDecoders
%
% Decoder inference for PhenotypeParameterKind.Real.
%
% Decoder scope:
%   - Structural consistency with the genome representation.
%   - Semantic validity is validated by DEM
%     (PhenotypeParameterValidator).

    methods (Static)

        function decodeFcn = infer(args)
            arguments
                args.sourceBlockType (1,1) string
            end

            switch args.sourceBlockType
                case "bool"
                    decodeFcn = @(block, spec) ...
                        RealDecoders.fromBool(block, spec);

                case "int"
                    decodeFcn = @(block, spec) ...
                        RealDecoders.fromInt(block, spec);

                case "real"
                    decodeFcn = @(block, spec) ...
                        RealDecoders.fromReal(block, spec);

                case "complex"
                    decodeFcn = @(block, spec) ...
                        RealDecoders.fromComplex(block, spec);

                otherwise
                    helpers.Errors.raise( ...
                        classMeta=?epistemic.tools.evolutionary. ...
                            phenotype.decoders.RealDecoders, ...
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
                RealDecoders;
        
            DecoderValidator.mustHaveAtomCountForShape( ...
                classMeta, block, spec.shape);
        
            DecoderValidator.mustHaveNondegenerateDomainBounds( ...
                classMeta, spec);
        
            lo = spec.domain.lo;
            hi = spec.domain.hi;
        
            X = double(block.asMatrix());
        
            value = epistemic.tools.evolutionary.internal. ...
                DecoderTransforms.wrapToInterval(X, lo, hi);
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
                RealDecoders;
        
            DecoderValidator.mustHaveNondegenerateDomainBounds( ...
                classMeta, spec);
        
            DecoderValidator.mustHaveBitsForShape( ...
                classMeta, block, spec.shape);
        
            p = prod(spec.shape);
            nBits = block.nAtoms / p;
        
            lo = spec.domain.lo;
            hi = spec.domain.hi;
        
            codes = epistemic.tools.evolutionary.internal. ...
                DecoderTransforms.decodeBinaryCodesRowwise( ...
                block.asMatrix(), p, nBits);
        
            denom = 2^nBits - 1;
        
            value = lo + (hi - lo) .* (codes ./ denom);
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
                RealDecoders;
        
            DecoderValidator.mustHaveAtomCountForShape( ...
                classMeta, block, spec.shape);
        
            DecoderValidator.mustHaveNondegenerateDomainBounds( ...
                classMeta, spec);
        
            lo = spec.domain.lo;
            hi = spec.domain.hi;
        
            X = double(block.asMatrix());
        
            value = epistemic.tools.evolutionary.internal. ...
                DecoderTransforms.wrapToInterval(X, lo, hi);
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
                RealDecoders;
        
            DecoderValidator.mustHaveAtomCountForShape( ...
                classMeta, block, spec.shape);
        
            DecoderValidator.mustHaveNondegenerateDomainBounds( ...
                classMeta, spec);
        
            lo = spec.domain.lo;
            hi = spec.domain.hi;
        
            X = abs(block.asMatrix());
        
            value = epistemic.tools.evolutionary.internal. ...
                DecoderTransforms.wrapToInterval(X, lo, hi);
        end

    end

end