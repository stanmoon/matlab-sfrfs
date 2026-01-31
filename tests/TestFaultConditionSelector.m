classdef TestFaultConditionSelector < matlab.unittest.TestCase
    methods (Test)

        function testExtractRecordStructHappyPath(testCase)
            tbl = TestFaultConditionSelector.makeTable_();
            sel = OperatingConditionSelection(speed=10, load=2);

            [rec, idx] = FaultConditionSelector.extractRecordStruct( ...
                tbl, faultGroup=2, selection=sel);

            testCase.verifyEqual(idx, 2);

            testCase.verifyTrue(isstruct(rec));
            testCase.verifyTrue(isfield(rec, "FaultGroup"));
            testCase.verifyTrue(isfield(rec, "Speed"));
            testCase.verifyTrue(isfield(rec, "Load"));
            testCase.verifyTrue(isfield(rec, "Description"));

            testCase.verifyEqual(rec.FaultGroup, 2);
            testCase.verifyEqual(rec.Speed, 10);
            testCase.verifyEqual(rec.Load, 2);
            testCase.verifyEqual(string(rec.Description), ...
                "Inner Race Fault");
        end

        function testExtractRecordStructNoMatchThrows(testCase)
            tbl = TestFaultConditionSelector.makeTable_();
            sel = OperatingConditionSelection(speed=999, load=2);

            f = @() FaultConditionSelector.extractRecordStruct( ...
                tbl, faultGroup=2, selection=sel);

            testCase.verifyError(f, ...
                "sfrfs:tables:FaultConditionSelector:NoMatch");
        end

        function testExtractRecordStructAmbiguousMatchThrows(testCase)
            tbl = TestFaultConditionSelector.makeAmbiguousTable_();
            sel = OperatingConditionSelection(speed=10, load=2);

            f = @() FaultConditionSelector.extractRecordStruct( ...
                tbl, faultGroup=2, selection=sel);

            testCase.verifyError(f, ...
                "sfrfs:tables:FaultConditionSelector:AmbiguousMatch");
        end

        function testExtractRecordStructMissingColumnThrows(testCase)
            tbl = TestFaultConditionSelector.makeTable_();
            tbl = removevars(tbl, "Load");
            sel = OperatingConditionSelection(speed=10, load=2);

            f = @() FaultConditionSelector.extractRecordStruct( ...
                tbl, faultGroup=2, selection=sel);

            testCase.verifyError(f, ...
                "sfrfs:tables:FaultConditionSelector:MissingColumn");
        end
    end

    methods (Static, Access = private)

        function tbl = makeTable_()
            FaultGroup = [1; 2; 2];
            Speed = [10; 10; 20];
            Load = [1; 2; 2];
            Description = ["Outer Race Fault"; ...
                "Inner Race Fault"; ...
                "Inner Race Fault"];

            tbl = table(FaultGroup, Speed, Load, Description);
        end

        function tbl = makeAmbiguousTable_()
            tbl = TestFaultConditionSelector.makeTable_();
            % Add a duplicate key for (FaultGroup=2, Speed=10, Load=2).
            tbl = [tbl; tbl(2, :)];
        end
    end
end
