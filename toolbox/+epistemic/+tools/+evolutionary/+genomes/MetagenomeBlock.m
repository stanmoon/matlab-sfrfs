classdef (Abstract) MetagenomeBlock < handle
% MetagenomeBlock
% Structural carrier for homogeneous population genotypes.
%
% Rows correspond to individuals, columns to atomic genotype elements.
% Population size and genome length are derived from the backing matrix.

    properties (Access = protected)
        % matrix
        % Packed storage of genotypes (rows = individuals).
        matrix
    end

    properties (Dependent, SetAccess = private)
        % nIndividuals
        % Number of individuals (rows).
        nIndividuals (1,1) double

        % nAtoms
        % Number of atomic genotype elements per individual (columns).
        nAtoms (1,1) double
    end

    methods (Access = protected)
        function obj = MetagenomeBlock(args)
            arguments
                args.matrix (:,:)
            end
            obj.matrix = args.matrix;
        end

        function setMatrix(obj, G)
            arguments
                obj
                G (:,:)
            end
            obj.matrix = G;
        end
    end

    methods
        function n = get.nIndividuals(obj)
            n = size(obj.matrix, 1);
        end

        function n = get.nAtoms(obj)
            n = size(obj.matrix, 2);
        end

        function G = asMatrix(obj)
            % asMatrix
            % Return a copy of the backing genotype matrix.
            G = obj.matrix;
        end
    end

    methods (Static, Access = protected)

        function assertMutuallyExclusive(nameA, a, nameB, b)
            import epistemic.tools.evolutionary.internal.MetagenomeValidator

            MetagenomeValidator.mustBeMutuallyExclusive( ...
                string(nameA), a, string(nameB), b);
        end

        function assertLogicalScalar(name, x)
            import epistemic.tools.evolutionary.internal.ValidationUtils

            meta = ?epistemic.tools.evolutionary.genomes.MetagenomeBlock;

            ValidationUtils.mustBeLogicalScalar( ...
                x, meta, "BadArg", string(name));
        end

        function assertIntegerScalar(name, x)
            import epistemic.tools.evolutionary.internal.ValidationUtils

            meta = ?epistemic.tools.evolutionary.genomes.MetagenomeBlock;

            ValidationUtils.mustBeIntegerScalar( ...
                x, meta, "BadArg", string(name));
        end

        function assertInRange(name, x, lo, hi)
            import epistemic.tools.evolutionary.internal.ValidationUtils

            meta = ?epistemic.tools.evolutionary.genomes.MetagenomeBlock;

            ValidationUtils.mustBeInRange( ...
                x, lo, hi, meta, "BadArg", string(name));
        end

        function assertIntegerMatrix(name, G)
            import epistemic.tools.evolutionary.internal.ValidationUtils

            meta = ?epistemic.tools.evolutionary.genomes.MetagenomeBlock;

            ValidationUtils.mustBeIntegerMatrix( ...
                G, meta, "BadArg", string(name));
        end

        function assertSize(name, G, nRows, nCols)
            import epistemic.tools.evolutionary.internal.ValidationUtils

            meta = ?epistemic.tools.evolutionary.genomes.MetagenomeBlock;

            ValidationUtils.mustHaveSize( ...
                G, nRows, nCols, meta, "BadArg", string(name));
        end

        function assertLogicalMatrix(name, G)
            import epistemic.tools.evolutionary.internal.ValidationUtils
        
            meta = ?epistemic.tools.evolutionary.genomes.MetagenomeBlock;
        
            ValidationUtils.mustBeLogicalMatrix( ...
                G, meta, "BadArg", string(name));
        end

    end
end
