classdef TestBooleanMetagenomeBlockValidator < matlab.unittest.TestCase
% TestBooleanMetagenomeBlockValidator
% Unit tests for BooleanMetagenomeBlockValidator.

    properties (Constant, Access = private)
        FQCN = ...
            "epistemic.tools.evolutionary.internal." + ...
            "BooleanMetagenomeBlockValidator";
        Leaf = "BooleanMetagenomeBlockValidator";
    end

    methods (Test)

        function testValidateConstructorInputsHappyWithDefaultInit(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            v.validateConstructorInputs( ...
                meta, 2, 3, [], []);
        end

        function testValidateConstructorInputsHappyWithProbability(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            v.validateConstructorInputs( ...
                meta, 2, 3, [], 0.25);
        end

        function testValidateConstructorInputsHappyWithScalarLogicalValue( ...
                testCase)

            v = testCase.validator_();
            meta = testCase.meta_();

            v.validateConstructorInputs( ...
                meta, 2, 3, true, []);
        end

        function testValidateConstructorInputsHappyWithLogicalMatrixValue( ...
                testCase)

            v = testCase.validator_();
            meta = testCase.meta_();

            G = logical([1 0 1; 0 1 0]);

            v.validateConstructorInputs( ...
                meta, 2, 3, G, []);
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
                meta, 2, 3, true, 0.5);

            testCase.verifyError(f, testCase.id_("AmbiguousInit"));
        end

        function testValidateProbabilityHappy(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            v.validateProbability(meta, 0.0);
            v.validateProbability(meta, 0.5);
            v.validateProbability(meta, 1.0);
        end

        function testValidateProbabilityRejectsBadValues(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f1 = @() v.validateProbability(meta, NaN);
            testCase.verifyError(f1, testCase.id_("BadArg"));

            f2 = @() v.validateProbability(meta, -0.1);
            testCase.verifyError(f2, testCase.id_("BadArg"));

            f3 = @() v.validateProbability(meta, 1.1);
            testCase.verifyError(f3, testCase.id_("BadArg"));
        end

        function testValidateExplicitValueAcceptsScalarLogical(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            v.validateExplicitValue(meta, false, 4, 5);
        end

        function testValidateExplicitValueAcceptsLogicalMatrix(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            G = logical([1 0 1; 0 1 0]);

            v.validateExplicitValue(meta, G, 2, 3);
        end

        function testValidateExplicitValueRejectsNonLogical(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f1 = @() v.validateExplicitValue(meta, [1 0], 1, 2);
            testCase.verifyError(f1, testCase.id_("BadArg"));

            f2 = @() v.validateExplicitValue(meta, "true", 1, 1);
            testCase.verifyError(f2, testCase.id_("BadArg"));
        end

        function testValidateExplicitValueRejectsSizeMismatch(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            G = logical([1 0]);

            f = @() v.validateExplicitValue(meta, G, 2, 2);

            testCase.verifyError(f, testCase.id_("BadArg"));
        end

    end

    methods (Access = private)

        function v = validator_(testCase)
            if testCase.FQCN == ...
                    "epistemic.tools.evolutionary.internal." + ...
                    "BooleanMetagenomeBlockValidator"

                v = epistemic.tools.evolutionary.internal. ...
                    BooleanMetagenomeBlockValidator;
                return
            end

            error("TestBooleanMetagenomeBlockValidator:BadFQCN", ...
                "Update FQCN and validator_().");
        end

        function meta = meta_(testCase)
            if testCase.FQCN == ...
                    "epistemic.tools.evolutionary.internal." + ...
                    "BooleanMetagenomeBlockValidator"

                meta = ?epistemic.tools.evolutionary.internal. ...
                    BooleanMetagenomeBlockValidator;
                return
            end

            error("TestBooleanMetagenomeBlockValidator:BadFQCN", ...
                "Update FQCN and meta_().");
        end

        function id = id_(testCase, suffix)
            id = "sfrfs:" + testCase.Leaf + ":" + string(suffix);
            id = char(id);
        end

    end

end