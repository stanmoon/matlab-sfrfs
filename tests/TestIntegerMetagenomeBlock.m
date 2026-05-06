classdef TestIntegerMetagenomeBlock < matlab.unittest.TestCase

    methods (Test)

       function testDegenerateRangeCreatesConstantMatrix(testCase)
            b = epistemic.tools.evolutionary.genomes. ...
                IntegerMetagenomeBlock( ...
                nIndividuals = 3, nAtoms = 4, lo = 2, hi = 2);
        
            G = b.asMatrix();
        
            testCase.verifyEqual(G, 2 * ones(3, 4));
        end

        function testMatrixSizeAndBounds(testCase)
            b = epistemic.tools.evolutionary.genomes. ...
                IntegerMetagenomeBlock( ...
                nIndividuals = 10, nAtoms = 7, lo = -3, hi = 4);

            G = b.asMatrix();

            testCase.verifySize(G, [10, 7]);
            testCase.verifyTrue(isnumeric(G));
            testCase.verifyTrue(all(isfinite(G(:))));
            testCase.verifyTrue(all(G(:) == floor(G(:))));
            testCase.verifyGreaterThanOrEqual(min(G(:)), -3);
            testCase.verifyLessThanOrEqual(max(G(:)), 4);
        end


        function testBadRangeErrors(testCase)
            f = @() epistemic.tools.evolutionary.genomes. ...
                IntegerMetagenomeBlock( ...
                nIndividuals = 1, nAtoms = 1, lo = 2, hi = 1);

            testCase.verifyError(f, ...
                "sfrfs:IntegerMetagenomeBlock:BadRange");
        end


        function testValueOverridesGeneration(testCase)
            G0 = [-3 -2 -1; 0 1 2];

            b = epistemic.tools.evolutionary.genomes. ...
                IntegerMetagenomeBlock( ...
                nIndividuals = 2, nAtoms = 3, ...
                lo = -999, hi = 999, ... % ignored
                value = G0);

            G = b.asMatrix();

            testCase.verifyEqual(G, G0);
        end

        function testValueRejectsNonInteger(testCase)
            f = @() epistemic.tools.evolutionary.genomes. ...
                IntegerMetagenomeBlock( ...
                nIndividuals = 1, nAtoms = 2, ...
                value = [1 2.2]);
        
            testCase.verifyError(f, "sfrfs:IntegerMetagenomeBlock:BadArg");
        end
        
        function testValueRejectsNonFinite(testCase)
            f = @() epistemic.tools.evolutionary.genomes. ...
                IntegerMetagenomeBlock( ...
                nIndividuals = 1, nAtoms = 2, ...
                value = [1 NaN]);
        
            testCase.verifyError(f, "sfrfs:IntegerMetagenomeBlock:BadArg");
        end

        function testValueRejectsSizeMismatch(testCase)
            f = @() epistemic.tools.evolutionary.genomes. ...
                IntegerMetagenomeBlock( ...
                nIndividuals = 2, nAtoms = 3, ...
                value = zeros(2, 2));

            testCase.verifyError(f, ...
                "sfrfs:IntegerMetagenomeBlock:BadArg");
        end

        function testStoresDeclaredDomain(testCase)
            b = epistemic.tools.evolutionary.genomes. ...
                IntegerMetagenomeBlock( ...
                nIndividuals = 3, nAtoms = 4, lo = -2, hi = 7);
        
            testCase.verifyEqual(b.lo, -2);
            testCase.verifyEqual(b.hi, 7);
        end
        
        function testStoresDeclaredDomainWhenValueProvided(testCase)
            G0 = [-3 -2 -1; 0 1 2];
        
            b = epistemic.tools.evolutionary.genomes. ...
                IntegerMetagenomeBlock( ...
                nIndividuals = 2, nAtoms = 3, ...
                lo = -999, hi = 999, ...
                value = G0);
        
            testCase.verifyEqual(b.asMatrix(), G0);
            testCase.verifyEqual(b.lo, -999);
            testCase.verifyEqual(b.hi, 999);
        end

    end

end