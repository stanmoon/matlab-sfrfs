%% install_sfrfs.m
% Script to install the SFRFS Toolbox cleanly, removing old versions

toolboxName = 'Spectral Fault Receptive Fields';
distDir = 'dist';

d = dir(fullfile(distDir, 'SFRFsToolbox_v*.mltbx'));
assert(~isempty(d), 'No release artifacts found in dist/.');

[~, i] = max([d.datenum]);
toolboxFile = fullfile(d(i).folder, d(i).name);

agreeToLicense = true;


% Uninstall any previous versions
installed = matlab.addons.installedAddons;
idx = find(strcmp(installed.Name, toolboxName));
if ~isempty(idx)
    for k = 1:numel(idx)
        disp(['Uninstalling previous version: ', ...
            installed.Name{idx(k)}, ' (', installed.Version{idx(k)}, ')']);
        matlab.addons.uninstall(...
            installed.Name{idx(k)});
    end
end

% Suppress warnings around the installation, known bug
s = warning('off', 'all');
installedInfo = matlab.addons.toolbox.installToolbox(toolboxFile, agreeToLicense);
warning(s); % restore previous warning state

disp(['Toolbox installed: ', installedInfo.Name]);
disp(['Version: ', installedInfo.Version]);
disp(['Guid: ', installedInfo.Guid]);

disp('SFRFS Toolbox installed and path updated successfully.');

% Cleanup installer log clutter (best-effort)
logFiles = { ...
    fullfile(pwd, "deploymentLog.html"), ...
    fullfile("dist", "deploymentLog.html") ...
};

for k = 1:numel(logFiles)
    if isfile(logFiles{k})
        delete(logFiles{k});
        fprintf('[install_sfrfs] Deleted log file: %s\n', f);
    end
end
