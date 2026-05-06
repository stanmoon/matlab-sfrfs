classdef TestMetagenomeValidator < matlab.unittest.TestCase
% TestMetagenomeValidator
% Unit tests for
%   epistemic.tools.evolutionary.internal.MetagenomeValidator
%
% Scope:
%   - Metagenome-specific validation only.
%   - Generic validation is covered by ValidationUtils tests.

    properties (Constant, Access = private)
        ClassName = "MetagenomeValidator"
    end

    methods (Test)

        function testMustBeMutuallyExclusiveAcceptsEitherEmpty(~)
            v = epistemic.tools.evolutionary.internal.MetagenomeValidator;

            v.mustBeMutuallyExclusive("a", [], "b", []);
            v.mustBeMutuallyExclusive("a", 1, "b", []);
            v.mustBeMutuallyExclusive("a", [], "b", 2);
        end

        function testMustBeMutuallyExclusiveThrowsOnBothPresent(testCase)
            v = epistemic.tools.evolutionary.internal.MetagenomeValidator;

            f = @() v.mustBeMutuallyExclusive("a", 1, "b", 2);

            testCase.verifyError( ...
                f, ...
                testCase.id_("AmbiguousInit"));
        end

    end

    methods (Access = private)

        function id = id_(testCase, suffix)
            id = "sfrfs:" + testCase.ClassName + ":" + suffix;
            id = char(id);
        end

    end
end
