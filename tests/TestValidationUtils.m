classdef TestValidationUtils < matlab.unittest.TestCase
% TestValidationUtils
% Unit tests for ValidationUtils (funnel based errors).
%
% Pattern used in this file
%   We build a small dispatcher struct named "checks" that exposes the
%   static methods under test as function handles. This keeps call sites
%   short and avoids feval or string based dispatching in the tests.

    properties (Constant, Access = private)
        FQCN = ...
            "epistemic.tools.evolutionary.internal.ValidationUtils";
        Leaf = "ValidationUtils";
    end

    methods (Test)

        function testMustBePositiveScalarHappy(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();

            checks.mustBePositiveScalar(1.5, meta, "X", "msg");
        end

        function testMustBePositiveScalarFails(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();

            f1 = @() checks.mustBePositiveScalar(0, meta, "Bad", "msg");
            testCase.verifyError(f1, testCase.id_("Bad"));

            f2 = @() checks.mustBePositiveScalar(-1, meta, "Bad", "msg");
            testCase.verifyError(f2, testCase.id_("Bad"));

            f3 = @() checks.mustBePositiveScalar(NaN, meta, "Bad", "msg");
            testCase.verifyError(f3, testCase.id_("Bad"));

            f4 = @() checks.mustBePositiveScalar([1 2], meta, "Bad", ...
                "msg");
            testCase.verifyError(f4, testCase.id_("Bad"));
        end

        function testMustBeFiniteMatrixHappy(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();
        
            checks.mustBeFiniteMatrix([1 2; 3 4], meta, "X", "msg");
        end
        
        function testMustBeFiniteMatrixFails(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();
        
            f1 = @() checks.mustBeFiniteMatrix( ...
                [1 NaN], meta, "NonFinite", "msg");
            testCase.verifyError(f1, testCase.id_("NonFinite"));
        
            f2 = @() checks.mustBeFiniteMatrix( ...
                [1 + 1i, 2], meta, "Bad", "msg");
            testCase.verifyError(f2, testCase.id_("Bad"));
        
            f3 = @() checks.mustBeFiniteMatrix( ...
                cat(3, 1, 2), meta, "Bad", "msg");
            testCase.verifyError(f3, testCase.id_("Bad"));
        end

        function testMustBeMetaClassHappy(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();

            x = ?epistemic.tools.evolutionary.internal.ValidationUtils;

            checks.mustBeMetaClass(x, meta, "X", "msg");
        end

        function testMustBeMetaClassFails(testCase)
            checks = testCase.checks_();
            m = testCase.meta_();
        
            f1 = @() checks.mustBeMetaClass(123, m, "Bad", "msg");
            testCase.verifyError(f1, testCase.id_("Bad"));
        
            f2 = @() checks.mustBeMetaClass("x", m, "Bad", "msg");
            testCase.verifyError(f2, testCase.id_("Bad"));
        
            f3 = @() checks.mustBeMetaClass( ...
                meta.class.empty(1, 0), m, "Bad", "msg");
            testCase.verifyError(f3, testCase.id_("Bad"));
        end


        function testMustBeContainersMapHappy(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();

            m = containers.Map('KeyType', 'char', 'ValueType', 'double');

            checks.mustBeContainersMap(m, meta, "X", "msg");
        end

        function testMustBeContainersMapFails(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();

            f1 = @() checks.mustBeContainersMap( ...
                struct(), meta, "Bad", "msg");
            testCase.verifyError(f1, testCase.id_("Bad"));

            f2 = @() checks.mustBeContainersMap( ...
                "nope", meta, "Bad", "msg");
            testCase.verifyError(f2, testCase.id_("Bad"));
        end

        function testMustBeIndexAtMostHappy(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();

            checks.mustBeIndexAtMost( ...
                3, 3, meta, "X", "idx %d bad", {3});
        end

        function testMustBeIndexAtMostFails(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();

            f = @() checks.mustBeIndexAtMost( ...
                4, 3, meta, "TooBig", "idx %d is out of range.", {4});
            testCase.verifyError(f, testCase.id_("TooBig"));
        end

        function testMustBeIndexInRangeHappy(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();

            checks.mustBeIndexInRange(1, 3, meta, "BadIndex");
            checks.mustBeIndexInRange(3, 3, meta, "BadIndex");
        end

        function testMustBeIndexInRangeFails(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();

            f1 = @() checks.mustBeIndexInRange(0, 3, meta, "BadIndex");
            testCase.verifyError(f1, testCase.id_("BadIndex"));

            f2 = @() checks.mustBeIndexInRange(4, 3, meta, "BadIndex");
            testCase.verifyError(f2, testCase.id_("BadIndex"));
        end

        function testMustBeNonEmptyCellHappy(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();
            checks.mustBeNonEmptyCell({1}, meta, "X", "msg");
        end

        function testMustBeNonEmptyCellFails(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();
            f = @() checks.mustBeNonEmptyCell({}, meta, "Empty", "msg");
            testCase.verifyError(f, testCase.id_("Empty"));
        end

        function testMustBeFiniteNumericHappy(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();
            checks.mustBeFiniteNumeric([1 2; 3 4], meta, "X", "msg");
        end

        function testMustBeFiniteNumericFails(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();
            f = @() checks.mustBeFiniteNumeric( ...
                [1 NaN], meta, "NonFinite", "msg");
            testCase.verifyError(f, testCase.id_("NonFinite"));
        end

        function testMustBeFiniteScalarHappy(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();
            checks.mustBeFiniteScalar(3, meta, "X", "msg");
        end

        function testMustBeFiniteScalarFails(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();

            f1 = @() checks.mustBeFiniteScalar(NaN, meta, "Bad", "msg");
            testCase.verifyError(f1, testCase.id_("Bad"));

            f2 = @() checks.mustBeFiniteScalar([1 2], meta, "Bad", "msg");
            testCase.verifyError(f2, testCase.id_("Bad"));
        end

        function testMustHaveStrictOrderHappy(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();

            checks.mustHaveStrictOrder(0, 1, meta, "BadBounds", "msg");
        end

        function testMustHaveStrictOrderFailsForBadLo(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();

            f = @() checks.mustHaveStrictOrder( ...
                Inf, 1, meta, "BadBounds", "msg");
            testCase.verifyError(f, testCase.id_("BadLo"));
        end

        function testMustHaveStrictOrderFailsForBadHi(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();

            f = @() checks.mustHaveStrictOrder( ...
                0, NaN, meta, "BadBounds", "msg");
            testCase.verifyError(f, testCase.id_("BadHi"));
        end

        function testMustHaveStrictOrderFailsForEqualBounds(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();

            f = @() checks.mustHaveStrictOrder( ...
                1, 1, meta, "BadBounds", "msg");
            testCase.verifyError(f, testCase.id_("BadBounds"));
        end

        function testMustHaveStrictOrderFailsForReversedBounds(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();

            f = @() checks.mustHaveStrictOrder( ...
                2, 1, meta, "BadBounds", "msg");
            testCase.verifyError(f, testCase.id_("BadBounds"));
        end

        function testMustBeInClosedIntervalHappy(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();

            checks.mustBeInClosedInterval( ...
                [0 0.5 1], 0, 1, meta, "OutOfRange", "msg");
        end

        function testMustBeInClosedIntervalFailsForBadBounds(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();

            f1 = @() checks.mustBeInClosedInterval( ...
                0.5, Inf, 1, meta, "OutOfRange", "msg");
            testCase.verifyError(f1, testCase.id_("BadLo"));

            f2 = @() checks.mustBeInClosedInterval( ...
                0.5, 0, NaN, meta, "OutOfRange", "msg");
            testCase.verifyError(f2, testCase.id_("BadHi"));

            f3 = @() checks.mustBeInClosedInterval( ...
                0.5, 1, 1, meta, "OutOfRange", "msg");
            testCase.verifyError(f3, testCase.id_("BadBounds"));
        end

        function testMustBeInClosedIntervalFailsForBadValue(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();

            f1 = @() checks.mustBeInClosedInterval( ...
                [0 NaN], 0, 1, meta, "OutOfRange", "msg");
            testCase.verifyError(f1, testCase.id_("BadValue"));

            f2 = @() checks.mustBeInClosedInterval( ...
                [1 + 1i, 0.5], 0, 1, meta, "OutOfRange", "msg");
            testCase.verifyError(f2, testCase.id_("BadValue"));
        end

        function testMustBeInClosedIntervalFailsForOutOfRange(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();

            f1 = @() checks.mustBeInClosedInterval( ...
                [-0.1 0.5], 0, 1, meta, "OutOfRange", "msg");
            testCase.verifyError(f1, testCase.id_("OutOfRange"));

            f2 = @() checks.mustBeInClosedInterval( ...
                [0.5 1.1], 0, 1, meta, "OutOfRange", "msg");
            testCase.verifyError(f2, testCase.id_("OutOfRange"));
        end

        function testMustBeInOpenIntervalHappy(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();

            checks.mustBeInOpenInterval( ...
                [0.1 0.5 0.9], 0, 1, meta, "OutOfRange", "msg");
        end

        function testMustBeInOpenIntervalFailsForBadBounds(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();

            f1 = @() checks.mustBeInOpenInterval( ...
                0.5, Inf, 1, meta, "OutOfRange", "msg");
            testCase.verifyError(f1, testCase.id_("BadLo"));

            f2 = @() checks.mustBeInOpenInterval( ...
                0.5, 0, NaN, meta, "OutOfRange", "msg");
            testCase.verifyError(f2, testCase.id_("BadHi"));

            f3 = @() checks.mustBeInOpenInterval( ...
                0.5, 1, 1, meta, "OutOfRange", "msg");
            testCase.verifyError(f3, testCase.id_("BadBounds"));
        end

        function testMustBeInOpenIntervalFailsForBadValue(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();

            f1 = @() checks.mustBeInOpenInterval( ...
                [0 NaN], 0, 1, meta, "OutOfRange", "msg");
            testCase.verifyError(f1, testCase.id_("BadValue"));

            f2 = @() checks.mustBeInOpenInterval( ...
                [1 + 1i, 0.5], 0, 1, meta, "OutOfRange", "msg");
            testCase.verifyError(f2, testCase.id_("BadValue"));
        end

        function testMustBeInOpenIntervalFailsForBoundaryTouch(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();

            f1 = @() checks.mustBeInOpenInterval( ...
                [0 0.5], 0, 1, meta, "OutOfRange", "msg");
            testCase.verifyError(f1, testCase.id_("OutOfRange"));

            f2 = @() checks.mustBeInOpenInterval( ...
                [0.5 1], 0, 1, meta, "OutOfRange", "msg");
            testCase.verifyError(f2, testCase.id_("OutOfRange"));
        end

        function testMustBeInOpenIntervalFailsForOutOfRange(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();

            f1 = @() checks.mustBeInOpenInterval( ...
                [-0.1 0.5], 0, 1, meta, "OutOfRange", "msg");
            testCase.verifyError(f1, testCase.id_("OutOfRange"));

            f2 = @() checks.mustBeInOpenInterval( ...
                [0.5 1.1], 0, 1, meta, "OutOfRange", "msg");
            testCase.verifyError(f2, testCase.id_("OutOfRange"));
        end

        function testMustBeIntegerValuedHappy(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();
            checks.mustBeIntegerValued([1 2; 3 4], meta, "X", "msg");
        end

        function testMustBeIntegerValuedFails(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();
            f = @() checks.mustBeIntegerValued( ...
                [1 2.1], meta, "NonInteger", "msg");
            testCase.verifyError(f, testCase.id_("NonInteger"));
        end

        function testMustBeIntegerMatrixHappy(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();
            G = [1 2; 3 4];
            checks.mustBeIntegerMatrix(G, meta, "X", "msg");
        end

        function testMustBeIntegerMatrixFails(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();

            f1 = @() checks.mustBeIntegerMatrix( ...
                [1 2.2; 3 4], meta, "Bad", "msg");
            testCase.verifyError(f1, testCase.id_("Bad"));

            f2 = @() checks.mustBeIntegerMatrix( ...
                cat(3, 1, 2), meta, "Bad", "msg");
            testCase.verifyError(f2, testCase.id_("Bad"));
        end

        function testMustBeIntegerScalarHappy(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();
            checks.mustBeIntegerScalar(3, meta, "X", "msg");
        end

        function testMustBeIntegerScalarFails(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();
            f = @() checks.mustBeIntegerScalar( ...
                3.5, meta, "BadScalar", "msg");
            testCase.verifyError(f, testCase.id_("BadScalar"));
        end

        function testMustBeNonnegativeIntegerScalarHappy(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();
            checks.mustBeNonnegativeIntegerScalar(0, meta, "X", "msg");
            checks.mustBeNonnegativeIntegerScalar(7, meta, "X", "msg");
        end

        function testMustBeNonnegativeIntegerScalarFails(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();

            f1 = @() checks.mustBeNonnegativeIntegerScalar( ...
                -1, meta, "Bad", "msg");
            testCase.verifyError(f1, testCase.id_("Bad"));

            f2 = @() checks.mustBeNonnegativeIntegerScalar( ...
                1.2, meta, "Bad", "msg");
            testCase.verifyError(f2, testCase.id_("Bad"));
        end

        function testMustBeLogicalScalarHappy(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();
            checks.mustBeLogicalScalar(true, meta, "X", "msg");
            checks.mustBeLogicalScalar(false, meta, "X", "msg");
        end

        function testMustBeLogicalScalarFails(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();

            f1 = @() checks.mustBeLogicalScalar(1, meta, "Bad", "msg");
            testCase.verifyError(f1, testCase.id_("Bad"));

            f2 = @() checks.mustBeLogicalScalar( ...
                [true true], meta, "Bad", "msg");
            testCase.verifyError(f2, testCase.id_("Bad"));
        end

        function testMustBeMutuallyExclusiveHappy(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();

            checks.mustBeMutuallyExclusive([], [], meta, "X", "msg");
            checks.mustBeMutuallyExclusive(1, [], meta, "X", "msg");
            checks.mustBeMutuallyExclusive([], 1, meta, "X", "msg");
        end

        function testMustBeMutuallyExclusiveFails(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();

            f = @() checks.mustBeMutuallyExclusive( ...
                1, 2, meta, "Amb", "msg");
            testCase.verifyError(f, testCase.id_("Amb"));
        end

        function testMustHaveSizeHappy(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();
            x = zeros(2, 3);
            checks.mustHaveSize(x, 2, 3, meta, "X", "msg");
        end

        function testMustHaveSizeFails(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();
            x = zeros(2, 2);
            f = @() checks.mustHaveSize( ...
                x, 2, 3, meta, "ShapeMismatch", "msg");
            testCase.verifyError(f, testCase.id_("ShapeMismatch"));
        end

        function testMustHaveSizeBadRowsFails(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();
            x = zeros(2, 3);
            f = @() checks.mustHaveSize(x, -1, 3, meta, "X", "msg");
            testCase.verifyError(f, testCase.id_("BadRows"));
        end

        function testMustHaveSizeBadColsFails(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();
            x = zeros(2, 3);
            f = @() checks.mustHaveSize(x, 2, -1, meta, "X", "msg");
            testCase.verifyError(f, testCase.id_("BadCols"));
        end

        function testMustBeInRangeHappy(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();
            checks.mustBeInRange([0 1], 0, 1, meta, "X", "msg");
        end

        function testMustBeInRangeFails(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();
            f = @() checks.mustBeInRange( ...
                [-1 0], 0, 1, meta, "OutOfRange", "msg");
            testCase.verifyError(f, testCase.id_("OutOfRange"));
        end

        function testMustAllSatisfyHappy(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();
            xs = {1, 2, 3};
            pred = @(x) isnumeric(x) && isscalar(x) && x > 0;
            checks.mustAllSatisfy(xs, pred, meta, "X", "msg");
        end

        function testMustAllSatisfyFails(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();
            xs = {1, -2, 3};
            pred = @(x) isnumeric(x) && isscalar(x) && x > 0;

            f = @() checks.mustAllSatisfy( ...
                xs, pred, meta, "PredicateFailed", "msg");
            testCase.verifyError(f, testCase.id_("PredicateFailed"));
        end

        function testMustAllSatisfyBadInputsFails(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();
            xs = {1; 2}; % not 1 by N
            pred = @(x) true;

            f = @() checks.mustAllSatisfy( ...
                xs, pred, meta, "BadInputs", "msg");
            testCase.verifyError(f, testCase.id_("BadInputs"));
        end

        function testMustBeStringScalarHappy(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();
            checks.mustBeStringScalar("x", meta, "X", "msg");
        end

        function testMustBeStringScalarFails(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();

            f1 = @() checks.mustBeStringScalar(1, meta, "Bad", "msg");
            testCase.verifyError(f1, testCase.id_("Bad"));

            f2 = @() checks.mustBeStringScalar( ...
                ["a" "b"], meta, "Bad", "msg");
            testCase.verifyError(f2, testCase.id_("Bad"));
        end

        function testMustBeRowVectorHappy(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();
            checks.mustBeRowVector([1 2 3], meta, "X", "msg");
        end

        function testMustBeRowVectorFails(testCase)
            checks = testCase.checks_();
            meta = testCase.meta_();

            f1 = @() checks.mustBeRowVector([1; 2], meta, ...
                "BadRow", "msg");
            testCase.verifyError(f1, testCase.id_("BadRow"));

            f2 = @() checks.mustBeRowVector("nope", meta, ...
                "BadRow", "msg");
            testCase.verifyError(f2, testCase.id_("BadRow"));

            f3 = @() checks.mustBeRowVector([1 + 1i, 2], meta, ...
                "BadRow", "msg");
            testCase.verifyError(f3, testCase.id_("BadRow"));
        end

    end

    methods (Access = private)

        function checks = checks_(testCase)
            % Dispatcher mapping: one place to update if the FQCN changes.
            if testCase.FQCN == ...
                    "epistemic.tools.evolutionary.internal.ValidationUtils"

                checks = struct();

                checks.mustBeNonEmptyCell = ...
                    @epistemic.tools.evolutionary.internal. ...
                    ValidationUtils.mustBeNonEmptyCell;

                checks.mustBeFiniteNumeric = ...
                    @epistemic.tools.evolutionary.internal. ...
                    ValidationUtils.mustBeFiniteNumeric;

                checks.mustBeFiniteScalar = ...
                    @epistemic.tools.evolutionary.internal. ...
                    ValidationUtils.mustBeFiniteScalar;

                checks.mustHaveStrictOrder = ...
                    @epistemic.tools.evolutionary.internal. ...
                    ValidationUtils.mustHaveStrictOrder;

                checks.mustBeInClosedInterval = ...
                    @epistemic.tools.evolutionary.internal. ...
                    ValidationUtils.mustBeInClosedInterval;

                checks.mustBeInOpenInterval = ...
                    @epistemic.tools.evolutionary.internal. ...
                    ValidationUtils.mustBeInOpenInterval;

                checks.mustBeIntegerValued = ...
                    @epistemic.tools.evolutionary.internal. ...
                    ValidationUtils.mustBeIntegerValued;

                checks.mustBeIntegerMatrix = ...
                    @epistemic.tools.evolutionary.internal. ...
                    ValidationUtils.mustBeIntegerMatrix;

                checks.mustBeIntegerScalar = ...
                    @epistemic.tools.evolutionary.internal. ...
                    ValidationUtils.mustBeIntegerScalar;

                checks.mustBeNonnegativeIntegerScalar = ...
                    @epistemic.tools.evolutionary.internal. ...
                    ValidationUtils.mustBeNonnegativeIntegerScalar;

                checks.mustBeLogicalScalar = ...
                    @epistemic.tools.evolutionary.internal. ...
                    ValidationUtils.mustBeLogicalScalar;

                checks.mustBeMutuallyExclusive = ...
                    @epistemic.tools.evolutionary.internal. ...
                    ValidationUtils.mustBeMutuallyExclusive;

                checks.mustHaveSize = ...
                    @epistemic.tools.evolutionary.internal. ...
                    ValidationUtils.mustHaveSize;

                checks.mustBeInRange = ...
                    @epistemic.tools.evolutionary.internal. ...
                    ValidationUtils.mustBeInRange;

                checks.mustAllSatisfy = ...
                    @epistemic.tools.evolutionary.internal. ...
                    ValidationUtils.mustAllSatisfy;

                checks.mustBeStringScalar = ...
                    @epistemic.tools.evolutionary.internal. ...
                    ValidationUtils.mustBeStringScalar;

                checks.mustBeRowVector = ...
                    @epistemic.tools.evolutionary.internal. ...
                    ValidationUtils.mustBeRowVector;

                checks.mustBeMetaClass = ...
                    @epistemic.tools.evolutionary.internal. ...
                    ValidationUtils.mustBeMetaClass;

                checks.mustBeContainersMap = ...
                    @epistemic.tools.evolutionary.internal. ...
                    ValidationUtils.mustBeContainersMap;

                checks.mustBeIndexAtMost = ...
                    @epistemic.tools.evolutionary.internal. ...
                    ValidationUtils.mustBeIndexAtMost;

                checks.mustBeIndexInRange = ...
                    @epistemic.tools.evolutionary.internal. ...
                    ValidationUtils.mustBeIndexInRange;

                checks.mustBeFiniteMatrix = ...
                    @epistemic.tools.evolutionary.internal. ...
                    ValidationUtils.mustBeFiniteMatrix;

                checks.mustBePositiveScalar = ...
                    @epistemic.tools.evolutionary.internal. ...
                    ValidationUtils.mustBePositiveScalar;

                return
            end

            error("TestValidationUtils:BadFQCN", ...
                "Update FQCN and checks_() mappings.");
        end

        function meta = meta_(testCase)
            if testCase.FQCN == ...
                    "epistemic.tools.evolutionary.internal.ValidationUtils"
                meta = ?epistemic.tools.evolutionary.internal. ...
                    ValidationUtils;
                return
            end

            error("TestValidationUtils:BadFQCN", ...
                "Update FQCN and meta_().");
        end

        function id = id_(testCase, suffix)
            id = "sfrfs:" + testCase.Leaf + ":" + string(suffix);
            id = char(id);
        end

    end
end