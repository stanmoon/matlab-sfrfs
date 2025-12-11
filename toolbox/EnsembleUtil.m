classdef EnsembleUtil
%EnsembleUtil Static utility functions for ensemble processing.
%
%   This class provides utility methods for ensemble handling.
%
%   Utility Methods:
%     appendSuffix(baseName, suffix) - Append suffix to a base name,
%       preserving the input type (char or string).
%
%     removeSuffix(nameWithSuffix, suffix) - Remove specified suffix 
%       from a name, preserving the input type and verifying presence 
%       of the suffix.
%
%   Usage:
%     To access help for each method, use:
%       help EnsembleUtil.appendSuffix
%       help EnsembleUtil.removeSuffix

    
    methods (Static)

        function outputName = appendSuffix(baseName, suffix)
        %APPENDSUFFIX Append suffix to a base name, preserving input type.
        %
        %   outputName = EnsembleUtil.appendSuffix(baseName, suffix)
        %
        % Inputs:
        %   baseName - char or string scalar
        %   suffix   - string scalar suffix to append
        %
        % Output:
        %   outputName - baseName with suffix appended, same type as input
        %
        % Example:
        %     colName = EnsembleUtil.appendSuffix(...
        %       'HorizontalAcceleration', '_FFT');
        
            arguments
                baseName {mustBeTextScalar}
                suffix (1,1) string
            end
            isCharInput = ischar(baseName);
            outputName = string(baseName) + suffix;
            if isCharInput
                outputName = char(outputName);
            end
        end

        function baseName = removeSuffix(nameWithSuffix, suffix)
        %REMOVESUFFIX Remove suffix from name if present, preserving type.
        %
        %   baseName = EnsembleUtil.removeSuffix(nameWithSuffix, suffix)
        %
        % Inputs:
        %   nameWithSuffix - char or string scalar
        %   suffix         - string scalar suffix to remove
        %
        % Output:
        %   baseName - nameWithSuffix without trailing suffix
        %
        % Example:
        %     baseName = EnsembleUtil.removeSuffix(...
        %       'VerticalAcceleration_FFT', '_FFT');
            arguments
                nameWithSuffix {mustBeTextScalar}
                suffix (1,1) string
            end
            isCharInput = ischar(nameWithSuffix);
            nameStr = string(nameWithSuffix);
            if endsWith(nameStr, suffix)
                suffixLength = strlength(suffix);
                baseName = extractBefore(...
                    nameStr, strlength(nameStr) - suffixLength + 1);
            else
                errorId = 'sfrfs:EnsembleUtil:InvalidSuffix';
                error(...
                    errorId, ...
                    '"%s" does not end with the expected suffix "%s".', ...
                    nameWithSuffix, ...
                    suffix);
            end
            if isCharInput
                baseName = char(baseName);
            end
        end
    end
end
