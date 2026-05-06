classdef TestPhenotypeParameterValidator < matlab.unittest.TestCase
% TestPhenotypeParameterValidator
% Unit tests for
%   epistemic.tools.evolutionary.internal.PhenotypeParameterValidator

    properties (Constant, Access = private)
        ClassName = "PhenotypeParameterValidator"
    end

    methods (Test)

        function testShapeMismatch(testCase)
            kind = testCase.kindReal_();
            spec = struct();
            spec.name = "x";
            spec.kind = kind;
            spec.shape = [1 3];
            spec.domain = struct("lo", 0, "hi", 1);

            v = rand(5, 2);
            f = testCase.fcn_();

            testCase.verifyError( ...
                @() f(spec, v, 5), ...
                "sfrfs:PhenotypeParameterValidator:ShapeMismatch");
        end

        function testBadNIndividuals(testCase)
            kind = testCase.kindReal_();
            spec = struct();
            spec.name = "x";
            spec.kind = kind;
            spec.shape = [1 2];
            spec.domain = struct("lo", 0, "hi", 1);

            v = rand(3, 2);
            f = testCase.fcn_();

            testCase.verifyError( ...
                @() f(spec, v, 3.5), ...
                "sfrfs:PhenotypeParameterValidator:BadScalar");
        end

        function testOutOfBoundsReal(testCase)
            kind = testCase.kindReal_();
            spec = struct();
            spec.name = "x";
            spec.kind = kind;
            spec.shape = [1 2];
            spec.domain = struct("lo", 0, "hi", 1);

            v = [-0.1 0.5];
            f = testCase.fcn_();

            testCase.verifyError( ...
                @() f(spec, v, 1), ...
                "sfrfs:PhenotypeParameterValidator:OutOfBounds");
        end

        function testEnumBadType(testCase)
            kind = testCase.kindEnum_();
            spec = struct();
            spec.name = "e";
            spec.kind = kind;
            spec.shape = [1 2];
            spec.domain = struct("values", ["a" "b"]);

            v = [1 2];
            f = testCase.fcn_();

            testCase.verifyError( ...
                @() f(spec, v, 1), ...
                "sfrfs:PhenotypeParameterValidator:EnumType");
        end

        function testEnumMissingValues(testCase)
            spec = struct( ...
                "name", "e", ...
                "kind", testCase.kindEnum_(), ...
                "shape", [1 1], ...
                "domain", struct());

            v = "a";
            f = testCase.fcn_();

            testCase.verifyError( ...
                @() f(spec, v, 1), ...
                "sfrfs:PhenotypeParameterValidator:EnumMissingValues");
        end

        function testPermRangeViolation(testCase)
            kind = testCase.kindPerm_();
            spec = testCase.specPerm_(kind, 4);

            v = [1 2 3 5];
            f = testCase.fcn_();

            testCase.verifyError( ...
                @() f(spec, v, 1), ...
                "sfrfs:PhenotypeParameterValidator:PermRange");
        end

        function testCustomKindPassThrough(testCase)
            spec = struct( ...
                "name", "c", ...
                "kind", testCase.kindCustom_(), ...
                "shape", [1 3], ...
                "domain", struct());

            v = rand(2, 3);
            f = testCase.fcn_();

            f(spec, v, 2);
            testCase.verifyTrue(true);
        end

        function testPermWidthMismatch(testCase)
            kind = testCase.kindPerm_();
        
            % Deliberately inconsistent spec:
            % shape allows 3 columns but permutation domain requires 4.
            spec = struct();
            spec.name = "p";
            spec.kind = kind;
            spec.shape = [1 3];
            spec.domain = struct("n", 4);
        
            v = [1 2 3];
        
            f = testCase.fcn_();
        
            testCase.verifyError( ...
                @() f(spec, v, 1), ...
                testCase.id_("PermWidth"));
        end

        function testRealHappyPath(testCase)
            kind = testCase.kindReal_();
            spec = testCase.specReal_(kind);
            v = rand(3, 6);

            f = testCase.fcn_();
            f(spec, v, 3);
        end

        function testIntNonIntegerFails(testCase)
            kind = testCase.kindInt_();
            spec = testCase.specInt_(kind);
            v = rand(2, 4);

            f = testCase.fcn_();
            testCase.verifyError( ...
                @() f(spec, v, 2), ...
                testCase.id_("NonInteger"));
        end

        function testBoolNumericHappyPath(testCase)
            kind = testCase.kindBool_();
            spec = testCase.specBool_(kind);
            v = double([0 1; 1 0]);

            f = testCase.fcn_();
            f(spec, v, 2);
        end

        function testBoolBadTypeFails(testCase)
            kind = testCase.kindBool_();
            spec = testCase.specBool_(kind);
            v = [2 0; 1 0];

            f = testCase.fcn_();
            testCase.verifyError( ...
                @() f(spec, v, 2), ...
                testCase.id_("BoolType"));
        end

        function testEnumInvalidFails(testCase)
            kind = testCase.kindEnum_();
            spec = testCase.specEnum_(kind);
            v = ["a" "x"; "b" "a"];

            f = testCase.fcn_();
            testCase.verifyError( ...
                @() f(spec, v, 2), ...
                testCase.id_("EnumInvalid"));
        end

        function testPermDuplicatesFails(testCase)
            kind = testCase.kindPerm_();
            spec = testCase.specPerm_(kind, 4);
            v = [1 2 2 4; 4 3 2 1];

            f = testCase.fcn_();
            testCase.verifyError( ...
                @() f(spec, v, 2), ...
                testCase.id_("PermDuplicates"));
        end

        function testShapeMismatchFails(testCase)
            kind = testCase.kindReal_();
            spec = testCase.specReal_(kind);
            v = rand(3, 5);

            f = testCase.fcn_();
            testCase.verifyError( ...
                @() f(spec, v, 3), ...
                testCase.id_("ShapeMismatch"));
        end

        function testNIndividualsBadScalarFails(testCase)
            kind = testCase.kindReal_();
            spec = testCase.specReal_(kind);
            v = rand(1, 6);

            f = testCase.fcn_();
            testCase.verifyError( ...
                @() f(spec, v, -1), ...
                testCase.id_("BadScalar"));
        end

        function testEnumBadTypeFails(testCase)
            kind = testCase.kindEnum_();
            spec = testCase.specEnum_(kind);
            v = [1 2];

            f = testCase.fcn_();
            testCase.verifyError( ...
                @() f(spec, v, 1), ...
                testCase.id_("EnumType"));
        end

    end

    methods (Access = private)

        function f = fcn_(~)
            f = ...
                @epistemic.tools.evolutionary.internal. ...
                PhenotypeParameterValidator.mustBeValidValue;
        end

        function id = id_(testCase, suffix)
            id = "sfrfs:" + testCase.ClassName + ":" + suffix;
            id = char(id);
        end

        function kind = kindReal_(~)
            kind = ...
                epistemic.tools.evolutionary.phenotype. ...
                PhenotypeParameterKind.Real;
        end

        function kind = kindInt_(~)
            kind = ...
                epistemic.tools.evolutionary.phenotype. ...
                PhenotypeParameterKind.Int;
        end

        function kind = kindBool_(~)
            kind = ...
                epistemic.tools.evolutionary.phenotype. ...
                PhenotypeParameterKind.Bool;
        end

        function kind = kindEnum_(~)
            kind = ...
                epistemic.tools.evolutionary.phenotype. ...
                PhenotypeParameterKind.Enum;
        end

        function kind = kindPerm_(~)
            kind = ...
                epistemic.tools.evolutionary.phenotype. ...
                PhenotypeParameterKind.Perm;
        end

        function kind = kindCustom_(~)
            kind = ...
                epistemic.tools.evolutionary.phenotype. ...
                PhenotypeParameterKind.Custom;
        end

        function spec = specReal_(~, kind)
            spec = struct();
            spec.name = "x";
            spec.kind = kind;
            spec.shape = [2 3];
            spec.domain = struct("lo", 0, "hi", 1);
        end

        function spec = specInt_(~, kind)
            spec = struct();
            spec.name = "k";
            spec.kind = kind;
            spec.shape = [1 4];
            spec.domain = struct("lo", 0, "hi", 10);
        end

        function spec = specBool_(~, kind)
            spec = struct();
            spec.name = "b";
            spec.kind = kind;
            spec.shape = [1 2];
            spec.domain = struct();
        end

        function spec = specEnum_(~, kind)
            spec = struct();
            spec.name = "e";
            spec.kind = kind;
            spec.shape = [1 2];
            spec.domain = struct("values", ["a" "b"]);
        end

        function spec = specPerm_(~, kind, n)
            spec = struct();
            spec.name = "p";
            spec.kind = kind;
            spec.shape = [1 n];
            spec.domain = struct("n", n);
        end

    end
end