classdef TestEnumDecoders < matlab.unittest.TestCase
% TestEnumDecoders
%
% Unit tests for EnumDecoders using PhenotypeParameterKind as enum domain.
%
% Contract:
%   - All decoders operate on MetagenomeBlock instances.
%   - Individuals are represented by rows in the source block.
%   - Output shape is [nIndividuals, p].

    methods (Test)

        function inferRejectsUnknownSourceBlockType(testCase)
            f = @() epistemic.tools.evolutionary.phenotype.decoders. ...
                EnumDecoders.infer(sourceBlockType="weird");

            testCase.verifyError( ...
                f, ...
                "sfrfs:EnumDecoders:UnsupportedSourceBlockType");
        end

        function inferAcceptsComplexSourceBlockType(testCase)
            decodeFcn = epistemic.tools.evolutionary.phenotype. ...
                decoders.EnumDecoders.infer( ...
                sourceBlockType="complex");

            testCase.verifyClass(decodeFcn, "function_handle");
        end

        function fromIntDecodesIntegerBlock(testCase)
            rng(1);

            spec = testCase.makeEnumSpec_([1 6]);

            block = epistemic.tools.evolutionary.genomes. ...
                IntegerMetagenomeBlock( ...
                nIndividuals=4, ...
                nAtoms=6, ...
                lo=-3, ...
                hi=7);

            actual = epistemic.tools.evolutionary.phenotype. ...
                decoders.EnumDecoders.fromInt(block, spec);

            values = spec.domain.values(:).';
            n = numel(values);

            G = block.asMatrix();
            idx = mod(double(G) - 1, n) + 1;
            expected = values(double(idx));

            testCase.verifyEqual(actual, expected);
        end

        function fromIntPreservesRowwiseIndividuals(testCase)
            spec = testCase.makeEnumSpec_([1 3]);

            G = [ ...
                -3 -2 -1; ...
                 0  1  2];

            lo = min(G(:));
            hi = max(G(:));

            block = epistemic.tools.evolutionary.genomes. ...
                IntegerMetagenomeBlock( ...
                nIndividuals=2, ...
                nAtoms=3, ...
                lo=lo, ...
                hi=hi, ...
                value=G);

            actual = epistemic.tools.evolutionary.phenotype. ...
                decoders.EnumDecoders.fromInt(block, spec);

            values = spec.domain.values(:).';
            n = numel(values);

            idx = mod(double(G) - 1, n) + 1;
            expected = values(double(idx));

            testCase.verifyEqual(actual, expected);
        end

        function fromRealDecodesRealBlock(testCase)
            rng(2);

            spec = testCase.makeEnumSpec_([1 5]);

            block = epistemic.tools.evolutionary.genomes. ...
                RealMetagenomeBlock( ...
                nIndividuals=3, ...
                nAtoms=5, ...
                lo=-2.0, ...
                hi=2.0);

            actual = epistemic.tools.evolutionary.phenotype. ...
                decoders.EnumDecoders.fromReal(block, spec);

            values = spec.domain.values(:).';
            n = numel(values);

            G = block.asMatrix();
            idx = mod(round(double(G)) - 1, n) + 1;
            expected = values(double(idx));

            testCase.verifyEqual(actual, expected);
        end

        function fromRealPreservesRowwiseIndividuals(testCase)
            spec = testCase.makeEnumSpec_([1 3]);

            G = [ ...
                -1.6 -0.4 0.6; ...
                 1.4  2.4 3.4];

            lo = min(G(:));
            hi = max(G(:));

            block = epistemic.tools.evolutionary.genomes. ...
                RealMetagenomeBlock( ...
                nIndividuals=2, ...
                nAtoms=3, ...
                lo=lo, ...
                hi=hi, ...
                value=G);

            actual = epistemic.tools.evolutionary.phenotype. ...
                decoders.EnumDecoders.fromReal(block, spec);

            values = spec.domain.values(:).';
            n = numel(values);

            idx = mod(round(double(G)) - 1, n) + 1;
            expected = values(double(idx));

            testCase.verifyEqual(actual, expected);
        end

        function fromComplexDecodesComplexBlock(testCase)
            spec = testCase.makeEnumSpec_([1 6]);

            G = [0.2, 0.6, 1.2, 1.6, 2.5, 3.6];

            block = epistemic.tools.evolutionary.genomes. ...
                ComplexMetagenomeBlock( ...
                nIndividuals=1, ...
                nAtoms=6, ...
                lo=0, ...
                hi=4, ...
                value=G);

            actual = epistemic.tools.evolutionary.phenotype. ...
                decoders.EnumDecoders.fromComplex(block, spec);

            values = spec.domain.values(:).';
            expected = values([4 1 1 2 3 4]);

            testCase.verifyEqual(actual, expected);
        end

        function fromComplexPreservesRowwiseIndividuals(testCase)
            spec = testCase.makeEnumSpec_([1 3]);

            G = [ ...
                0.2 * exp(1i * 0), ...
                1.2 * exp(1i * pi / 2), ...
                2.6 * exp(1i * pi); ...
                3.6 * exp(1i * pi / 4), ...
                0.6 * exp(1i * pi / 3), ...
                1.6 * exp(1i * 3 * pi / 2)];

            block = epistemic.tools.evolutionary.genomes. ...
                ComplexMetagenomeBlock( ...
                nIndividuals=2, ...
                nAtoms=3, ...
                lo=0, ...
                hi=4, ...
                value=G);

            actual = epistemic.tools.evolutionary.phenotype. ...
                decoders.EnumDecoders.fromComplex(block, spec);

            values = spec.domain.values(:).';
            n = numel(values);

            idx = mod(round(abs(G)) - 1, n) + 1;
            expected = values(double(idx));

            testCase.verifyEqual(actual, expected);
        end

        function fromBoolMapsToFirstTwoEnumValues(testCase)
            spec = testCase.makeEnumSpec_([1 4]);

            blockFalse = epistemic.tools.evolutionary.genomes. ...
                BooleanMetagenomeBlock( ...
                nIndividuals=3, ...
                nAtoms=4, ...
                value=false);

            blockTrue = epistemic.tools.evolutionary.genomes. ...
                BooleanMetagenomeBlock( ...
                nIndividuals=3, ...
                nAtoms=4, ...
                value=true);

            actualFalse = epistemic.tools.evolutionary.phenotype. ...
                decoders.EnumDecoders.fromBool(blockFalse, spec);

            actualTrue = epistemic.tools.evolutionary.phenotype. ...
                decoders.EnumDecoders.fromBool(blockTrue, spec);

            values = spec.domain.values(:).';

            expectedFalse = repmat(values(1), 3, 4);
            expectedTrue = repmat(values(2), 3, 4);

            testCase.verifyEqual(actualFalse, expectedFalse);
            testCase.verifyEqual(actualTrue, expectedTrue);
        end

        function fromPermAppliesPermutation(testCase)
            spec = testCase.makeEnumSpec_([1 3]);

            V = [3 1 2; 2 3 1];

            block = epistemic.tools.evolutionary.genomes. ...
                PermutationMetagenomeBlock( ...
                nIndividuals=2, ...
                nAtoms=3, ...
                value=V);

            actual = epistemic.tools.evolutionary.phenotype. ...
                decoders.EnumDecoders.fromPerm(block, spec);

            values = spec.domain.values(:).';
            n = numel(values);

            perm = mod(double(V) - 1, n) + 1;
            expected = values(double(perm));

            testCase.verifyEqual(actual, expected);
        end

        function fromIntWrapsNegativeGenes(testCase)
            spec = testCase.makeEnumSpec_([1 5]);

            G = [-3 -2 -1 0 1];

            lo = min(G(:));
            hi = max(G(:));

            block = epistemic.tools.evolutionary.genomes. ...
                IntegerMetagenomeBlock( ...
                nIndividuals=1, ...
                nAtoms=5, ...
                lo=lo, ...
                hi=hi, ...
                value=G);

            actual = epistemic.tools.evolutionary.phenotype. ...
                decoders.EnumDecoders.fromInt(block, spec);

            values = spec.domain.values(:).';
            expected = values([1 2 3 4 1]);

            testCase.verifyEqual(actual, expected);
        end

        function fromIntFoldsRepeatedCyclesWithZeroCrossing(testCase)
            spec = testCase.makeEnumSpec_([1 12]);

            G = -3:8;

            lo = min(G(:));
            hi = max(G(:));

            block = epistemic.tools.evolutionary.genomes. ...
                IntegerMetagenomeBlock( ...
                nIndividuals=1, ...
                nAtoms=12, ...
                lo=lo, ...
                hi=hi, ...
                value=G);

            actual = epistemic.tools.evolutionary.phenotype. ...
                decoders.EnumDecoders.fromInt(block, spec);

            values = spec.domain.values(:).';
            expected = repmat(values, 1, 3);

            testCase.verifyEqual(actual, expected);
        end

        function fromRealRoundsThenWrapsNegativeGenes(testCase)
            spec = testCase.makeEnumSpec_([1 6]);

            G = [-1.6 -1.5 -1.4 0.4 0.5 0.6];

            lo = min(G(:));
            hi = max(G(:));

            block = epistemic.tools.evolutionary.genomes. ...
                RealMetagenomeBlock( ...
                nIndividuals=1, ...
                nAtoms=6, ...
                lo=lo, ...
                hi=hi, ...
                value=G);

            actual = epistemic.tools.evolutionary.phenotype. ...
                decoders.EnumDecoders.fromReal(block, spec);

            actual = actual(:).';

            values = spec.domain.values(:).';
            expected = values([2 2 3 4 1 1]);

            testCase.verifyEqual(actual, expected);
        end

    end

    methods (Access = private)

        function spec = makeEnumSpec_(~, shape)
            spec = struct();
            spec.shape = shape;
            spec.domain = struct();

            vals = enumeration( ...
                "epistemic.tools.evolutionary.phenotype." + ...
                "PhenotypeParameterKind");

            spec.domain.values = vals(1:4);
        end

    end

end