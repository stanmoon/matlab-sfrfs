classdef TestPermDecoders < matlab.unittest.TestCase
% TestPermDecoders
%
% Unit tests for PermDecoders.
%
% Contract:
%   - Only permutation genomes are supported.
%   - Individuals are represented by rows in the source block.
%   - Output shape is [nIndividuals, p].

    methods (Test)

        function inferRejectsUnknownSourceBlockType(testCase)
            f = @() epistemic.tools.evolutionary.phenotype.decoders. ...
                PermDecoders.infer(sourceBlockType="weird");

            testCase.verifyError( ...
                f, ...
                "sfrfs:PermDecoders:UnsupportedSourceBlockType");
        end

        function inferRejectsBoolSourceBlockType(testCase)
            f = @() epistemic.tools.evolutionary.phenotype.decoders. ...
                PermDecoders.infer(sourceBlockType="bool");

            testCase.verifyError( ...
                f, ...
                "sfrfs:PermDecoders:UnsupportedSourceBlockType");
        end

        function inferRejectsIntSourceBlockType(testCase)
            f = @() epistemic.tools.evolutionary.phenotype.decoders. ...
                PermDecoders.infer(sourceBlockType="int");

            testCase.verifyError( ...
                f, ...
                "sfrfs:PermDecoders:UnsupportedSourceBlockType");
        end

        function inferRejectsRealSourceBlockType(testCase)
            f = @() epistemic.tools.evolutionary.phenotype.decoders. ...
                PermDecoders.infer(sourceBlockType="real");

            testCase.verifyError( ...
                f, ...
                "sfrfs:PermDecoders:UnsupportedSourceBlockType");
        end

        function inferRejectsComplexSourceBlockType(testCase)
            f = @() epistemic.tools.evolutionary.phenotype.decoders. ...
                PermDecoders.infer(sourceBlockType="complex");

            testCase.verifyError( ...
                f, ...
                "sfrfs:PermDecoders:UnsupportedSourceBlockType");
        end

        function inferAcceptsPermSourceBlockType(testCase)
            decodeFcn = epistemic.tools.evolutionary.phenotype. ...
                decoders.PermDecoders.infer( ...
                sourceBlockType="perm");

            testCase.verifyClass(decodeFcn, "function_handle");
        end

        function fromPermReturnsPermutationMatrix(testCase)
            spec = testCase.makePermSpec_([1 3], 3);

            G = [3 1 2; 2 3 1];

            block = epistemic.tools.evolutionary.genomes. ...
                PermutationMetagenomeBlock( ...
                nIndividuals=2, ...
                nAtoms=3, ...
                value=G);

            actual = epistemic.tools.evolutionary.phenotype. ...
                decoders.PermDecoders.fromPerm(block, spec);

            testCase.verifyEqual(actual, G);
        end

        function fromPermPreservesRowwiseIndividuals(testCase)
            spec = testCase.makePermSpec_([1 4], 4);

            G = [ ...
                1 2 3 4; ...
                4 3 2 1];

            block = epistemic.tools.evolutionary.genomes. ...
                PermutationMetagenomeBlock( ...
                nIndividuals=2, ...
                nAtoms=4, ...
                value=G);

            actual = epistemic.tools.evolutionary.phenotype. ...
                decoders.PermDecoders.fromPerm(block, spec);

            testCase.verifyEqual(actual, G);
        end

        function fromPermRejectsBadShape(testCase)
            spec = testCase.makePermSpec_([1 4], 4);

            G = [1 2 3; 3 1 2];

            block = epistemic.tools.evolutionary.genomes. ...
                PermutationMetagenomeBlock( ...
                nIndividuals=2, ...
                nAtoms=3, ...
                value=G);

            f = @() epistemic.tools.evolutionary.phenotype. ...
                decoders.PermDecoders.fromPerm(block, spec);

            testCase.verifyError(f, "sfrfs:PermDecoders:BadShape");
        end

        function fromPermRejectsShapeDomainMismatch(testCase)
            spec = testCase.makePermSpec_([1 3], 4);

            G = [1 2 3; 3 1 2];

            block = epistemic.tools.evolutionary.genomes. ...
                PermutationMetagenomeBlock( ...
                nIndividuals=2, ...
                nAtoms=3, ...
                value=G);

            f = @() epistemic.tools.evolutionary.phenotype. ...
                decoders.PermDecoders.fromPerm(block, spec);

            testCase.verifyError(f, "sfrfs:PermDecoders:BadShape");
        end

        function fromPermRejectsBlockDomainMismatch(testCase)
            spec = testCase.makePermSpec_([1 4], 4);

            G = [ ...
                1 2 3; ...
                3 1 2];

            block = epistemic.tools.evolutionary.genomes. ...
                PermutationMetagenomeBlock( ...
                nIndividuals=2, ...
                nAtoms=3, ...
                value=G);

            f = @() epistemic.tools.evolutionary.phenotype. ...
                decoders.PermDecoders.fromPerm(block, spec);

            testCase.verifyError(f, "sfrfs:PermDecoders:BadShape");
        end

        function fromPermRejectsMissingDomainN(testCase)
            spec = struct();
            spec.shape = [1 3];
            spec.domain = struct();

            G = [ ...
                1 2 3; ...
                3 1 2];

            block = epistemic.tools.evolutionary.genomes. ...
                PermutationMetagenomeBlock( ...
                nIndividuals=2, ...
                nAtoms=3, ...
                value=G);

            f = @() epistemic.tools.evolutionary.phenotype. ...
                decoders.PermDecoders.fromPerm(block, spec);

            testCase.verifyError(f, "sfrfs:PermDecoders:BadSpec");
        end

    end

    methods (Access = private)

        function spec = makePermSpec_(~, shape, n)
            spec = struct();
            spec.shape = shape;
            spec.domain = struct();
            spec.domain.n = n;
        end

    end

end