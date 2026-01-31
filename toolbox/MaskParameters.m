classdef (Abstract) MaskParameters
% MaskParameters
%
% Abstract base class for mask profile parameterization.
%
% The semantic meaning of a mask is defined by the concrete subclass
% (e.g. GaussianMaskParameters, SuperGaussianMaskParameters).
%
% Parameters are stored as a dictionary (actually a struct) to accommodate
% instance-specific naming.
%

    properties
        params (1,1) struct   % dictionary of mask-specific parameters
    end

    methods
        function obj = MaskParameters(params)
            % Construct a mask-parameter object.
            arguments
                params (1,1) struct = struct()
            end
            obj.params = params;
        end

        function str = toString(obj)
            % Return a JSON string representation of mask parameters.
            str = sprintf('[%s: %s]', class(obj), jsonencode(obj.params));
        end
    end

    methods (Abstract)
        bw = getReferenceBandwidth(obj)
        % Return a reference bandwidth (Hz) for band construction.
    end
end
