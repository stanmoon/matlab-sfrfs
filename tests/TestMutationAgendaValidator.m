classdef TestMutationAgendaValidator < matlab.unittest.TestCase
% TestMutationAgendaValidator
% Unit tests for MutationAgendaValidator (funnel-based errors).

    properties (Constant, Access = private)
        FQCN = ...
            "epistemic.tools.evolutionary.internal." + ...
            "MutationAgendaValidator";
        Leaf = "MutationAgendaValidator";
    end

    methods (Test)

        function testValidateConstructorInputsHappy(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            v.validateConstructorInputs( ...
                meta, ...
                5, ...
                10, ...
                [10 3 7], ...
                0.2);
        end

        function testBadNGenerations(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f = @() v.validateConstructorInputs( ...
                meta, 0, 10, [5 3], 0.2);

            testCase.verifyError(f, testCase.id_("BadNGenerations"));
        end

        function testBadNIndividuals(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f = @() v.validateConstructorInputs( ...
                meta, 5, 0, [5 3], 0.2);

            testCase.verifyError(f, testCase.id_("BadNIndividuals"));
        end

        function testBadAtomsPerBlockShape(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f = @() v.validateConstructorInputs( ...
                meta, 5, 10, [5; 3], 0.2);

            testCase.verifyError( ...
                f, testCase.id_("BadAtomsPerBlockShape"));
        end

        function testBadAtomsPerBlockType(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f = @() v.validateConstructorInputs( ...
                meta, 5, 10, [5 2.5], 0.2);

            testCase.verifyError( ...
                f, testCase.id_("BadAtomsPerBlockType"));
        end

        function testEmptyAtomsPerBlock(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f = @() v.validateConstructorInputs( ...
                meta, 5, 10, [], 0.2);

            testCase.verifyError( ...
                f, testCase.id_("EmptyAtomsPerBlock"));
        end

        function testNonPositiveAtoms(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f = @() v.validateConstructorInputs( ...
                meta, 5, 10, [5 0 3], 0.2);

            testCase.verifyError( ...
                f, testCase.id_("NonPositiveAtoms"));
        end

        function testBadRho(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f = @() v.validateConstructorInputs( ...
                meta, 5, 10, [5 3], NaN);

            testCase.verifyError(f, testCase.id_("BadRho"));
        end

        function testRhoOutOfRangeLow(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f = @() v.validateConstructorInputs( ...
                meta, 5, 10, [5 3], -0.1);

            testCase.verifyError( ...
                f, testCase.id_("RhoOutOfRange"));
        end

        function testRhoOutOfRangeHigh(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f = @() v.validateConstructorInputs( ...
                meta, 5, 10, [5 3], 1.5);

            testCase.verifyError( ...
                f, testCase.id_("RhoOutOfRange"));
        end

    end

    methods (Access = private)

        function v = validator_(testCase)
            if testCase.FQCN == ...
                    "epistemic.tools.evolutionary.internal." + ...
                    "MutationAgendaValidator"

                v = epistemic.tools.evolutionary.internal. ...
                    MutationAgendaValidator;
                return
            end

            error("TestMutationAgendaValidator:BadFQCN", ...
                "Update FQCN and validator_().");
        end

        function meta = meta_(testCase)
            if testCase.FQCN == ...
                    "epistemic.tools.evolutionary.internal." + ...
                    "MutationAgendaValidator"

                meta = ?epistemic.tools.evolutionary.internal. ...
                    MutationAgendaValidator;
                return
            end

            error("TestMutationAgendaValidator:BadFQCN", ...
                "Update FQCN and meta_().");
        end

        function id = id_(testCase, suffix)
            id = "sfrfs:" + testCase.Leaf + ":" + string(suffix);
            id = char(id);
        end

    end

end