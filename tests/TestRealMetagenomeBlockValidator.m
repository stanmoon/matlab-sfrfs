classdef TestRealMetagenomeBlockValidator < matlab.unittest.TestCase
% TestRealMetagenomeBlockValidator
% Unit tests for RealMetagenomeBlockValidator.

    properties (Constant, Access = private)
        FQCN = ...
            "epistemic.tools.evolutionary.internal." + ...
            "RealMetagenomeBlockValidator";
        Leaf = "RealMetagenomeBlockValidator";
    end

    methods (Test)

        function testValidateConstructorInputsHappy(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            v.validateConstructorInputs( ...
                meta, 2, 3, -1.5, 2.25, []);
        end

        function testValidateConstructorInputsHappyWithExplicitValue( ...
                testCase)

            v = testCase.validator_();
            meta = testCase.meta_();

            G = [-1.2 0.0 2.25; 1.0 -0.5 0.75];

            v.validateConstructorInputs( ...
                meta, 2, 3, -1.5, 2.25, G);
        end

        function testBadNIndividuals(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f = @() v.validateConstructorInputs( ...
                meta, 0, 3, -1, 1, []);

            testCase.verifyError(f, testCase.id_("BadNIndividuals"));
        end

        function testBadNAtoms(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f = @() v.validateConstructorInputs( ...
                meta, 2, 0, -1, 1, []);

            testCase.verifyError(f, testCase.id_("BadNAtoms"));
        end

        function testBadLo(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f = @() v.validateConstructorInputs( ...
                meta, 2, 3, NaN, 1, []);

            testCase.verifyError(f, testCase.id_("BadArg"));
        end

        function testBadHi(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f = @() v.validateConstructorInputs( ...
                meta, 2, 3, -1, NaN, []);

            testCase.verifyError(f, testCase.id_("BadArg"));
        end

        function testBadRange(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f = @() v.validateConstructorInputs( ...
                meta, 2, 3, 2, 1, []);

            testCase.verifyError(f, testCase.id_("BadRange"));
        end

        function testValidateDomainHappy(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            v.validateDomain(meta, -1.5, 2.25);
        end

        function testValidateExplicitValueHappy(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            G = [-1.2 0.0 2.25; 1.0 -0.5 0.75];

            v.validateExplicitValue( ...
                meta, G, 2, 3, -1.5, 2.25);
        end

        function testValidateExplicitValueRejectsNonFinite(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f = @() v.validateExplicitValue( ...
                meta, [1 NaN], 1, 2, -1, 2);

            testCase.verifyError(f, testCase.id_("BadArg"));
        end

        function testValidateExplicitValueRejectsComplex(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f = @() v.validateExplicitValue( ...
                meta, [1 + 1i, 2], 1, 2, -1, 2);

            testCase.verifyError(f, testCase.id_("BadArg"));
        end

        function testValidateExplicitValueRejectsSizeMismatch(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f = @() v.validateExplicitValue( ...
                meta, zeros(2, 2), 2, 3, -1, 1);

            testCase.verifyError(f, testCase.id_("BadArg"));
        end

        function testValidateExplicitValueRejectsBelowDomain(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            G = [-1.1 0.0; 0.2 0.3];

            f = @() v.validateExplicitValue( ...
                meta, G, 2, 2, -1.0, 1.0);

            testCase.verifyError(f, testCase.id_("BadArg"));
        end

        function testValidateExplicitValueRejectsAboveDomain(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            G = [0.0 0.1; 0.2 1.1];

            f = @() v.validateExplicitValue( ...
                meta, G, 2, 2, -1.0, 1.0);

            testCase.verifyError(f, testCase.id_("BadArg"));
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

            v.mustBeValidAtomUpdate(meta, obj, 1, [2; 4], 0.25);
        end

        function testMustBeValidAtomUpdateHappyVector(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();
            obj = testCase.block_();

            v.mustBeValidAtomUpdate( ...
                meta, obj, 2, [1; 3; 5], [-0.1 0.0 0.8]);
        end

        function testMustBeValidAtomUpdateRejectsNonFiniteValues( ...
                testCase)

            v = testCase.validator_();
            meta = testCase.meta_();
            obj = testCase.block_();

            f = @() v.mustBeValidAtomUpdate( ...
                meta, obj, 1, [1; 2], [0.0 NaN]);

            testCase.verifyError(f, testCase.id_("BadArg"));
        end

        function testMustBeValidAtomUpdateRejectsComplexValues( ...
                testCase)

            v = testCase.validator_();
            meta = testCase.meta_();
            obj = testCase.block_();

            f = @() v.mustBeValidAtomUpdate( ...
                meta, obj, 1, [1; 2], [1 + 1i, 0]);

            testCase.verifyError(f, testCase.id_("BadArg"));
        end

        function testMustBeValidAtomUpdateRejectsLengthMismatch( ...
                testCase)

            v = testCase.validator_();
            meta = testCase.meta_();
            obj = testCase.block_();

            f = @() v.mustBeValidAtomUpdate( ...
                meta, obj, 1, [1; 2; 3], [0.1 0.2]);

            testCase.verifyError(f, testCase.id_("BadArg"));
        end

        function testMustBeValidAtomUpdateRejectsBelowDomain( ...
                testCase)

            v = testCase.validator_();
            meta = testCase.meta_();
            obj = testCase.block_();

            f = @() v.mustBeValidAtomUpdate( ...
                meta, obj, 1, [1; 2], [-1.1 0.0]);

            testCase.verifyError(f, testCase.id_("BadArg"));
        end

        function testMustBeValidAtomUpdateRejectsAboveDomain( ...
                testCase)

            v = testCase.validator_();
            meta = testCase.meta_();
            obj = testCase.block_();

            f = @() v.mustBeValidAtomUpdate( ...
                meta, obj, 1, [1; 2], [0.0 1.1]);

            testCase.verifyError(f, testCase.id_("BadArg"));
        end

    end

    methods (Access = private)

        function v = validator_(testCase)
            if testCase.FQCN == ...
                    "epistemic.tools.evolutionary.internal." + ...
                    "RealMetagenomeBlockValidator"

                v = epistemic.tools.evolutionary.internal. ...
                    RealMetagenomeBlockValidator;
                return
            end

            error("TestRealMetagenomeBlockValidator:BadFQCN", ...
                "Update FQCN and validator_().");
        end

        function meta = meta_(testCase)
            if testCase.FQCN == ...
                    "epistemic.tools.evolutionary.internal." + ...
                    "RealMetagenomeBlockValidator"

                meta = ?epistemic.tools.evolutionary.internal. ...
                    RealMetagenomeBlockValidator;
                return
            end

            error("TestRealMetagenomeBlockValidator:BadFQCN", ...
                "Update FQCN and meta_().");
        end

        function obj = block_(~)
            obj = epistemic.tools.evolutionary.genomes. ...
                RealMetagenomeBlock( ...
                nIndividuals = 3, ...
                nAtoms = 5, ...
                lo = -1.0, ...
                hi = 1.0, ...
                value = zeros(3, 5));
        end

        function id = id_(testCase, suffix)
            id = "sfrfs:" + testCase.Leaf + ":" + string(suffix);
            id = char(id);
        end

    end

end