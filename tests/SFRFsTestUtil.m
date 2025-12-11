classdef SFRFsTestUtil
    %TESTUTIL Utility class for test-related helper functions
    %   Provides static methods for displaying or processing test results.

    methods (Static)
        function printTestSummary(testResults, maxNameLength)
            %PRINTTESTSUMMARY Display compact summary of TestResult array.
            % Automatically truncates long test names with '...' without 
            % breaking alignment.
            
            arguments
                testResults (:,1) matlab.unittest.TestResult
                maxNameLength (1,1) double = 60
            end

            n = numel(testResults);

            % Header
            fprintf(['%-' num2str(maxNameLength) 's | %s\n'], ...
                'Test Name', 'Result');
            % +9 accounts for " | Result" length
            fprintf('%s\n', repmat('-',1,maxNameLength+9)); 

            % Rows
            for i = 1:n
                nameStr = string(testResults(i).Name);

                % Determine overall result
                if testResults(i).Failed > 0
                    status = "Failed";
                elseif testResults(i).Incomplete > 0
                    status = "Incomplete";
                else
                    status = "Passed";
                end

                % Truncate if needed
                dotStr = "";
                if strlength(nameStr) > maxNameLength
                    dotStr = "...";
                    nameStr = extractBefore(...
                        nameStr, maxNameLength - strlength(dotStr) + 1);
                end

                % Print row
                fprintf(['%-' num2str(maxNameLength) 's | %s\n'], ...
                    nameStr + dotStr, status);
            end
            fprintf('\n');
        end
    end
end
