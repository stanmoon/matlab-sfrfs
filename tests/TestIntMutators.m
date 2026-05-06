classdef TestIntMutators < matlab.unittest.TestCase
% TestIntMutators
%
% Unit tests for:
%   epistemic.tools.evolutionary.operators.mutation.IntMutators

    methods (Test)

        function InferReturnsCallableMutationFunction(testCase)

            cfg = epistemic.tools.evolutionary.EngineConfig( ...
                powerLawAlpha = 1.5);

            mutateFcn = epistemic.tools.evolutionary. ...
                operators.mutation.IntMutators.infer( ...
                config = cfg);

            testCase.verifyClass(mutateFcn, "function_handle");
        end

        function MutateChangesSelectedAtomsOnly(testCase)

            rng(1);

            G0 = [ ...
                0  1  2  1  0; ...
                2  1  0  1  2];

            block = epistemic.tools.evolutionary.genomes. ...
                IntegerMetagenomeBlock( ...
                nIndividuals = 2, ...
                nAtoms = 5, ...
                lo = 0, ...
                hi = 2, ...
                value = G0);

            cfg = epistemic.tools.evolutionary.EngineConfig( ...
                powerLawAlpha = 1.5);

            mutateFcn = epistemic.tools.evolutionary. ...
                operators.mutation.IntMutators.infer( ...
                config = cfg);

            idx = [2; 4];
            mutateFcn(block, 2, idx);

            G = block.asMatrix();

            testCase.verifyEqual(G(1, :), G0(1, :));
            testCase.verifyEqual(G(2, [1 3 5]), G0(2, [1 3 5]));

            testCase.verifyTrue( ...
                any(G(2, idx') ~= G0(2, idx')));
        end

        function MutateKeepsSelectedAtomsWithinDeclaredDomain(testCase)

            rng(2);

            G0 = [ ...
                0  1  2  1  0; ...
                2  1  0  1  2];

            block = epistemic.tools.evolutionary.genomes. ...
                IntegerMetagenomeBlock( ...
                nIndividuals = 2, ...
                nAtoms = 5, ...
                lo = 0, ...
                hi = 2, ...
                value = G0);

            cfg = epistemic.tools.evolutionary.EngineConfig( ...
                powerLawAlpha = 0.7);

            mutateFcn = epistemic.tools.evolutionary. ...
                operators.mutation.IntMutators.infer( ...
                config = cfg);

            idx = [1; 3; 5];
            mutateFcn(block, 1, idx);

            values = block.getAtoms( ...
                individualIndex = 1, ...
                atomIndices = idx);

            testCase.verifyGreaterThanOrEqual(values, block.lo);
            testCase.verifyLessThanOrEqual(values, block.hi);
            testCase.verifyEqual(values, round(values));
        end

        function MutateStaysWithinDomain_SmallDomainStress(testCase)

            rng(3);

            domains = [ ...
                0  1;
               -1  1;
                0  2;
               -2  2];

            for d = 1:size(domains,1)

                lo = domains(d,1);
                hi = domains(d,2);

                for x0 = lo:hi

                    block = epistemic.tools.evolutionary.genomes. ...
                        IntegerMetagenomeBlock( ...
                        nIndividuals = 1, ...
                        nAtoms = 1, ...
                        lo = lo, ...
                        hi = hi, ...
                        value = x0);

                    cfg = epistemic.tools.evolutionary.EngineConfig( ...
                        powerLawAlpha = 1.2);

                    mutateFcn = epistemic.tools.evolutionary. ...
                        operators.mutation.IntMutators.infer( ...
                        config = cfg);

                    for k = 1:200

                        mutateFcn(block, 1, 1);

                        x = block.asMatrix();

                        testCase.verifyGreaterThanOrEqual(x, lo);
                        testCase.verifyLessThanOrEqual(x, hi);
                        testCase.verifyEqual(x, round(x));
                    end
                end
            end

        end

        function MutateRejectsDegenerateDomain(testCase)

            rng(4);

            block = epistemic.tools.evolutionary.genomes. ...
                IntegerMetagenomeBlock( ...
                nIndividuals = 1, ...
                nAtoms = 1, ...
                lo = 3, ...
                hi = 3, ...
                value = 3);

            cfg = epistemic.tools.evolutionary.EngineConfig( ...
                powerLawAlpha = 1.5);

            mutateFcn = epistemic.tools.evolutionary. ...
                operators.mutation.IntMutators.infer( ...
                config = cfg);

            f = @() mutateFcn(block, 1, 1);

            testCase.verifyError(f, ...
                "sfrfs:IncrementLaw:BadBounds");
        end

        function MutateMinimalDomainWorks(testCase)

            rng(5);

            block = epistemic.tools.evolutionary.genomes. ...
                IntegerMetagenomeBlock( ...
                nIndividuals = 1, ...
                nAtoms = 1, ...
                lo = 3, ...
                hi = 4, ...
                value = 3);

            cfg = epistemic.tools.evolutionary.EngineConfig( ...
                powerLawAlpha = 1.0);

            mutateFcn = epistemic.tools.evolutionary. ...
                operators.mutation.IntMutators.infer( ...
                config = cfg);

            mutateFcn(block, 1, 1);

            x = block.asMatrix();

            testCase.verifyGreaterThanOrEqual(x, 3);
            testCase.verifyLessThanOrEqual(x, 4);
            testCase.verifyEqual(x, round(x));
        end

    end

end