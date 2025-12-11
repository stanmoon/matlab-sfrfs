function ensemble = getXJTUSYEnsemble(outputFolder)
%GETXJTUSYENSEMBLE Reference a fileEnsembleDatastore from member .mat 
% files.
%
%   ensemble = GETXJTUSYENSEMBLE() prompts the user to select a folder.
%   ensemble = GETXJTUSYENSEMBLE(outputFolder) uses the specified folder.
%
%   Input (optional):
%     outputFolder - String or character vector specifying the path to the
%                    folder containing the ensemble member .mat files.
%                    If omitted or empty, a GUI dialog opens for selection.
%
%   Output:
%     ensemble     - A fileEnsembleDatastore object configured with the
%                    appropriate variable names and read/write functions.
%
%   Example:
%     % Load an existing ensemble from a folder selected via GUI
%     ensemble = getXJTUSYEnsemble();
%     tbl = readall(ensemble);
%     head(tbl)
%
%   See also: createXJTUSYEnsemble, fileEnsembleDatastore

    % Handle optional input
    if nargin < 1 || isempty(outputFolder)
        outputFolder = uigetdir(...
            '', 'Select folder containing ensemble .mat files');
        if outputFolder == 0
            error('sfrfs:data:getXJTUSYEnsemble:NoFolderSelected', ...
                'No folder selected.');
        end
        outputFolder = string(outputFolder);
    else
        outputFolder = string(outputFolder);
        mustBeFolder(outputFolder); % Validate input is a folder
    end

    % Define your variable names (should match those used in creation)
    dataVariables = ["HorizontalAcceleration", "VerticalAcceleration"];
    independentVariables = ["Label", "SnapshotIndex"];
    conditionVariables = ["Speed", "Load", "Lifetime"];
    allVars = [independentVariables, conditionVariables, dataVariables];

    % Set up the data store
    ensemble = fileEnsembleDatastore(outputFolder, '.mat');
    ensemble.ReadFcn = @readMember;
    ensemble.WriteToMemberFcn = @writeMember;
    ensemble.DataVariables = dataVariables;
    ensemble.IndependentVariables = independentVariables;
    ensemble.ConditionVariables = conditionVariables;
    ensemble.SelectedVariables = allVars;
end

function mustBeFolder(f)
    if ~isfolder(f)
        error('sfrfs:data:getXJTUSYEnsemble:NotAFolder', ...
          'The specified outputFolder does not exist or is not a folder.');
    end
end

function member = readMember(filename, selectedVariables)
    data = load(filename, 'ensembleMemberTable');
    member = data.ensembleMemberTable(:, selectedVariables);
end

function writeMember(filename, tbl)
    ensembleMemberTable = tbl; %#ok<NASGU>
    save(filename, 'ensembleMemberTable');
end
