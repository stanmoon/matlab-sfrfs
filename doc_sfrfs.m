% Export SFRFs live scripts to HTML and publish .m sources to HTML.
%
% - toolbox/doc/*.mlx      -> doc/html/...
% - toolbox/**/*.m         -> doc/html/src/...
% - tests/**/*.m           -> doc/html/tests/...
% - Fix .m hyperlinks in .mlx-exported HTML to point to src/ and tests/.

%% Paths

proj        = fileparts(mfilename('fullpath'));
srcRoot     = fullfile(proj,'toolbox','doc');   % live scripts root
htmlRoot    = fullfile(proj,'doc','html');      % main HTML docs root
srcHtmlRoot = fullfile(htmlRoot,'src');         % published toolbox sources
testsHtmlRoot = fullfile(htmlRoot,'tests');     % published test sources

% Ensure output roots exist
if ~exist(htmlRoot,'dir')
    mkdir(htmlRoot);
end
if ~exist(srcHtmlRoot,'dir')
    mkdir(srcHtmlRoot);
end
if ~exist(testsHtmlRoot,'dir')
    mkdir(testsHtmlRoot);
end

%% 1) Export .mlx live scripts to HTML

files = dir(fullfile(srcRoot,'**','*.mlx'));

for k = 1:numel(files)
    src = fullfile(files(k).folder, files(k).name);

    % Compute relative path (subfolder under toolbox/doc)
    rel = erase(files(k).folder, srcRoot);
    if isempty(rel)
        rel = '';
    else
        if startsWith(rel, filesep)
            rel = rel(2:end);
        end
    end

    outHtml = fullfile(htmlRoot, rel);

    % Ensure output folder exists
    if ~exist(outHtml,'dir')
        mkdir(outHtml);
    end

    [~, base] = fileparts(files(k).name);
    htmlFile  = fullfile(outHtml, [base '.html']);

    fprintf('MLX : %s\n', src);
    fprintf('HTML: %s\n', htmlFile);
    matlab.internal.liveeditor.openAndConvert(char(src), char(htmlFile));

    % ---------------------------------------------------------
    % Fix links to .m files in the generated HTML
    % ---------------------------------------------------------

    txt = fileread(htmlFile);

    % How many levels up from this HTML file to doc/html?
    if isempty(rel)
        up = '';              % e.g. doc/html/GettingStarted.html
    else
        nSep   = numel(strfind(rel, filesep)) + 1;
        upCell = repmat({ '..' }, 1, nSep);
        up     = strjoin(upCell, '/');
        up     = [up '/'];    % '../' or '../../'
    end

    % Prefixes for links to toolbox sources and tests
    srcPrefix   = [up 'src/'];    % e.g. 'src/' or '../src/'
    testsPrefix = [up 'tests/'];  % e.g. 'tests/' or '../tests/'

    % Find all href="...*.m" occurrences
    expr   = 'href\s*=\s*"([^"]+\.m)"';
    tokens = regexp(txt, expr, 'tokens');

    for i = 1:numel(tokens)
        orig = tokens{i}{1};     % e.g. ../../SFRFsCompute.m or
                                 %      ../../../tests/TestSFRFsCompute.m
        [~, name, ~] = fileparts(orig);

        if contains(orig, 'tests/')
            newHref = ['href="' testsPrefix name '.html"'];
        else
            newHref = ['href="' srcPrefix name '.html"'];
        end

        % Replace both href = "orig" and href="orig"
        txt = strrep(txt, ['href = "' orig '"'], newHref);
        txt = strrep(txt, ['href="'  orig '"'], newHref);
    end

    fid = fopen(htmlFile,'w');
    fwrite(fid, txt, 'char');
    fclose(fid);
end

%% 2) Publish toolbox .m sources to HTML (doc/html/src/...)

toolboxRoot = fullfile(proj,'toolbox');

opts          = struct;
opts.format   = 'html';
opts.evalCode = false;   % do not execute any code
opts.showCode = true;    % show source in the HTML

mfilesToolbox = dir(fullfile(toolboxRoot,'**','*.m'));

for k = 1:numel(mfilesToolbox)
    srcM = fullfile(mfilesToolbox(k).folder, mfilesToolbox(k).name);

    % Relative folder under toolbox
    relM = erase(mfilesToolbox(k).folder, toolboxRoot);
    if isempty(relM)
        relM = '';
    else
        if startsWith(relM, filesep)
            relM = relM(2:end);
        end
    end

    destDir = fullfile(srcHtmlRoot, relM);
    if ~exist(destDir,'dir')
        mkdir(destDir);
    end

    opts.outputDir = destDir;

    fprintf('SRC (toolbox): %s\n', srcM);
    publish(char(srcM), opts);
end

%% 3) Publish tests .m sources to HTML (doc/html/tests/...)

testsRoot = fullfile(proj,'tests');

if exist(testsRoot,'dir')
    mfilesTests = dir(fullfile(testsRoot,'**','*.m'));

    for k = 1:numel(mfilesTests)
        srcM = fullfile(mfilesTests(k).folder, mfilesTests(k).name);

        % Relative folder under tests
        relT = erase(mfilesTests(k).folder, testsRoot);
        if isempty(relT)
            relT = '';
        else
            if startsWith(relT, filesep)
                relT = relT(2:end);
            end
        end

        destDir = fullfile(testsHtmlRoot, relT);
        if ~exist(destDir,'dir')
            mkdir(destDir);
        end

        opts.outputDir = destDir;

        fprintf('SRC (tests)  : %s\n', srcM);
        publish(char(srcM), opts);
    end
end

fprintf('Export completed.\n');
