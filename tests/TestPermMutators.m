classdef TestPermMutators < matlab.unittest.TestCase
% TestPermMutators
%
% Unit tests for:
%   epistemic.tools.evolutionary.operators.mutation.PermMutators

    methods (Test)

        function InferReturnsCallableMutationFunction(testCase)

            cfg = epistemic.tools.evolutionary.EngineConfig( ...
                powerLawAlpha = 1.5, ...
                powerLawRMin = 1.0e-3);

            mutateFcn = epistemic.tools.evolutionary. ...
                operators.mutation.PermMutators.infer( ...
                config = cfg);

            testCase.verifyClass(mutateFcn, "function_handle");
        end

        function MutateChangesSelectedRowOnly(testCase)

            rng(1);

            G0 = [ ...
                1 2 3 4 5; ...
                5 4 3 2 1];

            block = epistemic.tools.evolutionary.genomes. ...
                PermutationMetagenomeBlock( ...
                nIndividuals = 2, ...
                nAtoms = 5, ...
                value = G0);

            cfg = epistemic.tools.evolutionary.EngineConfig( ...
                powerLawAlpha = 1.5, ...
                powerLawRMin = 1.0e-3);

            mutateFcn = epistemic.tools.evolutionary. ...
                operators.mutation.PermMutators.infer( ...
                config = cfg);

            idx = [2; 4];
            mutateFcn(block, 2, idx);

            G = block.asMatrix();

            testCase.verifyEqual(G(1, :), G0(1, :));
            testCase.verifyNotEqual(G(2, :), G0(2, :));
        end

        function MutatePreservesPermutationValidity(testCase)

            rng(2);

            G0 = [ ...
                1 2 3 4 5 6; ...
                6 5 4 3 2 1];

            block = epistemic.tools.evolutionary.genomes. ...
                PermutationMetagenomeBlock( ...
                nIndividuals = 2, ...
                nAtoms = 6, ...
                value = G0);

            cfg = epistemic.tools.evolutionary.EngineConfig( ...
                powerLawAlpha = 0.7, ...
                powerLawRMin = 1.0e-3);

            mutateFcn = epistemic.tools.evolutionary. ...
                operators.mutation.PermMutators.infer( ...
                config = cfg);

            idx = [1; 3; 6];
            mutateFcn(block, 1, idx);

            row = block.asMatrix();
            row = row(1, :);

            testCase.verifyEqual(sort(row), 1:6);
        end

        function MutateKeepsNonSelectedRowsUnchanged(testCase)

            rng(3);

            G0 = [ ...
                1 2 3 4; ...
                4 3 2 1; ...
                2 1 4 3];

            block = epistemic.tools.evolutionary.genomes. ...
                PermutationMetagenomeBlock( ...
                nIndividuals = 3, ...
                nAtoms = 4, ...
                value = G0);

            cfg = epistemic.tools.evolutionary.EngineConfig( ...
                powerLawAlpha = 1.5, ...
                powerLawRMin = 1.0e-3);

            mutateFcn = epistemic.tools.evolutionary. ...
                operators.mutation.PermMutators.infer( ...
                config = cfg);

            idx = [2; 3];
            mutateFcn(block, 2, idx);

            G = block.asMatrix();

            testCase.verifyEqual(G(1, :), G0(1, :));
            testCase.verifyEqual(G(3, :), G0(3, :));
        end

        function MutateCanMoveBoundaryAnchors(testCase)

            rng(4);

            G0 = [1 2 3 4 5];

            block = epistemic.tools.evolutionary.genomes. ...
                PermutationMetagenomeBlock( ...
                nIndividuals = 1, ...
                nAtoms = 5, ...
                value = G0);

            cfg = epistemic.tools.evolutionary.EngineConfig( ...
                powerLawAlpha = 1.5, ...
                powerLawRMin = 1.0e-3);

            mutateFcn = epistemic.tools.evolutionary. ...
                operators.mutation.PermMutators.infer( ...
                config = cfg);

            idx = [1; 5];
            mutateFcn(block, 1, idx);

            row = block.asMatrix();
            row = row(1, :);

            testCase.verifyEqual(sort(row), 1:5);
        end

    end

end