classdef MetagenomeValidator
% MetagenomeValidator
% Internal, stateless validation utilities for Metagenome invariants.
%
% Design
%   - Static, stateless validators.
%   - Single error funnel via helpers.Errors.raise (polymorphic).
%   - Validators do not assemble error identifiers.
%   - No reflection, no imports, no arguments blocks.

    methods (Static)

        function mustBeNonEmptyBlocks(blocks)
            if ~iscell(blocks) || isempty(blocks)
                helpers.Errors.raise( ...
                    'suffix', "EmptyBlocks", ...
                    'message', "At least one block is required.");
            end
        end

        function mustAllBeBlocks(blocks, blockClassName)
            if ~iscell(blocks)
                helpers.Errors.raise( ...
                    'suffix', "BadBlocks", ...
                    'message', "blocks must be a cell.");
            end

            if ~(isstring(blockClassName) && isscalar(blockClassName))
                helpers.Errors.raise( ...
                    'suffix', "BadArg", ...
                    'message', "blockClassName must be a string.");
            end

            cls = char(blockClassName);
            for k = 1:numel(blocks)
                if ~isa(blocks{k}, cls)
                    helpers.Errors.raise( ...
                        'suffix', "InvalidBlock", ...
                        'format', "Expected %s.", ...
                        'args', {string(cls)});
                end
            end
        end

        function mustShareNIndividuals(blocks)
            if ~iscell(blocks)
                helpers.Errors.raise( ...
                    'suffix', "BadBlocks", ...
                    'message', "blocks must be a cell.");
            end

            if isempty(blocks)
                return
            end

            ref = MetagenomeValidator.getNIndividuals_(blocks{1});

            for k = 2:numel(blocks)
                v = MetagenomeValidator.getNIndividuals_(blocks{k});
                if ~isequal(v, ref)
                    helpers.Errors.raise( ...
                        'suffix', "RowMismatch", ...
                        'message', ...
                        "All blocks must share the same nIndividuals.");
                end
            end
        end

        function mustMatchNIndividuals(block, n)
            if ~(isnumeric(n) && isreal(n) && isscalar(n))
                helpers.Errors.raise( ...
                    'suffix', "BadArg", ...
                    'format', "%s must be a real numeric scalar.", ...
                    'args', {"nIndividuals"});
            end

            if ~isfinite(n) || n < 0 || n ~= floor(n)
                helpers.Errors.raise( ...
                    'suffix', "BadArg", ...
                    'format', "%s must be a nonnegative integer.", ...
                    'args', {"nIndividuals"});
            end

            v = MetagenomeValidator.getNIndividuals_(block);

            if v ~= n
                helpers.Errors.raise( ...
                    'suffix', "RowMismatch", ...
                    'message', ...
                    "All blocks must share the same nIndividuals.");
            end
        end

        function mustBeIntegerScalarIndex(k, nMax)
            v = epistemic.tools.evolutionary.internal.ValidationUtils;

            v.mustBeIntegerScalar( ...
                k, "BadIndex", ...
                "Block index must be an integer scalar.");

            v.mustBeInRange( ...
                k, 1, nMax, "IndexOutOfRange", ...
                "Block index out of range.");
        end

        function mustBeMutuallyExclusive(nameA, valA, nameB, valB)
            meta = ?epistemic.tools.evolutionary.internal. ...
                MetagenomeValidator;
    
            hasA = ~isempty(valA);
            hasB = ~isempty(valB);
    
            if hasA && hasB
                helpers.Errors.raise( ...
                    'classMeta', meta, ...
                    'suffix', "AmbiguousInit", ...
                    'format', ...
                    "Arguments '%s' and '%s' are mutually exclusive.", ...
                    'args', {nameA, nameB});
            end
        end

        function mustBeMetagenomeBlockSubclassMeta(...
                blockClassMeta, contextName)

            meta = ?epistemic.tools.evolutionary.internal. ...
                MetagenomeValidator;
        
            if ~isa(blockClassMeta, 'matlab.metadata.Class')
                helpers.Errors.raise( ...
                    'classMeta', meta, ...
                    'suffix', "BadArg", ...
                    'format', "%s must be a matlab.metadata.Class.", ...
                    'args', {"blockClassMeta"});
            end
        
            if ~(isstring(contextName) && isscalar(contextName))
                helpers.Errors.raise( ...
                    'classMeta', meta, ...
                    'suffix', "BadArg", ...
                    'format', "%s must be a string scalar.", ...
                    'args', {"contextName"});
            end
        
            base = "epistemic.tools.evolutionary.genomes.MetagenomeBlock";
        
            if blockClassMeta.Name == base
                return
            end
        
            if ~matlab.lang.isSubclass(blockClassMeta.Name, base)
                helpers.Errors.raise( ...
                    'classMeta', meta, ...
                    'suffix', "BadBlockSubclass", ...
                    'format', ...
                    "%s requires a subclass of '%s', got '%s'.", ...
                    'args', {contextName, base, blockClassMeta.Name});
            end
        end
    end

    methods (Static, Access = private)

        function n = getNIndividuals_(block)
            try
                n = block.nIndividuals;
            catch
                helpers.Errors.raise( ...
                    'suffix', "MissingProperty", ...
                    'format', "Missing property: %s.", ...
                    'args', {"nIndividuals"});
            end

            if ~(isnumeric(n) && isreal(n) && isscalar(n) && isfinite(n))
                helpers.Errors.raise( ...
                    'suffix', "BadProperty", ...
                    'format', ...
                    "Property %s must be a finite numeric scalar.", ...
                    'args', {"nIndividuals"});
            end
        end

    end
end
