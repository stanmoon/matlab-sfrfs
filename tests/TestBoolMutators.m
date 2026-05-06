classdef TestBoolMutators < matlab.unittest.TestCase

    methods (Test)

        function testInferReturnsCallable(testCase)

            f = epistemic.tools.evolutionary. ...
                operators.mutation.BoolMutators.infer();

            testCase.verifyClass(f, "function_handle");

        end

        function testFlipMutationIsApplied(testCase)

            b = epistemic.tools.evolutionary.genomes. ...
                BooleanMetagenomeBlock( ...
                nIndividuals = 2, ...
                nAtoms = 4, ...
                value = false);

            f = epistemic.tools.evolutionary. ...
                operators.mutation.BoolMutators.infer();

            f(b, 1, [2 4]);

            G = b.asMatrix();

            Gexp = false(2,4);
            Gexp(1,[2 4]) = true;

            testCase.verifyEqual(G, Gexp);

        end

        function testFlipMutationTwiceRestores(testCase)

            b = epistemic.tools.evolutionary.genomes. ...
                BooleanMetagenomeBlock( ...
                nIndividuals = 1, ...
                nAtoms = 3, ...
                value = false);

            f = epistemic.tools.evolutionary. ...
                operators.mutation.BoolMutators.infer();

            f(b, 1, [1 2]);
            f(b, 1, [1 2]);

            testCase.verifyEqual(b.asMatrix(), false(1,3));

        end

        function testEmptyIndicesNoEffect(testCase)

            b = epistemic.tools.evolutionary.genomes. ...
                BooleanMetagenomeBlock( ...
                nIndividuals = 1, ...
                nAtoms = 3, ...
                value = true);

            f = epistemic.tools.evolutionary. ...
                operators.mutation.BoolMutators.infer();

            f(b, 1, zeros(0,1));

            testCase.verifyEqual(b.asMatrix(), true(1,3));

        end

    end

end