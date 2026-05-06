classdef TestPhenotypeParameterSpecUtils < matlab.unittest.TestCase
% TestPhenotypeParameterSpecUtils
% Unit tests for
%   epistemic.tools.evolutionary.internal.PhenotypeParameterSpecUtils

    properties (Constant, Access = private)
        Leaf = "PhenotypeParameterSpecUtils"
    end

    methods (Test)
        function testGetNameHappy(testCase)
            u = testCase.u_();
            meta = testCase.meta_();

            spec = struct("name", "x");
            name = u.getName(spec, meta, "BadSpec");

            testCase.verifyEqual(name, "x");
        end

        function testGetNameMissingFails(testCase)
            u = testCase.u_();
            meta = testCase.meta_();

            spec = struct();
            f = @() u.getName(spec, meta, "BadSpec");

            testCase.verifyError(f, testCase.id_("BadSpec"));
        end

        function testGetKindHappy(testCase)
            u = testCase.u_();
            meta = testCase.meta_();

            kind = ...
                epistemic.tools.evolutionary.phenotype. ...
                PhenotypeParameterKind.Real;

            spec = struct("kind", kind);
            got = u.getKind(spec, meta, "BadSpec");

            testCase.verifyEqual(got, kind);
        end

        function testGetKindMissingFails(testCase)
            u = testCase.u_();
            meta = testCase.meta_();

            spec = struct();
            f = @() u.getKind(spec, meta, "BadSpec");

            testCase.verifyError(f, testCase.id_("BadSpec"));
        end

        function testGetShapeHappy(testCase)
            u = testCase.u_();
            meta = testCase.meta_();

            spec = struct("shape", [2 3]);
            shape = u.getShape(spec, meta, "BadShape", "p");

            testCase.verifyEqual(shape, [2 3]);
        end

        function testGetShapeInvalidFails(testCase)
            u = testCase.u_();
            meta = testCase.meta_();

            spec = struct("shape", [2 0]);
            f = @() u.getShape(spec, meta, "BadShape", "p");

            testCase.verifyError(f, testCase.id_("BadShape"));
        end

        function testGetShapeMissingFails(testCase)
            u = testCase.u_();
            meta = testCase.meta_();

            spec = struct();
            f = @() u.getShape(spec, meta, "BadShape", "p");

            testCase.verifyError(f, testCase.id_("BadShape"));
        end

        function testGetDomainMissingReturnsEmptyStruct(testCase)
            u = testCase.u_();
            meta = testCase.meta_();

            spec = struct();
            d = u.getDomain(spec, meta, "BadDomain", "p");

            testCase.verifyTrue(isstruct(d));
            testCase.verifyTrue(isempty(fieldnames(d)));
        end

        function testGetDomainNonStructFails(testCase)
            u = testCase.u_();
            meta = testCase.meta_();

            spec = struct("domain", 3);
            f = @() u.getDomain(spec, meta, "BadDomain", "p");

            testCase.verifyError(f, testCase.id_("BadDomain"));
        end

        function testSpecNotScalarStructFails(testCase)
            u = testCase.u_();
            meta = testCase.meta_();

            spec = struct("name", {"a","b"});
            f = @() u.getName(spec, meta, "BadSpec");

            testCase.verifyError(f, testCase.id_("BadSpec"));
        end
    end

    methods (Access = private)
        function u = u_(~)
            u = ...
                epistemic.tools.evolutionary.internal. ...
                PhenotypeParameterSpecUtils;
        end

        function meta = meta_(~)
            meta = ?epistemic.tools.evolutionary.internal. ...
                PhenotypeParameterSpecUtils;
        end

        function id = id_(testCase, suffix)
            id = "sfrfs:" + testCase.Leaf + ":" + string(suffix);
            id = char(id);
        end
    end
end
