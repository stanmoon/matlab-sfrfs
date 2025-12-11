installed = matlab.addons.installedAddons;
if isempty(installed)
    disp('No add-ons or toolboxes are installed.');
    return
end

toolboxName = 'Spectral Fault Receptive Fields';
isSFRFS = strcmp(installed.Name, toolboxName);

if any(isSFRFS)
    % Select the toolbox to uninstall
    toolboxToUninstall = installed(isSFRFS, :);
    % Uninstall using the identifier (most robust)
    
    matlab.addons.uninstall(string(toolboxToUninstall.Identifier), ...
        string(toolboxToUninstall.Version));
    disp(['Uninstalled toolbox: ', toolboxName]);
else
    disp(['Toolbox "', toolboxName, '" not found.']);
end
