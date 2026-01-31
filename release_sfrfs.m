% release_sfrfs.m
% Build a versioned release artifact and release notes into dist/.

prjFile = 'sfrfs-toolbox.prj';
distDir = 'dist';

assert(isfile(prjFile), 'Project file not found: %s', prjFile);
if ~exist(distDir, 'dir'); mkdir(distDir); end

% Release notes template
templateRN = fullfile( ...
    'resources', 'templates', 'SFRFsToolboxReleaseNotes.md');
assert(isfile(templateRN), ...
    'Release notes template not found: %s', templateRN);

% Ask for version
v = strtrim(input('Enter release version (X.Y.Z): ', 's'));
assert(~isempty(regexp(v, '^\d+\.\d+\.\d+$', 'once')), ...
    'Version must be semantic: X.Y.Z (e.g., 1.0.0).');

% Targets
releaseName = sprintf('SFRFsToolbox_v%s.mltbx', v);
releaseFile = fullfile(distDir, releaseName);

rnName = sprintf('SFRFsToolbox_v%s_ReleaseNotes.md', v);
releaseNotesFile = fullfile(distDir, rnName);

% Overwrite handling
% Policy: never overwrite existing release notes (they may have been edited).
% Only the toolbox artifact may be overwritten, with explicit confirmation.

if isfile(releaseFile)
    reply = lower(strtrim(input( ...
        'Release artifact exists. Overwrite artifact? [y/N]: ', 's')));
    if ~ismember(reply, ["y","yes"])
        fprintf('Release cancelled.');
        return;
    end
    delete(releaseFile);
end

keepReleaseNotes = isfile(releaseNotesFile);
if keepReleaseNotes
    fprintf('Keeping existing release notes (will not overwrite):  %s', ...
        releaseNotesFile);
end

% Package directly to the versioned artifact (single-file policy)
matlab.addons.toolbox.packageToolbox(prjFile, releaseFile);

% Create release notes from template (only if missing)
if ~keepReleaseNotes
    txt = fileread(templateRN);
    txt = strrep(txt, '@version', v);
    txt = strrep(txt, '@date', ...
        string(datetime('today', 'Format', 'yyyy-MM-dd')));

    fid = fopen(releaseNotesFile, 'w');
    assert(fid ~= -1, 'Could not write: %s', releaseNotesFile);
    cleanup = onCleanup(@() fclose(fid));
    fwrite(fid, txt);
end

% Refresh MATLAB Project view (dev-only workaround)
if exist('projectPoke', 'file') == 2
    projectPoke(distDir);
end

fprintf('Built release artifact:\n  %s\n', releaseFile);
if ~keepReleaseNotes
    fprintf('Created release notes:\n  %s\n', releaseNotesFile);
else
    fprintf(['Release notes already existed (kept as-is):\n' ...
        '  %s\n'], releaseNotesFile);
end

