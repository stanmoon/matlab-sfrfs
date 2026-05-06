classdef IntegerMetagenomeBlockValidator
% IntegerMetagenomeBlockValidator
%
% Structural validation helpers for IntegerMetagenomeBlock.
%
% Scope
%   - Constructor admission control
%   - Domain validation for [lo, hi]
%   - Explicit value validation
%   - Row-local atom index validation
%   - Row-local atom update validation

    methods (Static)

        function validateConstructorInputs( ...
                classMeta, nIndividuals, nAtoms, lo, hi, value)

            arguments
                classMeta (1,1) meta.class
                nIndividuals (1,1) double
                nAtoms (1,1) double
                lo (1,1) double
                hi (1,1) double
                value = []
            end

            V = epistemic.tools.evolutionary.internal.ValidationUtils;

            V.mustBePositiveIntegerScalar( ...
                nIndividuals, classMeta, ...
                "BadNIndividuals", ...
                "nIndividuals must be a positive integer scalar.");

            V.mustBePositiveIntegerScalar( ...
                nAtoms, classMeta, ...
                "BadNAtoms", ...
                "nAtoms must be a positive integer scalar.");

            epistemic.tools.evolutionary.internal. ...
                IntegerMetagenomeBlockValidator.validateDomain( ...
                classMeta, lo, hi);

            if isempty(value)
                return
            end

            epistemic.tools.evolutionary.internal. ...
                IntegerMetagenomeBlockValidator.validateExplicitValue( ...
                classMeta, value, nIndividuals, nAtoms, lo, hi);
        end

        function validateDomain(classMeta, lo, hi)
            arguments
                classMeta (1,1) meta.class
                lo (1,1) double
                hi (1,1) double
            end

            V = epistemic.tools.evolutionary.internal.ValidationUtils;

            V.mustBeIntegerScalar( ...
                lo, classMeta, "BadArg", "lo");

            V.mustBeIntegerScalar( ...
                hi, classMeta, "BadArg", "hi");

            if lo > hi
                helpers.Errors.raise( ...
                    classMeta=classMeta, ...
                    suffix="BadRange", ...
                    message="Lower bound must be <= upper bound.");
            end
        end

        function validateExplicitValue( ...
                classMeta, value, nIndividuals, nAtoms, lo, hi)

            arguments
                classMeta (1,1) meta.class
                value
                nIndividuals (1,1) double
                nAtoms (1,1) double
                lo (1,1) double
                hi (1,1) double
            end

            V = epistemic.tools.evolutionary.internal.ValidationUtils;

            V.mustBeIntegerMatrix( ...
                value, classMeta, "BadArg", "value");

            V.mustHaveSize( ...
                value, nIndividuals, nAtoms, classMeta, ...
                "BadArg", "value");

            if any(value(:) < lo) || any(value(:) > hi)
                helpers.Errors.raise( ...
                    classMeta=classMeta, ...
                    suffix="ValueOutOfDomain", ...
                    message="value entries must lie within [lo, hi].");
            end
        end

        function mustBeValidAtomIndices( ...
                classMeta, obj, individualIndex, atomIndices)

            arguments
                classMeta (1,1) meta.class
                obj (1,1) ...
                    epistemic.tools.evolutionary.genomes. ...
                    IntegerMetagenomeBlock
                individualIndex (1,1) double
                atomIndices
            end

            if ~isfinite(individualIndex) || ...
                    individualIndex ~= floor(individualIndex) || ...
                    individualIndex < 1 || ...
                    individualIndex > obj.nIndividuals

                helpers.Errors.raise( ...
                    classMeta=classMeta, ...
                    suffix="BadIndex", ...
                    message="individualIndex must be a valid row index.");
            end

            if isempty(atomIndices)
                helpers.Errors.raise( ...
                    classMeta=classMeta, ...
                    suffix="BadIndex", ...
                    message="atomIndices must be nonempty.");
            end

            if ~isnumeric(atomIndices) || ~isreal(atomIndices) || ...
                    ~isvector(atomIndices) || ...
                    any(~isfinite(atomIndices(:))) || ...
                    any(atomIndices(:) ~= floor(atomIndices(:))) || ...
                    any(atomIndices(:) < 1) || ...
                    any(atomIndices(:) > obj.nAtoms)

                helpers.Errors.raise( ...
                    classMeta=classMeta, ...
                    suffix="BadIndex", ...
                    message="atomIndices must be a vector of valid indices.");
            end
        end

        function mustBeValidAtomUpdate( ...
                classMeta, obj, individualIndex, atomIndices, values)

            arguments
                classMeta (1,1) meta.class
                obj (1,1) ...
                    epistemic.tools.evolutionary.genomes. ...
                    IntegerMetagenomeBlock
                individualIndex (1,1) double
                atomIndices
                values
            end

            epistemic.tools.evolutionary.internal. ...
                IntegerMetagenomeBlockValidator.mustBeValidAtomIndices( ...
                classMeta, obj, individualIndex, atomIndices);

            idx = atomIndices(:);
            values = values(:);

            V = epistemic.tools.evolutionary.internal.ValidationUtils;

            V.mustBeIntegerMatrix( ...
                values, classMeta, "BadArg", "values");

            if ~(isscalar(values) || numel(values) == numel(idx))
                helpers.Errors.raise( ...
                    classMeta=classMeta, ...
                    suffix="BadSize", ...
                    message="values must be scalar or match indices.");
            end

            if any(values(:) < obj.lo) || any(values(:) > obj.hi)
                helpers.Errors.raise( ...
                    classMeta=classMeta, ...
                    suffix="ValueOutOfDomain", ...
                    message="Assigned values must lie within [lo, hi].");
            end
        end

    end

end