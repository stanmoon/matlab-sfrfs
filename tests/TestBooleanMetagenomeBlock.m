classdef TestBooleanMetagenomeBlock < matlab.unittest.TestCase

    methods (Test)

        function testValueCreatesConstantMatrix(testCase)
            b = epistemic.tools.evolutionary.genomes. ...
                BooleanMetagenomeBlock( ...
                nIndividuals = 3, nAtoms = 4, value = true);

            G = b.asMatrix();

            testCase.verifySize(G, [3, 4]);
            testCase.verifyClass(G, "logical");
            testCase.verifyTrue(all(G(:)));
        end

        function testValueCreatesGivenLogicalMatrix(testCase)
            G0 = logical([true false; false true]);

            b = epistemic.tools.evolutionary.genomes. ...
                BooleanMetagenomeBlock( ...
                nIndividuals = 2, nAtoms = 2, value = G0);

            G = b.asMatrix();

            testCase.verifyEqual(G, G0);
        end

        function testProbabilityCreatesLogicalMatrix(testCase)
            b = epistemic.tools.evolutionary.genomes. ...
                BooleanMetagenomeBlock( ...
                nIndividuals = 5, nAtoms = 6, probability = 0.2);

            G = b.asMatrix();

            testCase.verifySize(G, [5, 6]);
            testCase.verifyClass(G, "logical");
        end

        function testZeroProbabilityCreatesAllFalse(testCase)
            b = epistemic.tools.evolutionary.genomes. ...
                BooleanMetagenomeBlock( ...
                nIndividuals = 3, nAtoms = 4, probability = 0);

            G = b.asMatrix();

            testCase.verifyEqual(G, false(3, 4));
        end

        function testOneProbabilityCreatesAllTrue(testCase)
            b = epistemic.tools.evolutionary.genomes. ...
                BooleanMetagenomeBlock( ...
                nIndividuals = 3, nAtoms = 4, probability = 1);

            G = b.asMatrix();

            testCase.verifyEqual(G, true(3, 4));
        end

        function testSetAtomsScalarBroadcast(testCase)
            b = epistemic.tools.evolutionary.genomes. ...
                BooleanMetagenomeBlock( ...
                nIndividuals = 2, nAtoms = 5, value = false);

            b.setAtoms( ...
                individualIndex = 2, ...
                atomIndices = [2; 4], ...
                values = true);

            G = b.asMatrix();
            Gexp = false(2, 5);
            Gexp(2, [2 4]) = true;

            testCase.verifyEqual(G, Gexp);
        end

        function testSetAtomsVectorAssignment(testCase)
            b = epistemic.tools.evolutionary.genomes. ...
                BooleanMetagenomeBlock( ...
                nIndividuals = 2, nAtoms = 5, value = false);

            b.setAtoms( ...
                individualIndex = 1, ...
                atomIndices = [1; 3; 5], ...
                values = logical([true false true]));

            G = b.asMatrix();
            Gexp = false(2, 5);
            Gexp(1, [1 3 5]) = logical([true false true]);

            testCase.verifyEqual(G, Gexp);
        end

        function testFlipAtomsFlipsSelectedAtoms(testCase)
            G0 = logical([true false true false; false true false true]);

            b = epistemic.tools.evolutionary.genomes. ...
                BooleanMetagenomeBlock( ...
                nIndividuals = 2, nAtoms = 4, value = G0);

            b.flipAtoms( ...
                individualIndex = 1, ...
                atomIndices = [2; 3]);

            G = b.asMatrix();
            Gexp = G0;
            Gexp(1, [2 3]) = ~Gexp(1, [2 3]);

            testCase.verifyEqual(G, Gexp);
        end

        function testProbabilityBelowZeroThrowsError(testCase)
            f = @() epistemic.tools.evolutionary.genomes. ...
                BooleanMetagenomeBlock( ...
                nIndividuals = 1, nAtoms = 1, ...
                probability = -eps);

            testCase.verifyError(f, ...
                "sfrfs:BooleanMetagenomeBlock:BadArg");
        end

        function testProbabilityAboveOneThrowsError(testCase)
            f = @() epistemic.tools.evolutionary.genomes. ...
                BooleanMetagenomeBlock( ...
                nIndividuals = 1, nAtoms = 1, ...
                probability = 1 + eps);

            testCase.verifyError(f, ...
                "sfrfs:BooleanMetagenomeBlock:BadArg");
        end

        function testMutuallyExclusiveArgsError(testCase)
            f = @() epistemic.tools.evolutionary.genomes. ...
                BooleanMetagenomeBlock( ...
                nIndividuals = 1, ...
                nAtoms = 1, value = true, probability = 0.5);

            testCase.verifyError(f, ...
                "sfrfs:BooleanMetagenomeBlock:AmbiguousInit");
        end

        function testValueMustBeLogicalScalarOrMatrix(testCase)
            f1 = @() epistemic.tools.evolutionary.genomes. ...
                BooleanMetagenomeBlock( ...
                nIndividuals = 1, nAtoms = 1, value = 1);

            testCase.verifyError(f1, ...
                "sfrfs:BooleanMetagenomeBlock:BadArg");

            f2 = @() epistemic.tools.evolutionary.genomes. ...
                BooleanMetagenomeBlock( ...
                nIndividuals = 1, nAtoms = 1, value = [true false]);

            testCase.verifyError(f2, ...
                "sfrfs:BooleanMetagenomeBlock:BadArg");
        end

        function testProbabilityMustBeFiniteScalar(testCase)
            f1 = @() epistemic.tools.evolutionary.genomes. ...
                BooleanMetagenomeBlock( ...
                nIndividuals = 1, nAtoms = 1, probability = NaN);

            testCase.verifyError(f1, ...
                "sfrfs:BooleanMetagenomeBlock:BadArg");

            f2 = @() epistemic.tools.evolutionary.genomes. ...
                BooleanMetagenomeBlock( ...
                nIndividuals = 1, nAtoms = 1, probability = [0.2 0.3]);

            testCase.verifyError(f2, ...
                "sfrfs:BooleanMetagenomeBlock:BadArg");
        end

    end
end