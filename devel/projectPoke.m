function projectPoke(folder)
%PROJECTPOKE Force MATLAB Project view to rescan a folder.
%
%   PROJECTPOKE(FOLDER) creates and immediately deletes a temporary file in
%   FOLDER to trigger a refresh of the MATLAB Project view.
%
%   This is a workaround for cases where filesystem operations (e.g. 
%   movefile, delete, packageToolbox) update files on disk but the Project 
%   panel does not immediately reflect those changes.
%
%   Example:
%       projectPoke("dist")

    arguments
        folder (1,1) string
    end
    
    if ~isfolder(folder)
        error('Folder does not exist: %s', folder);
    end
    
    tmpFile = fullfile(folder, '.project_refresh');
    
    fid = fopen(tmpFile, 'w');
    if fid == -1
        warning('projectPoke:IO', ...
            'Could not create refresh file in: %s', folder);
        return;
    end
    
    fclose(fid);
    delete(tmpFile);

end
