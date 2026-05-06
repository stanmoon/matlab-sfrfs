classdef TestBoolDecoders < matlab.unittest.TestCase
% TestBoolDecoders
%
% Unit tests for phenotype.decoders.BoolDecoders.

    methods (Test)

        function inferReturnsFcnForBool(testCase)
            import epistemic.tools.evolutionary.phenotype.decoders.BoolDecoders

            decodeFcn = BoolDecoders.infer( ...
                sourceBlockType="bool");

            testCase.verifyClass(decodeFcn, "function_handle");

            block = [true; false; true];
            spec = struct();

            value = decodeFcn(block, spec);

            testCase.verifyClass(value, "logical");
            testCase.verifyEqual(value, logical(block));
        end


        function inferReturnsFcnForInt(testCase)
            import epistemic.tools.evolutionary.phenotype.decoders.BoolDecoders

            decodeFcn = BoolDecoders.infer( ...
                sourceBlockType="int");

            block = int32([0; 1; -2; 0]);
            spec = struct();

            value = decodeFcn(block, spec);

            testCase.verifyClass(value, "logical");
            testCase.verifyEqual(value, logical(block));
        end


        function inferReturnsFcnForReal(testCase)
            import epistemic.tools.evolutionary.phenotype.decoders.BoolDecoders

            decodeFcn = BoolDecoders.infer( ...
                sourceBlockType="real");

            block = [0; 0.1; -3.5; 0];
            spec = struct();

            value = decodeFcn(block, spec);

            testCase.verifyClass(value, "logical");
            testCase.verifyEqual(value, logical(block));
        end


        function inferRejectsPerm(testCase)
            import epistemic.tools.evolutionary.phenotype.decoders.BoolDecoders

            testCase.verifyError( ...
                @() BoolDecoders.infer(sourceBlockType="perm"), ...
                "sfrfs:BoolDecoders:UnsupportedSourceBlockType");
        end


        function inferRejectsUnknown(testCase)
            import epistemic.tools.evolutionary.phenotype.decoders.BoolDecoders

            testCase.verifyError( ...
                @() BoolDecoders.infer(sourceBlockType="weird"), ...
                "sfrfs:BoolDecoders:UnsupportedSourceBlockType");
        end


        function decodeFcnAcceptsSpecButIgnoresIt(testCase)
            import epistemic.tools.evolutionary.phenotype.decoders.BoolDecoders

            decodeFcn = BoolDecoders.infer( ...
                sourceBlockType="real");

            block = [0; 1; 0];
            spec1 = struct("name","x");
            spec2 = struct("name","y","domain",struct());

            v1 = decodeFcn(block, spec1);
            v2 = decodeFcn(block, spec2);

            testCase.verifyEqual(v1, v2);
        end

    end
end