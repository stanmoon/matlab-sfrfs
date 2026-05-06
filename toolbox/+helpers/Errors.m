classdef Errors
% Errors
% Named-argument error raising with consistent error identifiers.
%
% This helper provides a single, uniform funnel for raising errors with
% identifiers of the form:
%
%   <prefix>:<ClassName>:<Suffix>
%
% where <ClassName> is obtained from class metadata.
%
% Contract
%   - classMeta is a scalar matlab.metadata.Class.
%       * Use ?MyClass when the class is known.
%       * Use metaclass(obj) when tagging errors based on an object 
%         instance.
%
%   - Exactly one of 'message' or 'format' must be provided.
%
%   - If 'format' is used, 'args' must be a cell array of sprintf 
%     arguments.
%
% Examples
%
% 1) Static class tagging:
%
%   helpers.Errors.raise( ...
%       classMeta=?epistemic.tools.evolutionary.internal.PhenotypeParameterValidator, ...
%       suffix="BadSpec", ...
%       message="Spec is missing field 'name'.");
%
%   -> Identifier: sfrfs:PhenotypeParameterValidator:BadSpec
%
% 2) Dynamic class tagging (runtime object):
%  
%   x = table();
%   helpers.Errors.raise( ...
%       classMeta=metaclass(x), ...
%       suffix="InvalidValue", ...
%       format="Value %d is out of range.", ...
%       args={v});
%
%   -> Identifier: sfrfs:<class(x)>:InvalidValue
%
% 3) Custom prefix (optional):
%
%   helpers.Errors.raise( ...
%       classMeta=?helpers.Errors, ...
%       suffix="BadArgs", ...
%       message="Provide message or format.", ...
%       prefix="sfrfs");
%
% Notes
%   - The '?' operator accepts class names only; it does not evaluate
%     variables. To obtain metadata from a value, use metaclass(obj).
%   - Full qualified name for the class is unsupported. No packaging
%     information is included in the error id.


    methods (Static)
        function raise(args)
            arguments
                args.classMeta (1,1) matlab.metadata.Class
                args.suffix (1,1) string
                args.message (1,1) string = ""
                args.format (1,1) string = ""
                args.args (1,:) cell = {}
                args.prefix (1,1) string = "sfrfs"
            end

            helpers.Errors.validateArgs_(args);

            % dots from packages would break the code
            className = helpers.Errors.unqualifiedName_(...
                string(args.classMeta.Name));

            errId = args.prefix + ":" + className + ":" + args.suffix;

            if strlength(args.message) > 0
                error(errId, "%s", args.message);
            end

            error(errId, args.format, args.args{:});
        end
    end

    methods (Static, Access = private)
        function validateArgs_(args)
            hasMessage = strlength(args.message) > 0;
            hasFormat = strlength(args.format) > 0;

            if ~hasMessage && ~hasFormat
                helpers.Errors.badArgs_( ...
                    "Provide message or format.");
            end

            if hasMessage && hasFormat
                helpers.Errors.badArgs_( ...
                    "Provide message or format, not both.");
            end

            if hasFormat && isempty(args.args)
                helpers.Errors.badArgs_( ...
                    "Format requires args.");
            end
        end

        function badArgs_(msg)
            helpers.Errors.raise( ...
                classMeta=?helpers.Errors, ...
                suffix="BadArgs", ...
                message=msg);
        end

        function name = unqualifiedName_(fullName)
            parts = split(fullName, ".");
            name = parts(end);
        end

    end
end
