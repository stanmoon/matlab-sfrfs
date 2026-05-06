classdef TestPhenotypeParametersDescriptorValidator < matlab.unittest.TestCase
% TestPhenotypeParametersDescriptorValidator
%
% Unit tests for internal validator:
%   epistemic.tools.evolutionary.internal.PhenotypeParametersDescriptorValidator

    methods (Test)

        function testMustBeValidExpressionBadParamShape(tc)
            descMeta = tc.descMeta_();
            descriptor = tc.makeDescriptorOneParam_();

            n = 3;
            theta = struct();
            theta.p = zeros(n, 2); % wrong width for shape [1 1]

            f = @() tc.callMustBeValidExpression_( ...
                descMeta, descriptor, theta, n);
            tc.assertThrowsAny_(f);
        end

        function testMustBeDescriptorBadType(tc)
            descMeta = tc.descMeta_();

            f = @() tc.callMustBeDescriptor_(descMeta, struct());
            tc.assertThrowsAny_(f);
        end

        function testMustBeDescriptorNonScalar(tc)
            descMeta = tc.descMeta_();

            d = epistemic.tools.evolutionary.phenotype. ...
                PhenotypeParametersDescriptor();

            dArr = repmat(d, 1, 2); % force non-scalar of correct class

            f = @() tc.callMustBeDescriptor_(descMeta, dArr);
            tc.assertThrowsAny_(f);
        end

        function testMustMatchParameterNamesBadThetaType(tc)
            descMeta = tc.descMeta_();
            descriptor = tc.makeDescriptorOneParam_();

            f = @() tc.callMustMatchParameterNames_( ...
                descMeta, descriptor, 123);
            tc.assertThrowsAny_(f);
        end

        function testMustMatchParameterNamesMissingParam(tc)
            descMeta = tc.descMeta_();
            descriptor = tc.makeDescriptorOneParam_();

            theta = struct(); % missing expected field(s)
            f = @() tc.callMustMatchParameterNames_( ...
                descMeta, descriptor, theta);
            tc.assertThrowsAny_(f);
        end

        function testMustMatchParameterNamesUnknownParam(tc)
            descMeta = tc.descMeta_();
            descriptor = tc.makeDescriptorOneParam_();

            theta = struct("p", 0, "q", 0); % extra field
            f = @() tc.callMustMatchParameterNames_( ...
                descMeta, descriptor, theta);
            tc.assertThrowsAny_(f);
        end

        function testMustBeValidExpressionBadNIndividuals(tc)
            descMeta = tc.descMeta_();
            descriptor = tc.makeDescriptorOneParam_();
            theta = tc.makeThetaOneParam_(2);

            f = @() tc.callMustBeValidExpression_( ...
                descMeta, descriptor, theta, -1);
            tc.assertThrowsAny_(f);
        end

        function testMustBeValidExpressionHappy(tc)
            descMeta = tc.descMeta_();
            descriptor = tc.makeDescriptorOneParam_();
            theta = tc.makeThetaOneParam_(3);

            tc.callMustBeValidExpression_( ...
                descMeta, descriptor, theta, 3);
        end

        function testMustHaveParamNameBadNameType(tc)
            descMeta = tc.descMeta_();
            nameMap = tc.emptyNameMap_();

            f = @() tc.callMustHaveParamName_(descMeta, nameMap, 123);
            tc.assertThrowsSuffix_(f, "BadName");
        end

        function testMustHaveParamNameEmptyName(tc)
            descMeta = tc.descMeta_();
            nameMap = tc.emptyNameMap_();

            f = @() tc.callMustHaveParamName_(descMeta, nameMap, "");
            tc.assertThrowsSuffix_(f, "BadName");
        end

        function testMustHaveParamNameUnknownName(tc)
            descMeta = tc.descMeta_();
            nameMap = tc.emptyNameMap_();
            nameMap('p') = 1;

            f = @() tc.callMustHaveParamName_(descMeta, nameMap, "q");
            tc.assertThrowsSuffix_(f, "UnknownName");
        end

        function testMustHaveParamNameHappy(tc)
            descMeta = tc.descMeta_();
            nameMap = tc.emptyNameMap_();
            nameMap('p') = 1;

            tc.callMustHaveParamName_(descMeta, nameMap, "p");
        end

        function testMustBeValidAddParamArgsBadNameType(tc)
            descMeta = tc.descMeta_();
            args = tc.baseArgs_();
            args.name = 123;

            f = @() tc.callMustBeValidAddParamArgs_(descMeta, args, false);
            tc.assertThrowsSuffix_(f, "BadName");
        end

        function testMustBeValidAddParamArgsEmptyName(tc)
            descMeta = tc.descMeta_();
            args = tc.baseArgs_();
            args.name = "";

            f = @() tc.callMustBeValidAddParamArgs_(descMeta, args, false);
            tc.assertThrowsSuffix_(f, "BadName");
        end

        function testMustBeValidAddParamArgsDuplicateName(tc)
            descMeta = tc.descMeta_();
            args = tc.baseArgs_();

            f = @() tc.callMustBeValidAddParamArgs_(descMeta, args, true);
            tc.assertThrowsSuffix_(f, "DuplicateName");
        end

        function testMustBeValidAddParamArgsBadKind(tc)
            descMeta = tc.descMeta_();
            args = tc.baseArgs_();
            args.kind = "Real";

            f = @() tc.callMustBeValidAddParamArgs_(descMeta, args, false);
            tc.assertThrowsSuffix_(f, "BadKind");
        end

        function testMustBeValidAddParamArgsBadShapeNotRow(tc)
            descMeta = tc.descMeta_();
            args = tc.baseArgs_();
            args.shape = [2; 3];

            f = @() tc.callMustBeValidAddParamArgs_(descMeta, args, false);
            tc.assertThrowsSuffix_(f, "BadShape");
        end

        function testMustBeValidAddParamArgsBadShapeEmpty(tc)
            descMeta = tc.descMeta_();
            args = tc.baseArgs_();
            args.shape = [];

            f = @() tc.callMustBeValidAddParamArgs_(descMeta, args, false);
            tc.assertThrowsSuffix_(f, "BadShape");
        end

        function testMustBeValidAddParamArgsBadShapeNonFinite(tc)
            descMeta = tc.descMeta_();
            args = tc.baseArgs_();
            args.shape = [2, Inf];

            f = @() tc.callMustBeValidAddParamArgs_(descMeta, args, false);
            tc.assertThrowsSuffix_(f, "BadShape");
        end

        function testMustBeValidAddParamArgsBadShapeNonInteger(tc)
            descMeta = tc.descMeta_();
            args = tc.baseArgs_();
            args.shape = [2.1, 3];

            f = @() tc.callMustBeValidAddParamArgs_(descMeta, args, false);
            tc.assertThrowsSuffix_(f, "BadShape");
        end

        function testMustBeValidAddParamArgsBadShapeNonPositive(tc)
            descMeta = tc.descMeta_();
            args = tc.baseArgs_();
            args.shape = [2, 0];

            f = @() tc.callMustBeValidAddParamArgs_(descMeta, args, false);
            tc.assertThrowsSuffix_(f, "BadShape");
        end

        function testEnumMissingValues(tc)
            import epistemic.tools.evolutionary.phenotype.PhenotypeParameterKind

            descMeta = tc.descMeta_();
            args = tc.baseArgs_();
            args.kind = PhenotypeParameterKind.Enum;
            args.values = string.empty(1, 0);

            f = @() tc.callMustBeValidAddParamArgs_(descMeta, args, false);
            tc.assertThrowsSuffix_(f, "EnumMissingValues");
        end

        function testEnumBadValuesType(tc)
            import epistemic.tools.evolutionary.phenotype.PhenotypeParameterKind

            descMeta = tc.descMeta_();
            args = tc.baseArgs_();
            args.kind = PhenotypeParameterKind.Enum;
            args.values = {'a','b'};

            f = @() tc.callMustBeValidAddParamArgs_(descMeta, args, false);
            tc.assertThrowsSuffix_(f, "EnumBadValues");
        end

        function testPermBadN(tc)
            import epistemic.tools.evolutionary.phenotype.PhenotypeParameterKind

            descMeta = tc.descMeta_();
            args = tc.baseArgs_();
            args.kind = PhenotypeParameterKind.Perm;
            args.n = 0;

            f = @() tc.callMustBeValidAddParamArgs_(descMeta, args, false);
            tc.assertThrowsSuffix_(f, "BadPermN");
        end

        function testResolveBoundsBadType(tc)
            import epistemic.tools.evolutionary.phenotype.PhenotypeParameterKind

            descMeta = tc.descMeta_();
            args = tc.baseArgs_();
            args.kind = PhenotypeParameterKind.Real;
            args.shape = [2, 2];
            args.lo = "nope";
            args.hi = 1;

            f = @() tc.callBuildDomain_(descMeta, args);
            tc.assertThrowsSuffix_(f, "BoundsType");
        end

        function testResolveBoundsBadShape(tc)
            import epistemic.tools.evolutionary.phenotype.PhenotypeParameterKind

            descMeta = tc.descMeta_();
            args = tc.baseArgs_();
            args.kind = PhenotypeParameterKind.Real;
            args.shape = [2, 2];
            args.lo = zeros(1, 3);
            args.hi = 1;

            f = @() tc.callBuildDomain_(descMeta, args);
            tc.assertThrowsSuffix_(f, "BoundsShape");
        end

        function testResolveBoundsScalarLoGtHi(tc)
            import epistemic.tools.evolutionary.phenotype.PhenotypeParameterKind

            descMeta = tc.descMeta_();
            args = tc.baseArgs_();
            args.kind = PhenotypeParameterKind.Real;
            args.lo = 2;
            args.hi = 1;

            f = @() tc.callBuildDomain_(descMeta, args);
            tc.assertThrowsSuffix_(f, "BadBounds");
        end

        function testResolveBoundsElementwiseLoGtHi(tc)
            import epistemic.tools.evolutionary.phenotype.PhenotypeParameterKind

            descMeta = tc.descMeta_();
            args = tc.baseArgs_();
            args.kind = PhenotypeParameterKind.Real;
            args.shape = [1, 3];
            args.lo = [0, 2, 0];
            args.hi = [1, 1, 1];

            f = @() tc.callBuildDomain_(descMeta, args);
            tc.assertThrowsSuffix_(f, "BadBounds");
        end

        function testBuildDomainReal(tc)
            import epistemic.tools.evolutionary.phenotype.PhenotypeParameterKind

            descMeta = tc.descMeta_();
            args = tc.baseArgs_();
            args.kind = PhenotypeParameterKind.Real;
            args.shape = [1, 3];
            args.lo = 0;
            args.hi = 1;

            domain = tc.callBuildDomain_(descMeta, args);
            tc.verifyTrue(isfield(domain, 'lo'));
            tc.verifyTrue(isfield(domain, 'hi'));
        end

        function testBuildDomainEnum(tc)
            import epistemic.tools.evolutionary.phenotype.PhenotypeParameterKind

            descMeta = tc.descMeta_();
            args = tc.baseArgs_();
            args.kind = PhenotypeParameterKind.Enum;
            args.values = ["a","b"];

            domain = tc.callBuildDomain_(descMeta, args);
            tc.verifyTrue(isfield(domain, 'values'));
        end

        function testBuildDomainPerm(tc)
            import epistemic.tools.evolutionary.phenotype.PhenotypeParameterKind

            descMeta = tc.descMeta_();
            args = tc.baseArgs_();
            args.kind = PhenotypeParameterKind.Perm;
            args.n = 5;

            domain = tc.callBuildDomain_(descMeta, args);
            tc.verifyTrue(isfield(domain, 'n'));
        end

        function testBuildDomainBool(tc)
            import epistemic.tools.evolutionary.phenotype.PhenotypeParameterKind

            descMeta = tc.descMeta_();
            args = tc.baseArgs_();
            args.kind = PhenotypeParameterKind.Bool;

            domain = tc.callBuildDomain_(descMeta, args);
            tc.verifyTrue(isstruct(domain));
        end

        function testBuildDomainCustom(tc)
            import epistemic.tools.evolutionary.phenotype.PhenotypeParameterKind

            descMeta = tc.descMeta_();
            args = tc.baseArgs_();
            args.kind = PhenotypeParameterKind.Custom;
            args.options = struct("x", 1);

            domain = tc.callBuildDomain_(descMeta, args);
            tc.verifyTrue(isfield(domain, 'options'));
        end

    end

    methods (Access = private)

        function meta = descMeta_(~)
            meta = ?epistemic.tools.evolutionary.phenotype. ...
                PhenotypeParametersDescriptor;
        end

        function map = emptyNameMap_(~)
            map = containers.Map('KeyType', 'char', 'ValueType', 'double');
        end

        function args = baseArgs_(~)
            import epistemic.tools.evolutionary.phenotype.PhenotypeParameterKind

            args = struct();
            args.name = "p";
            args.kind = PhenotypeParameterKind.Real;
            args.shape = [1, 1];

            args.lo = NaN;
            args.hi = NaN;

            args.values = string.empty(1, 0);
            args.n = 1;

            args.options = struct();
        end

        function callMustHaveParamName_(~, descMeta, map, name)
            fn = @epistemic.tools.evolutionary.internal. ...
                PhenotypeParametersDescriptorValidator.mustHaveParamName;
            fn(descMeta, map, name);
        end

        function callMustBeValidAddParamArgs_(~, descMeta, args, nameExists)
            fn = @epistemic.tools.evolutionary.internal. ...
                PhenotypeParametersDescriptorValidator.mustBeValidAddParamArgs;
            fn(descMeta, args, nameExists);
        end

        function domain = callBuildDomain_(~, descMeta, args)
            fn = @epistemic.tools.evolutionary.internal. ...
                PhenotypeParametersDescriptorValidator.buildDomain;
            domain = fn(descMeta, args);
        end

        function callMustBeDescriptor_(~, descMeta, descriptor)
            fn = @epistemic.tools.evolutionary.internal. ...
                PhenotypeParametersDescriptorValidator.mustBeDescriptor;
            fn(descMeta, descriptor);
        end

        function callMustMatchParameterNames_(~, descMeta, descriptor, theta)
            fn = @epistemic.tools.evolutionary.internal. ...
                PhenotypeParametersDescriptorValidator.mustMatchParameterNames;
            fn(descMeta, descriptor, theta);
        end

        function callMustBeValidExpression_( ...
                ~, descMeta, descriptor, theta, nIndividuals)
            fn = @epistemic.tools.evolutionary.internal. ...
                PhenotypeParametersDescriptorValidator.mustBeValidExpression;
            fn(descMeta, descriptor, theta, nIndividuals);
        end

        function assertThrowsSuffix_(tc, f, suffix)
            tc.verifyNotEmpty(suffix);

            try
                f();
                tc.verifyFail("Expected an error but none was thrown.");
            catch ME
                id = string(ME.identifier);
                tc.verifyTrue( ...
                    endsWith(id, ":" + suffix) || ...
                    endsWith(id, "_" + suffix), ...
                    "Unexpected error identifier: " + ME.identifier);
            end
        end

        function descriptor = makeDescriptorOneParam_(~)
            import epistemic.tools.evolutionary.phenotype.PhenotypeParameterKind

            descriptor = epistemic.tools.evolutionary.phenotype. ...
                PhenotypeParametersDescriptor();

            descriptor.addParam( ...
                name="p", ...
                kind=PhenotypeParameterKind.Real, ...
                shape=[1 1], ...
                lo=0, ...
                hi=1);
        end

        function theta = makeThetaOneParam_(~, nIndividuals)
            theta = struct();
            theta.p = zeros(nIndividuals, 1);
        end

        function assertThrowsAny_(tc, f)
            try
                f();
                tc.verifyFail("Expected an error but none was thrown.");
            catch
                % Intentionally accept any identifier.
            end
        end

    end

end