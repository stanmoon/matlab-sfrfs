classdef PhenotypeParametersDescriptor < handle
% PhenotypeParametersDescriptor
%
% Collection of phenotype parameter specifications.
%
% This class stores a sequence of scalar spec structs following
% PhenotypeParameterSchema. Users add parameters via addParam using
% Name=Value arguments. Encoding concerns are out of scope.
%
% Contract:
%   - Parameter names are unique.
%   - Insertion order defines the canonical parameter order.
%   - Name-to-index resolution is supported.
%
% Error behavior:
%   - All input validation uses the internal error funnel
%     (helpers.Errors.raise), via ValidationUtils and
%     PhenotypeParametersDescriptorValidator.

    properties (Access = private)
        Specs (1,:) struct
        NameToIndex containers.Map
    end

    methods
        function obj = PhenotypeParametersDescriptor()
            import epistemic.tools.evolutionary.phenotype.structs.PhenotypeParameterSchema

            obj.Specs = struct( ...
                PhenotypeParameterSchema.NAME,   cell(1, 0), ...
                PhenotypeParameterSchema.KIND,   cell(1, 0), ...
                PhenotypeParameterSchema.DOMAIN, cell(1, 0), ...
                PhenotypeParameterSchema.SHAPE,  cell(1, 0));

            obj.NameToIndex = containers.Map( ...
                'KeyType', 'char', ...
                'ValueType', 'double');
        end

        function obj = addParam(obj, args)
            arguments
                obj
                args.name = ""          % validate in validator
                args.kind = []          % validate in validator
                args.shape = [1 1]
                args.lo = NaN
                args.hi = NaN
                args.values = []        % validate in validator
                args.n = NaN
                args.options = struct()
            end
        
            import epistemic.tools.evolutionary.phenotype.structs.PhenotypeParameterSchema
        
            descMeta = epistemic.tools.evolutionary.phenotype. ...
                PhenotypeParametersDescriptor.classMeta_();
        
            nameKey = char(args.name);
            nameExists = isKey(obj.NameToIndex, nameKey);
        
            epistemic.tools.evolutionary.internal. ...
                PhenotypeParametersDescriptorValidator. ...
                mustBeValidAddParamArgs(descMeta, args, nameExists);
        
            domain = epistemic.tools.evolutionary.internal. ...
                PhenotypeParametersDescriptorValidator. ...
                buildDomain(descMeta, args);
        
            spec = struct();
            spec.(PhenotypeParameterSchema.NAME)   = args.name;
            spec.(PhenotypeParameterSchema.KIND)   = args.kind;
            spec.(PhenotypeParameterSchema.DOMAIN) = domain;
            spec.(PhenotypeParameterSchema.SHAPE)  = args.shape;
        
            obj.Specs(end + 1) = spec;
            obj.NameToIndex(nameKey) = numel(obj.Specs);
        end

        function n = nParams(obj)
            n = numel(obj.Specs);
        end

        function tf = hasParam(obj, name)
            descMeta = epistemic.tools.evolutionary.phenotype. ...
                PhenotypeParametersDescriptor.classMeta_();

            epistemic.tools.evolutionary.internal. ...
                ValidationUtils.mustBeNonEmptyStringScalar( ...
                    name, descMeta, "BadName", ...
                    "name must be a non-empty string scalar.");

            tf = isKey(obj.NameToIndex, char(name));
        end

        function idx = indexOf(obj, name)
            descMeta = epistemic.tools.evolutionary.phenotype. ...
                PhenotypeParametersDescriptor.classMeta_();

            epistemic.tools.evolutionary.internal. ...
                PhenotypeParametersDescriptorValidator. ...
                mustHaveParamName(descMeta, obj.NameToIndex, name);

            idx = obj.NameToIndex(char(name));
        end

        function spec = getParam(obj, idx)
            descMeta = epistemic.tools.evolutionary.phenotype. ...
                PhenotypeParametersDescriptor.classMeta_();

            epistemic.tools.evolutionary.internal. ...
                ValidationUtils.mustBeIndexInRange( ...
                    idx, numel(obj.Specs), descMeta, "BadIndex");

            spec = obj.Specs(idx);
        end

        function spec = getParamByName(obj, name)
            spec = obj.getParam(obj.indexOf(name));
        end

        function specs = toArray(obj)
            specs = obj.Specs;
        end

        function names = names(obj)
            import epistemic.tools.evolutionary.phenotype.structs.PhenotypeParameterSchema

            if isempty(obj.Specs)
                names = string.empty(1, 0);
                return
            end

            names = [obj.Specs.(PhenotypeParameterSchema.NAME)];
        end
    end

    methods (Static, Access = private)
        function meta = classMeta_()
            meta = ?epistemic.tools.evolutionary.phenotype. ...
                PhenotypeParametersDescriptor;
        end
    end
end
