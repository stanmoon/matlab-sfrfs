classdef ContrastMappings
%ContrastMappings  A standard library of contrast mappings for 
% center-surround opponency.
% Each static method returns a function handle callable as:
%   c = map(Rc, Rs)
%   c = map(Rc, Rs, params)
%
% Inputs:
%   Rc     - center response (scalar or vector)
%   Rs     - surround response (same size as Rc)
%   params - optional scalar struct with mapping parameters. Fields depend
%            on the mapping; unused fields are ignored.
%
% Output:
%   c      - contrast value(s), same size as Rc/Rs.
%
% Usage note:
%   Mapping handles may optionally accept a third input argument for
%   parameterization. How parameters are bound or provided is left to the
%   mapping implementation.


    methods (Static)
        function map = difference(args)
        %difference Linear contrast: Rc - k*Rs.
            arguments
                args.k (1, 1) double = 1
            end

            k0 = args.k;

            map = @(Rc, Rs, varargin) ContrastMappings.doDifference( ...
                Rc, Rs, ContrastMappings.resolveParam(varargin, "k", k0));
        end

        function map = ratio(args)
        %ratio Relative contrast: Rc / (k*Rs + eps).
            arguments
                args.k   (1, 1) double = 1
                args.eps (1, 1) double {mustBePositive} = 1e-12
            end

            k0 = args.k;
            e0 = args.eps;

            map = @(Rc, Rs, varargin) ContrastMappings.doRatio( ...
                Rc, Rs, ...
                ContrastMappings.resolveParam(varargin, "k", k0), ...
                ContrastMappings.resolveParam(varargin, "eps", e0));
        end

        function map = logRatio(args)
        %logRatio Log contrast: log((Rc+eps)/(k*Rs+eps)).
            arguments
                args.k   (1, 1) double = 1
                args.eps (1, 1) double {mustBePositive} = 1e-12
            end

            k0 = args.k;
            e0 = args.eps;

            map = @(Rc, Rs, varargin) ContrastMappings.doLogRatio( ...
                Rc, Rs, ...
                ContrastMappings.resolveParam(varargin, "k", k0), ...
                ContrastMappings.resolveParam(varargin, "eps", e0));
        end

        function map = normalizedDifference(args)
        %normalizedDifference (Rc-k*Rs)/(Rc+k*Rs+eps).
            arguments
                args.k   (1, 1) double = 1
                args.eps (1, 1) double {mustBePositive} = 1e-12
            end

            k0 = args.k;
            e0 = args.eps;

            map = @(Rc, Rs, varargin) ContrastMappings.doNormDiff( ...
                Rc, Rs, ...
                ContrastMappings.resolveParam(varargin, "k", k0), ...
                ContrastMappings.resolveParam(varargin, "eps", e0));
        end
    end

    methods (Static, Access = private)
        
        function v = resolveParam(vin, name, default)
            arguments
                vin cell
                name (1, 1) string
                default
            end
        
            % vin is varargin from the mapping handle.
            if isempty(vin)
                v = default;
                return
            end
        
            params = vin{1};
        
            if isempty(params)
                v = default;
                return
            end
        
            if ~isstruct(params) || ~isscalar(params)
                error("sfrfs:ContrastMappings:InvalidParams", ...
                    "params must be a scalar struct (or empty).");
            end
        
            if isfield(params, name) && ~isempty(params.(name))
                v = params.(name);
            else
                v = default;
            end
        end


        function c = doDifference(Rc, Rs, k)
            c = Rc - k .* Rs;
        end

        function c = doRatio(Rc, Rs, k, epsVal)
            ContrastMappings.validateEps(epsVal);
            c = Rc ./ (k .* Rs + epsVal);
        end

        function c = doLogRatio(Rc, Rs, k, epsVal)
            ContrastMappings.validateEps(epsVal);
            c = log((Rc + epsVal) ./ (k .* Rs + epsVal));
        end

        function c = doNormDiff(Rc, Rs, k, epsVal)
            ContrastMappings.validateEps(epsVal);
            c = (Rc - k .* Rs) ./ (Rc + k .* Rs + epsVal);
        end

        function validateEps(epsVal)
            if ~(isscalar(epsVal) && isfinite(epsVal) && epsVal > 0)
                error("sfrfs:ContrastMappings:InvalidEps", ...
                    "eps must be a positive finite scalar.");
            end
        end
    end
end
