classdef TestPermutationMetagenomeBlockValidator < matlab.unittest.TestCase
% TestPermutationMetagenomeBlockValidator
% Unit tests for PermutationMetagenomeBlockValidator.

    properties (Constant, Access = private)
        FQCN = ...
            "epistemic.tools.evolutionary.internal." + ...
            "PermutationMetagenomeBlockValidator";
        Leaf = "PermutationMetagenomeBlockValidator";
    end

    methods (Test)

        function testValidateConstructorInputsHappy(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            v.validateConstructorInputs( ...
                meta, 2, 3, [], []);
        end

        function testBadNIndividuals(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f = @() v.validateConstructorInputs( ...
                meta, 0, 3, [], []);

            testCase.verifyError(f, testCase.id_("BadNIndividuals"));
        end

        function testBadNAtoms(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f = @() v.validateConstructorInputs( ...
                meta, 2, 0, [], []);

            testCase.verifyError(f, testCase.id_("BadNAtoms"));
        end

        function testAmbiguousInit(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f = @() v.validateConstructorInputs( ...
                meta, 1, 2, [1 2], 2);

            testCase.verifyError(f, testCase.id_("AmbiguousInit"));
        end

        function testValidateExplicitValueHappy(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            V = [1 2 3; 3 1 2];

            v.validateExplicitValue(meta, V, 2, 3);
        end

        function testValidateExplicitValueBadValue(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f = @() v.validateExplicitValue( ...
                meta, [1 1 2], 1, 3);

            testCase.verifyError(f, testCase.id_("BadValue"));
        end

        function testResolveDomainSizeDefaultsToNAtoms(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            nEff = v.resolveDomainSize(meta, 4, [], []);

            testCase.verifyEqual(nEff, 4);
        end

        function testResolveDomainSizeUsesCanonicalCaseForExplicitValue( ...
                testCase)

            v = testCase.validator_();
            meta = testCase.meta_();

            V = [1 2 3; 3 1 2];

            nEff = v.resolveDomainSize(meta, 3, V, []);

            testCase.verifyEqual(nEff, 3);
        end

        function testResolveDomainSizeUsesExplicitN(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            nEff = v.resolveDomainSize(meta, 4, [], 10);

            testCase.verifyEqual(nEff, 10);
        end

        function testResolveDomainSizeRejectsBadN(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f1 = @() v.resolveDomainSize(meta, 4, [], NaN);
            testCase.verifyError(f1, testCase.id_("BadN"));

            f2 = @() v.resolveDomainSize(meta, 4, [], 3);
            testCase.verifyError(f2, testCase.id_("BadN"));
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

            testCase.verifyError(f, testCase.id_("BadIndex"));
        end

        function testMustBeValidAtomIndicesRejectsEmptyAtomIndices( ...
                testCase)

            v = testCase.validator_();
            meta = testCase.meta_();
            obj = testCase.block_();

            f = @() v.mustBeValidAtomIndices(meta, obj, 1, []);

            testCase.verifyError(f, testCase.id_("BadIndex"));
        end

        function testMustBeValidAtomIndicesRejectsNonIntegerIndices( ...
                testCase)

            v = testCase.validator_();
            meta = testCase.meta_();
            obj = testCase.block_();

            f = @() v.mustBeValidAtomIndices(meta, obj, 1, [1; 2.5]);

            testCase.verifyError(f, testCase.id_("BadIndex"));
        end

        function testMustBeValidAtomIndicesRejectsOutOfRangeIndices( ...
                testCase)

            v = testCase.validator_();
            meta = testCase.meta_();
            obj = testCase.block_();

            f = @() v.mustBeValidAtomIndices(meta, obj, 1, [1; 6]);

            testCase.verifyError(f, testCase.id_("BadIndex"));
        end

        function testMustBeValidAtomUpdateHappyVector(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();
            obj = testCase.block_();

            v.mustBeValidAtomUpdate( ...
                meta, obj, 2, [1; 3; 5], [5 1 3]);
        end

        function testMustBeValidAtomUpdateRejectsNonIntegerValues( ...
                testCase)

            v = testCase.validator_();
            meta = testCase.meta_();
            obj = testCase.block_();

            f = @() v.mustBeValidAtomUpdate( ...
                meta, obj, 1, [1; 2], [1 2.5]);

            testCase.verifyError(f, testCase.id_("BadValue"));
        end

        function testMustBeValidAtomUpdateRejectsLengthMismatch( ...
                testCase)

            v = testCase.validator_();
            meta = testCase.meta_();
            obj = testCase.block_();

            f = @() v.mustBeValidAtomUpdate( ...
                meta, obj, 1, [1; 2; 3], [4 5]);

            testCase.verifyError(f, testCase.id_("BadValue"));
        end

        function testMustBeValidAtomUpdateRejectsDuplicateRow( ...
                testCase)

            v = testCase.validator_();
            meta = testCase.meta_();
            obj = testCase.block_();

            f = @() v.mustBeValidAtomUpdate( ...
                meta, obj, 1, [1; 2], [2 2]);

            testCase.verifyError(f, testCase.id_("BadValue"));
        end

        function testMustBeValidSwapArgsHappy(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();
            obj = testCase.block_();

            v.mustBeValidSwapArgs(meta, obj, 2, 1, 5);
        end

        function testMustBeValidSwapArgsRejectsBadIndividualIndex( ...
                testCase)

            v = testCase.validator_();
            meta = testCase.meta_();
            obj = testCase.block_();

            f = @() v.mustBeValidSwapArgs(meta, obj, 0, 1, 5);

            testCase.verifyError(f, testCase.id_("BadIndex"));
        end

        function testMustBeValidSwapArgsRejectsBadAtomIndexA( ...
                testCase)

            v = testCase.validator_();
            meta = testCase.meta_();
            obj = testCase.block_();

            f = @() v.mustBeValidSwapArgs(meta, obj, 1, 0, 5);

            testCase.verifyError(f, testCase.id_("BadIndex"));
        end

        function testMustBeValidSwapArgsRejectsBadAtomIndexB( ...
                testCase)

            v = testCase.validator_();
            meta = testCase.meta_();
            obj = testCase.block_();

            f = @() v.mustBeValidSwapArgs(meta, obj, 1, 1, 6);

            testCase.verifyError(f, testCase.id_("BadIndex"));
        end

    end

    methods (Access = private)

        function v = validator_(testCase)
            if testCase.FQCN == ...
                    "epistemic.tools.evolutionary.internal." + ...
                    "PermutationMetagenomeBlockValidator"

                v = epistemic.tools.evolutionary.internal. ...
                    PermutationMetagenomeBlockValidator;
                return
            end

            error("TestPermutationMetagenomeBlockValidator:BadFQCN", ...
                "Update FQCN and validator_().");
        end

        function meta = meta_(testCase)
            if testCase.FQCN == ...
                    "epistemic.tools.evolutionary.internal." + ...
                    "PermutationMetagenomeBlockValidator"

                meta = ?epistemic.tools.evolutionary.internal. ...
                    PermutationMetagenomeBlockValidator;
                return
            end

            error("TestPermutationMetagenomeBlockValidator:BadFQCN", ...
                "Update FQCN and meta_().");
        end

        function obj = block_(~)
            obj = epistemic.tools.evolutionary.genomes. ...
                PermutationMetagenomeBlock( ...
                nIndividuals = 3, ...
                nAtoms = 5, ...
                value = [ ...
                    1 2 3 4 5; ...
                    5 4 3 2 1; ...
                    2 4 1 5 3]);
        end

        function id = id_(testCase, suffix)
            id = "sfrfs:" + testCase.Leaf + ":" + string(suffix);
            id = char(id);
        end

    end

end