classdef TestOperatingConditions < matlab.unittest.TestCase
    % Test suite for OperatingConditions class.
    %
    % Covers:
    % - Construction with valid inputs
    % - Single-row input
    % - Mismatched inputs error
    % - Empty inputs returning empty table

    methods (Test)
        function testValidInputs(testCase)
            speed = [35; 37.5; 40];
            load  = [12; 11; 10];
            ocObj = OperatingConditions(speed, load);
            oc = ocObj.conditionsTable; % Extract table
            testCase.verifyEqual(height(oc), 3);
            testCase.verifyEqual(width(oc), 2);
            testCase.verifyEqual(oc.Properties.VariableNames, ...
                {'Speed', 'Load'});
            testCase.verifyEqual(oc.Speed, speed);
            testCase.verifyEqual(oc.Load, load);
        end
        
        function testSingleRow(testCase)
            speed = 42;
            load = 7;
            ocObj = OperatingConditions(speed, load);
            oc = ocObj.conditionsTable;
            
            testCase.verifyEqual(height(oc), 1);
            testCase.verifyEqual(oc.Speed, speed);
            testCase.verifyEqual(oc.Load, load);
        end
        
        function testMismatchedLengths(testCase)
            speed = [35; 37.5];
            load  = [12; 11; 10];
            testCase.verifyError(@() OperatingConditions(speed, load), ...
                'sfrfs:OperatingConditions:DimAgree');
        end
        
        function testEmptyInputs(testCase)
            speed = [];
            load  = [];
            ocObj = OperatingConditions(speed, load);
            oc = ocObj.conditionsTable;
            
            testCase.verifyEqual(height(oc), 0);
            testCase.verifyEqual(width(oc), 2);
        end
    end
end
