classdef DevelopmentalExpressionModel < handle
% DevelopmentalExpressionModel
%
% Block level phenotype parameter expression model.
%
% A DevelopmentalExpressionModel (DEM) defines a deterministic, vectorized,
% and non normative mapping from a MetagenomeBlock instance to a single
% phenotype parameter value.
%
% Design principles:
%   - Stateless handle object used only for identity, traceability, and
%     stable API exposure.
%   - All expressive behavior is injected via a function handle (closure
%     style decoder); no behavior is implemented via inheritance.
%   - Structural and wiring safety only; semantic validity is delegated to
%     dedicated validators outside the DEM.
%
% Contract:
%   - Each DEM instance is bound to exactly one MetagenomeBlock subclass.
%   - The DEM is bound to exactly one phenotype parameter spec.
%   - Expression operates on the full block (all individuals at once).
%   - The decoding function is assumed deterministic and vectorized.
%
% Error handling:
%   - Type and structural checks are delegated to MetagenomeValidator.
%   - Decode failures propagate natively; contract violations are reported
%     by validators.

    properties (SetAccess = private)
        name (1,1) string
        blockClassMeta (1,1) matlab.metadata.Class
        decodeFcn (1,1) function_handle
        spec (1,1) struct
    end

    methods (Access = private)

        function obj = DevelopmentalExpressionModel(args)
            arguments
                args.name (1,1) string
                args.blockClassMeta (1,1) matlab.metadata.Class
                args.decodeFcn (1,1) function_handle
                args.spec (1,1) struct
            end

            obj.name = args.name;
            obj.blockClassMeta = args.blockClassMeta;
            obj.decodeFcn = args.decodeFcn;
            obj.spec = args.spec;
        end

    end

    methods (Static)

        function obj = create(args)
            arguments
                args.name (1,1) string
                args.blockClassMeta (1,1) matlab.metadata.Class
                args.decodeFcn (1,1) function_handle
                args.descriptor (1,1) ...
                    epistemic.tools.evolutionary.phenotype. ...
                    PhenotypeParameterDescriptor
            end

            import epistemic.tools.evolutionary.internal.MetagenomeValidator

            context = "DEM '" + args.name + "'";

            MetagenomeValidator.mustBeMetagenomeBlockSubclassMeta( ...
                args.blockClassMeta, context);

            spec = args.descriptor.getParamByName(args.name);

            obj = DevelopmentalExpressionModel( ...
                name=args.name, ...
                blockClassMeta=args.blockClassMeta, ...
                decodeFcn=args.decodeFcn, ...
                spec=spec);
        end

    end

    methods

        function value = express(obj, block)
            import epistemic.tools.evolutionary.internal.MetagenomeValidator
            import epistemic.tools.evolutionary.internal. ...
                PhenotypeParameterValidator

            MetagenomeValidator.mustAllBeBlocks( ...
                {block}, string(obj.blockClassMeta.Name));

            value = obj.decodeFcn(block, obj.spec);

            PhenotypeParameterValidator.mustBeValidValue( ...
                obj.spec, value, block.nIndividuals);
        end

        function s = toString(obj)
            paramName = "";
            if isfield(obj.spec, "name")
                paramName = string(obj.spec.name);
            end

            s = sprintf( ...
                "dem{name='%s', param='%s', blockClass='%s', " + ...
                "decodeFcn='%s'}", ...
                obj.name, paramName, obj.blockClassMeta.Name, ...
                func2str(obj.decodeFcn));
        end

    end

end