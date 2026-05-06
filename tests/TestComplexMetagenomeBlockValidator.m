classdef TestComplexMetagenomeBlockValidator < matlab.unittest.TestCase
% TestComplexMetagenomeBlockValidator
% Unit tests for ComplexMetagenomeBlockValidator.

    properties (Constant, Access = private)
        FQCN = ...
            "epistemic.tools.evolutionary.internal." + ...
            "ComplexMetagenomeBlockValidator";
        Leaf = "ComplexMetagenomeBlockValidator";
    end

    methods (Test)

        function testValidateConstructorInputsHappy(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            v.validateConstructorInputs( ...
                meta, 2, 3, 0.5, 2.0, []);
        end

        function testValidateConstructorInputsHappyWithExplicitValue( ...
                testCase)

            v = testCase.validator_();
            meta = testCase.meta_();

            G = [ ...
                0.5, 1.0 * exp(1i * pi / 3), ...
                1.5 * exp(-1i * pi / 4); ...
                0.75 * exp(1i * pi / 2), ...
                1.25, ...
                2.0 * exp(-1i * pi / 6)];

            v.validateConstructorInputs( ...
                meta, 2, 3, 0.5, 2.0, G);
        end

        function testBadNIndividuals(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f = @() v.validateConstructorInputs( ...
                meta, 0, 3, 0.5, 2.0, []);

            testCase.verifyError(f, testCase.id_("BadNIndividuals"));
        end

        function testBadNAtoms(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f = @() v.validateConstructorInputs( ...
                meta, 2, 0, 0.5, 2.0, []);

            testCase.verifyError(f, testCase.id_("BadNAtoms"));
        end

        function testBadLo(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f1 = @() v.validateConstructorInputs( ...
                meta, 2, 3, -eps, 2.0, []);
            testCase.verifyError(f1, testCase.id_("BadArg"));

            f2 = @() v.validateConstructorInputs( ...
                meta, 2, 3, NaN, 2.0, []);
            testCase.verifyError(f2, testCase.id_("BadArg"));
        end

        function testBadHi(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f = @() v.validateConstructorInputs( ...
                meta, 2, 3, 0.5, NaN, []);

            testCase.verifyError(f, testCase.id_("BadArg"));
        end

        function testBadRange(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f = @() v.validateConstructorInputs( ...
                meta, 2, 3, 2.0, 1.0, []);

            testCase.verifyError(f, testCase.id_("BadRange"));
        end

        function testValidateDomainHappy(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            v.validateDomain(meta, 0.5, 2.0);
        end

        function testValidateExplicitValueHappy(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            G = [0.5, 1.0 * exp(1i * pi / 3)];

            v.validateExplicitValue(meta, G, 1, 2, 0.5, 1.0);
        end

        function testValidateExplicitValueRejectsNonFinite(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f1 = @() v.validateExplicitValue( ...
                meta, Inf + 1i, 1, 1, 0, 2);
            testCase.verifyError(f1, testCase.id_("BadArg"));

            f2 = @() v.validateExplicitValue( ...
                meta, NaN + 1i, 1, 1, 0, 2);
            testCase.verifyError(f2, testCase.id_("BadArg"));
        end

        function testValidateExplicitValueRejectsSizeMismatch(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            G = [1 + 1i, 2 + 2i];

            f = @() v.validateExplicitValue( ...
                meta, G, 2, 2, 0, 3);

            testCase.verifyError(f, testCase.id_("BadArg"));
        end

        function testValidateExplicitValueRejectsBadModulus(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            G = [0.1, 1.5];

            f = @() v.validateExplicitValue( ...
                meta, G, 1, 2, 0.5, 1.0);

            testCase.verifyError(f, testCase.id_("BadValue"));
        end

        function testMustBeValidAtomIndicesHappy(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();
            obj = testCase.block_();

            v.mustBeValidAtomIndices(meta, obj, 2, [1; 3; 5]);
        end

        function testMustBeValidAtomIndicesRejectsBadIndividualIndex( ...
                testCase)

            v = testCase.validator_();
            meta = testCase.meta_();
            obj = testCase.block_();

            f = @() v.mustBeValidAtomIndices(meta, obj, 0, [1; 3]);

            testCase.verifyError(f, testCase.id_("BadArg"));
        end

        function testMustBeValidAtomIndicesRejectsEmptyAtomIndices( ...
                testCase)

            v = testCase.validator_();
            meta = testCase.meta_();
            obj = testCase.block_();

            f = @() v.mustBeValidAtomIndices(meta, obj, 1, []);

            testCase.verifyError(f, testCase.id_("BadArg"));
        end

        function testMustBeValidAtomIndicesRejectsNonIntegerIndices( ...
                testCase)

            v = testCase.validator_();
            meta = testCase.meta_();
            obj = testCase.block_();

            f = @() v.mustBeValidAtomIndices(meta, obj, 1, [1; 2.5]);

            testCase.verifyError(f, testCase.id_("BadArg"));
        end

        function testMustBeValidAtomIndicesRejectsOutOfRangeIndices( ...
                testCase)

            v = testCase.validator_();
            meta = testCase.meta_();
            obj = testCase.block_();

            f = @() v.mustBeValidAtomIndices(meta, obj, 1, [1; 6]);

            testCase.verifyError(f, testCase.id_("BadArg"));
        end

        function testMustBeValidAtomUpdateHappyScalar(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();
            obj = testCase.block_();

            z = 1.25 * exp(1i * pi / 4);

            v.mustBeValidAtomUpdate(meta, obj, 1, [2; 4], z);
        end

        function testMustBeValidAtomUpdateHappyVector(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();
            obj = testCase.block_();

            values = [ ...
                0.75 * exp(1i * pi / 6), ...
                1.00 * exp(-1i * pi / 3), ...
                1.80 * exp(1i * pi / 2)];

            v.mustBeValidAtomUpdate( ...
                meta, obj, 2, [1; 3; 5], values);
        end

        function testMustBeValidAtomUpdateRejectsNonFiniteValues( ...
                testCase)

            v = testCase.validator_();
            meta = testCase.meta_();
            obj = testCase.block_();

            f = @() v.mustBeValidAtomUpdate( ...
                meta, obj, 1, [1; 2], [1 + 1i, NaN + 0i]);

            testCase.verifyError(f, testCase.id_("BadArg"));
        end

        function testMustBeValidAtomUpdateRejectsLengthMismatch( ...
                testCase)

            v = testCase.validator_();
            meta = testCase.meta_();
            obj = testCase.block_();

            values = [ ...
                0.75 * exp(1i * pi / 6), ...
                1.00 * exp(-1i * pi / 3)];

            f = @() v.mustBeValidAtomUpdate( ...
                meta, obj, 1, [1; 2; 3], values);

            testCase.verifyError(f, testCase.id_("BadArg"));
        end

        function testMustBeValidAtomUpdateRejectsBelowDomain( ...
                testCase)

            v = testCase.validator_();
            meta = testCase.meta_();
            obj = testCase.block_();

            values = [0.25, 1.00 * exp(1i * pi / 4)];

            f = @() v.mustBeValidAtomUpdate( ...
                meta, obj, 1, [1; 2], values);

            testCase.verifyError(f, testCase.id_("BadValue"));
        end

        function testMustBeValidAtomUpdateRejectsAboveDomain( ...
                testCase)

            v = testCase.validator_();
            meta = testCase.meta_();
            obj = testCase.block_();

            values = [1.00 * exp(1i * pi / 4), 2.50];

            f = @() v.mustBeValidAtomUpdate( ...
                meta, obj, 1, [1; 2], values);

            testCase.verifyError(f, testCase.id_("BadValue"));
        end

    end

    methods (Access = private)

        function v = validator_(testCase)
            if testCase.FQCN == ...
                    "epistemic.tools.evolutionary.internal." + ...
                    "ComplexMetagenomeBlockValidator"

                v = epistemic.tools.evolutionary.internal. ...
                    ComplexMetagenomeBlockValidator;
                return
            end

            error("TestComplexMetagenomeBlockValidator:BadFQCN", ...
                "Update FQCN and validator_().");
        end

        function meta = meta_(testCase)
            if testCase.FQCN == ...
                    "epistemic.tools.evolutionary.internal." + ...
                    "ComplexMetagenomeBlockValidator"

                meta = ?epistemic.tools.evolutionary.internal. ...
                    ComplexMetagenomeBlockValidator;
                return
            end

            error("TestComplexMetagenomeBlockValidator:BadFQCN", ...
                "Update FQCN and meta_().");
        end

        function obj = block_(~)
            obj = epistemic.tools.evolutionary.genomes. ...
                ComplexMetagenomeBlock( ...
                nIndividuals = 3, ...
                nAtoms = 5, ...
                lo = 0.5, ...
                hi = 2.0, ...
                value = ones(3, 5));
        end

        function id = id_(testCase, suffix)
            id = "sfrfs:" + testCase.Leaf + ":" + string(suffix);
            id = char(id);
        end

    end

end