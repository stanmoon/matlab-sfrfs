disp('Running all SFRFs tests, this may take a few seconds...');
results = runtests('Spectral Fault Receptive Fields/tests/');

disp('All tests finished! Here is the summary:');

% Loop over all results
for k = 1:numel(results)
    if results(k).Passed
        outcome = 'PASSED';
    elseif results(k).Failed
        outcome = 'FAILED';
    elseif results(k).Incomplete
        outcome = 'INCOMPLETE';
    else
        outcome = 'UNKNOWN';
    end
    
    fprintf('%-60s : %s (%.3f sec)\n', ...
        results(k).Name, outcome, results(k).Duration);
end

% Compute totals
numPassed = sum([results.Passed]);
numFailed = sum([results.Failed]);
numIncomplete = sum([results.Incomplete]);
totalTime = sum([results.Duration]);

disp('-------');
fprintf('Totals:\n');
fprintf('   Passed     : %d\n', numPassed);
fprintf('   Failed     : %d\n', numFailed);
fprintf('   Incomplete : %d\n', numIncomplete);
fprintf('   Time       : %.3f seconds testing time\n', totalTime);
