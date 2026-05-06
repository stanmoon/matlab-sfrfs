classdef TestMutationAgenda < matlab.unittest.TestCase
% TestMutationAgenda
%
% Unit tests for operators.mutation.MutationAgenda.

    methods (Test)

        function Constructor_BuildsAgendaWithValidEntries(testCase)

            agenda = epistemic.tools.evolutionary. ...
                operators.mutation.MutationAgenda( ...
                nGenerations = 4, ...
                nIndividuals = 7, ...
                nAtomsPerBlock = [10 3 25], ...
                rho = 0.2);

            nGen = 4;
            nInd = 7;
            nAtoms = [10 3 25];
            nBlocks = numel(nAtoms);

            for g = 1:nGen
                for i = 1:nInd

                    T = agenda.getTargets(g, i);
                    k = agenda.getTargetCount(g, i);

                    testCase.verifySize(T, [k 2]);
                    testCase.verifyClass(T, "double");

                    if isempty(T)
                        continue
                    end

                    blocks = T(:,1);
                    atoms = T(:,2);

                    testCase.verifyGreaterThanOrEqual(blocks, 1);
                    testCase.verifyLessThanOrEqual(blocks, nBlocks);

                    for r = 1:k
                        b = blocks(r);
                        a = atoms(r);

                        testCase.verifyGreaterThanOrEqual(a, 1);
                        testCase.verifyLessThanOrEqual(a, nAtoms(b));
                    end
                end
            end
        end

        function TargetCounts_MatchEntrySizes(testCase)

            agenda = epistemic.tools.evolutionary. ...
                operators.mutation.MutationAgenda( ...
                nGenerations = 3, ...
                nIndividuals = 5, ...
                nAtomsPerBlock = [8 4], ...
                rho = 0.15);

            for g = 1:3
                for i = 1:5

                    T = agenda.getTargets(g, i);
                    k = agenda.getTargetCount(g, i);

                    testCase.verifyEqual(k, size(T,1));

                end
            end
        end

        function ZeroMutationRate_YieldsEmptyEntries(testCase)

            agenda = epistemic.tools.evolutionary. ...
                operators.mutation.MutationAgenda( ...
                nGenerations = 3, ...
                nIndividuals = 6, ...
                nAtomsPerBlock = [12 5 2], ...
                rho = 0.0);

            for g = 1:3
                for i = 1:6

                    T = agenda.getTargets(g, i);
                    k = agenda.getTargetCount(g, i);

                    testCase.verifyEmpty(T);
                    testCase.verifyEqual(k, 0);

                end
            end
        end

        function Targets_AreUniqueWithinEachBlock(testCase)

            agenda = epistemic.tools.evolutionary. ...
                operators.mutation.MutationAgenda( ...
                nGenerations = 5, ...
                nIndividuals = 8, ...
                nAtomsPerBlock = [20 6 11], ...
                rho = 0.3);

            for g = 1:5
                for i = 1:8

                    T = agenda.getTargets(g, i);

                    if isempty(T)
                        continue
                    end

                    blocks = unique(T(:,1));

                    for j = 1:numel(blocks)
                        b = blocks(j);
                        atoms = T(T(:,1)==b,2);

                        testCase.verifyEqual( ...
                            numel(atoms), ...
                            numel(unique(atoms)));
                    end
                end
            end
        end

        function Targets_AreGroupedByAscendingBlockIndex(testCase)

            agenda = epistemic.tools.evolutionary. ...
                operators.mutation.MutationAgenda( ...
                nGenerations = 4, ...
                nIndividuals = 6, ...
                nAtomsPerBlock = [9 5 7 3], ...
                rho = 0.25);

            for g = 1:4
                for i = 1:6

                    T = agenda.getTargets(g, i);

                    if size(T, 1) <= 1
                        continue
                    end

                    blocks = T(:,1);

                    testCase.verifyGreaterThanOrEqual( ...
                        diff(blocks), 0);

                end
            end
        end

        function Iterator_YieldsSameTargetsAsRawView(testCase)

            agenda = epistemic.tools.evolutionary. ...
                operators.mutation.MutationAgenda( ...
                nGenerations = 4, ...
                nIndividuals = 7, ...
                nAtomsPerBlock = [10 3 25], ...
                rho = 0.2);

            for g = 1:4
                for i = 1:7

                    T = agenda.getTargets(g, i);
                    next = agenda.iterator(g, i);

                    collected = zeros(0, 2);

                    while true
                        [ok, b, atoms] = next();

                        if ~ok
                            break
                        end

                        m = numel(atoms);

                        collected = [ ...
                            collected; ...
                            [b * ones(m, 1), atoms(:)]];
                    end

                    testCase.verifyEqual(collected, T);

                end
            end
        end

        function Iterator_FirstCallOnEmptyTargets_ReturnsFalse(testCase)

            agenda = epistemic.tools.evolutionary. ...
                operators.mutation.MutationAgenda( ...
                nGenerations = 2, ...
                nIndividuals = 4, ...
                nAtomsPerBlock = [6 3 2], ...
                rho = 0.0);

            for g = 1:2
                for i = 1:4

                    next = agenda.iterator(g, i);
                    [ok, b, atoms] = next();

                    testCase.verifyFalse(ok);
                    testCase.verifyEmpty(b);
                    testCase.verifyEmpty(atoms);

                end
            end
        end

        function Iterator_IsConsumable(testCase)

            agenda = epistemic.tools.evolutionary. ...
                operators.mutation.MutationAgenda( ...
                nGenerations = 4, ...
                nIndividuals = 6, ...
                nAtomsPerBlock = [10 4 8], ...
                rho = 0.25);

            foundNonEmpty = false;

            for g = 1:4
                for i = 1:6

                    T = agenda.getTargets(g, i);

                    if isempty(T)
                        continue
                    end

                    next = agenda.iterator(g, i);

                    while true
                        [ok, ~, ~] = next();

                        if ~ok
                            break
                        end
                    end

                    [ok2, b2, atoms2] = next();

                    testCase.verifyFalse(ok2);
                    testCase.verifyEmpty(b2);
                    testCase.verifyEmpty(atoms2);

                    foundNonEmpty = true;
                    break
                end

                if foundNonEmpty
                    break
                end
            end

            testCase.assertTrue(foundNonEmpty, ...
                "Test did not encounter a non-empty agenda entry.");
        end


        function Constructor_ThrowsForBadNGenerations(testCase)

            f = @() epistemic.tools.evolutionary. ...
                operators.mutation.MutationAgenda( ...
                nGenerations = 0, ...
                nIndividuals = 5, ...
                nAtomsPerBlock = [10 3], ...
                rho = 0.2);

            testCase.verifyError( ...
                f, "sfrfs:MutationAgenda:BadNGenerations");
        end

        function Constructor_ThrowsForBadNIndividuals(testCase)

            f = @() epistemic.tools.evolutionary. ...
                operators.mutation.MutationAgenda( ...
                nGenerations = 3, ...
                nIndividuals = 0, ...
                nAtomsPerBlock = [10 3], ...
                rho = 0.2);

            testCase.verifyError( ...
                f, "sfrfs:MutationAgenda:BadNIndividuals");
        end

        function Constructor_ThrowsForEmptyAtomsPerBlock(testCase)

            f = @() epistemic.tools.evolutionary. ...
                operators.mutation.MutationAgenda( ...
                nGenerations = 3, ...
                nIndividuals = 5, ...
                nAtomsPerBlock = [], ...
                rho = 0.2);

            testCase.verifyError( ...
                f, "sfrfs:MutationAgenda:EmptyAtomsPerBlock");
        end

        function Constructor_ThrowsForBadAtomsShape(testCase)

            f = @() epistemic.tools.evolutionary. ...
                operators.mutation.MutationAgenda( ...
                nGenerations = 3, ...
                nIndividuals = 5, ...
                nAtomsPerBlock = [10; 3], ...
                rho = 0.2);

            testCase.verifyError( ...
                f, "sfrfs:MutationAgenda:BadAtomsPerBlockShape");
        end

        function Constructor_ThrowsForBadAtomsType(testCase)

            f = @() epistemic.tools.evolutionary. ...
                operators.mutation.MutationAgenda( ...
                nGenerations = 3, ...
                nIndividuals = 5, ...
                nAtomsPerBlock = [10 2.5], ...
                rho = 0.2);

            testCase.verifyError( ...
                f, "sfrfs:MutationAgenda:BadAtomsPerBlockType");
        end

        function Constructor_ThrowsForNonPositiveAtoms(testCase)

            f = @() epistemic.tools.evolutionary. ...
                operators.mutation.MutationAgenda( ...
                nGenerations = 3, ...
                nIndividuals = 5, ...
                nAtomsPerBlock = [10 0], ...
                rho = 0.2);

            testCase.verifyError( ...
                f, "sfrfs:MutationAgenda:NonPositiveAtoms");
        end

        function Constructor_ThrowsForBadRho(testCase)

            f = @() epistemic.tools.evolutionary. ...
                operators.mutation.MutationAgenda( ...
                nGenerations = 3, ...
                nIndividuals = 5, ...
                nAtomsPerBlock = [10 3], ...
                rho = NaN);

            testCase.verifyError( ...
                f, "sfrfs:MutationAgenda:BadRho");
        end

        function Constructor_ThrowsForRhoOutOfRange(testCase)

            f1 = @() epistemic.tools.evolutionary. ...
                operators.mutation.MutationAgenda( ...
                nGenerations = 3, ...
                nIndividuals = 5, ...
                nAtomsPerBlock = [10 3], ...
                rho = -0.1);

            f2 = @() epistemic.tools.evolutionary. ...
                operators.mutation.MutationAgenda( ...
                nGenerations = 3, ...
                nIndividuals = 5, ...
                nAtomsPerBlock = [10 3], ...
                rho = 1.5);

            testCase.verifyError( ...
                f1, "sfrfs:MutationAgenda:RhoOutOfRange");
            testCase.verifyError( ...
                f2, "sfrfs:MutationAgenda:RhoOutOfRange");
        end

    end

end