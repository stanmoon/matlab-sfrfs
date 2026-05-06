classdef TestIntegerMetagenomeBlockValidator < matlab.unittest.TestCase
% TestIntegerMetagenomeBlockValidator
% Unit tests for IntegerMetagenomeBlockValidator.

    properties (Constant, Access = private)
        FQCN = ...
            "epistemic.tools.evolutionary.internal." + ...
            "IntegerMetagenomeBlockValidator";
        Leaf = "IntegerMetagenomeBlockValidator";
    end

    methods (Test)

        function testValidateConstructorInputsHappy(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            v.validateConstructorInputs( ...
                meta, 2, 3, -2, 7, []);
        end

        function testBadNIndividuals(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f = @() v.validateConstructorInputs( ...
                meta, 0, 3, -2, 7, []);

            testCase.verifyError(f, testCase.id_("BadNIndividuals"));
        end

        function testBadNAtoms(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f = @() v.validateConstructorInputs( ...
                meta, 2, 0, -2, 7, []);

            testCase.verifyError(f, testCase.id_("BadNAtoms"));
        end

        function testBadLo(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f1 = @() v.validateConstructorInputs( ...
                meta, 2, 3, NaN, 7, []);
            testCase.verifyError(f1, testCase.id_("BadArg"));

            f2 = @() v.validateConstructorInputs( ...
                meta, 2, 3, 1.5, 7, []);
            testCase.verifyError(f2, testCase.id_("BadArg"));
        end

        function testBadHi(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f1 = @() v.validateConstructorInputs( ...
                meta, 2, 3, -2, NaN, []);
            testCase.verifyError(f1, testCase.id_("BadArg"));

            f2 = @() v.validateConstructorInputs( ...
                meta, 2, 3, -2, 7.2, []);
            testCase.verifyError(f2, testCase.id_("BadArg"));
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

            v.validateDomain(meta, -3, 4);
        end

        %% --- UPDATED: explicit value now needs lo, hi ---

        function testValidateExplicitValueHappy(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            G = [-3 -2 -1; 0 1 2];

            v.validateExplicitValue(meta, G, 2, 3, -3, 2);
        end

        function testValidateExplicitValueRejectsNonInteger(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f = @() v.validateExplicitValue( ...
                meta, [1 2.2], 1, 2, 0, 3);

            testCase.verifyError(f, testCase.id_("BadArg"));
        end

        function testValidateExplicitValueRejectsNonFinite(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f = @() v.validateExplicitValue( ...
                meta, [1 NaN], 1, 2, 0, 3);

            testCase.verifyError(f, testCase.id_("BadArg"));
        end

        function testValidateExplicitValueRejectsSizeMismatch(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            f = @() v.validateExplicitValue( ...
                meta, zeros(2, 2), 2, 3, 0, 3);

            testCase.verifyError(f, testCase.id_("BadArg"));
        end

        function testValidateExplicitValueRejectsOutOfDomain(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            G = [0 1 5]; % 5 outside [0,3]

            f = @() v.validateExplicitValue( ...
                meta, G, 1, 3, 0, 3);

            testCase.verifyError(f, ...
                testCase.id_("ValueOutOfDomain"));
        end

        %% --- NEW: atom index validation ---

        function testMustBeValidAtomIndicesHappy(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            block = epistemic.tools.evolutionary.genomes. ...
                IntegerMetagenomeBlock( ...
                nIndividuals = 2, ...
                nAtoms = 3, ...
                lo = 0, ...
                hi = 5);

            v.mustBeValidAtomIndices(meta, block, 1, [1 3]);
        end

        function testMustBeValidAtomIndicesRejectsBadIndividual(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            block = epistemic.tools.evolutionary.genomes. ...
                IntegerMetagenomeBlock( ...
                nIndividuals = 2, ...
                nAtoms = 3);

            f = @() v.mustBeValidAtomIndices(meta, block, 3, 1);

            testCase.verifyError(f, testCase.id_("BadIndex"));
        end

        function testMustBeValidAtomIndicesRejectsBadAtomIndex(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            block = epistemic.tools.evolutionary.genomes. ...
                IntegerMetagenomeBlock( ...
                nIndividuals = 2, ...
                nAtoms = 3);

            f = @() v.mustBeValidAtomIndices(meta, block, 1, 4);

            testCase.verifyError(f, testCase.id_("BadIndex"));
        end

        %% --- NEW: atom update validation ---

        function testMustBeValidAtomUpdateHappy(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            block = epistemic.tools.evolutionary.genomes. ...
                IntegerMetagenomeBlock( ...
                nIndividuals = 2, ...
                nAtoms = 3, ...
                lo = 0, ...
                hi = 5);

            v.mustBeValidAtomUpdate(meta, block, 1, [1 2], [3 4]);
        end

        function testMustBeValidAtomUpdateRejectsSizeMismatch(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            block = epistemic.tools.evolutionary.genomes. ...
                IntegerMetagenomeBlock( ...
                nIndividuals = 2, ...
                nAtoms = 3, ...
                lo = 0, ...
                hi = 5);

            f = @() v.mustBeValidAtomUpdate(meta, block, ...
                1, [1 2], [3 4 5]);

            testCase.verifyError(f, testCase.id_("BadSize"));
        end

        function testMustBeValidAtomUpdateRejectsOutOfDomain(testCase)
            v = testCase.validator_();
            meta = testCase.meta_();

            block = epistemic.tools.evolutionary.genomes. ...
                IntegerMetagenomeBlock( ...
                nIndividuals = 2, ...
                nAtoms = 3, ...
                lo = 0, ...
                hi = 5);

            f = @() v.mustBeValidAtomUpdate(meta, block, ...
                1, 1, 10);

            testCase.verifyError(f, ...
                testCase.id_("ValueOutOfDomain"));
        end

    end

    methods (Access = private)

        function v = validator_(~)
            v = epistemic.tools.evolutionary.internal. ...
                IntegerMetagenomeBlockValidator;
        end

        function meta = meta_(~)
            meta = ?epistemic.tools.evolutionary.internal. ...
                IntegerMetagenomeBlockValidator;
        end

        function id = id_(testCase, suffix)
            id = "sfrfs:" + testCase.Leaf + ":" + string(suffix);
            id = char(id);
        end

    end

end