classdef EnumDecoders
% EnumDecoders
%
% Decoder inference for PhenotypeParameterKind.Enum.
%
% Convention
%   - Decoded parameters are returned flat as [nIndividuals, p], where
%     p = prod(spec.shape).
%   - For block-based encodings, prod(spec.shape) must equal block.nAtoms.

    methods (Static)

        function decodeFcn = infer(args)
            arguments
                args.sourceBlockType (1,1) string
            end

            switch args.sourceBlockType
                case "int"
                    decodeFcn = @(block, spec) ...
                        EnumDecoders.fromInt(block, spec);
                case "real"
                    decodeFcn = @(block, spec) ...
                        EnumDecoders.fromReal(block, spec);
                case "bool"
                    decodeFcn = @(block, spec) ...
                        EnumDecoders.fromBool(block, spec);
                case "perm"
                    decodeFcn = @(block, spec) ...
                        EnumDecoders.fromPerm(block, spec);
                case "complex"
                    decodeFcn = @(block, spec) ...
                        EnumDecoders.fromComplex(block, spec);
                otherwise
                    helpers.Errors.raise( ...
                        classMeta=?epistemic.tools.evolutionary. ...
                            phenotype.decoders.EnumDecoders, ...
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
                EnumDecoders;

            DecoderValidator.mustHaveAtomCountForShape( ...
                classMeta, block, spec.shape);

            DecoderValidator.mustHaveDomainValues(classMeta, spec);

            values = spec.domain.values(:).';
            n = numel(values);

            G = block.asMatrix();
            idx = mod(double(G) - 1, n) + 1;

            value = values(double(idx));
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
                EnumDecoders;

            DecoderValidator.mustHaveAtomCountForShape( ...
                classMeta, block, spec.shape);

            DecoderValidator.mustHaveDomainValues(classMeta, spec);

            values = spec.domain.values;
            n = numel(values);

            G = block.asMatrix();
            idx = mod(round(double(G)) - 1, n) + 1;

            value = values(double(idx));
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
                EnumDecoders;

            DecoderValidator.mustHaveAtomCountForShape( ...
                classMeta, block, spec.shape);

            DecoderValidator.mustHaveAtLeastDomainValues( ...
                classMeta, spec, 2);

            values = spec.domain.values(:).';

            G = block.asMatrix();
            idx = 1 + uint32(logical(G));

            value = values(double(idx));
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
                EnumDecoders;

            DecoderValidator.mustHaveAtomCountForShape( ...
                classMeta, block, spec.shape);

            DecoderValidator.mustHaveDomainValues(classMeta, spec);

            values = spec.domain.values(:).';
            n = numel(values);

            G = block.asMatrix();
            idx = mod(double(G) - 1, n) + 1;

            value = values(double(idx));
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
                EnumDecoders;

            DecoderValidator.mustHaveAtomCountForShape( ...
                classMeta, block, spec.shape);

            DecoderValidator.mustHaveDomainValues(classMeta, spec);

            values = spec.domain.values(:).';
            n = numel(values);

            G = block.asMatrix();
            idx = mod(round(abs(G)) - 1, n) + 1;

            value = values(double(idx));
        end

    end

end