classdef OperatingConditionSelection
%OperatingConditionSelection  Select an operating condition (speed, load).
%
% Usage:
%   sel = OperatingConditionSelection(speed=speedHz, load=loadkN)
%
% The selection is intentionally minimal and domain-anchored:
%   - speed : shaft rotational speed in Hz
%   - load  : load in kN
%
% See also: OperatingConditions, FaultFrequencyBands

    properties (SetAccess = private)
        speed (1,1) double
        % Shaft rotational speed in Hz.

        load (1,1) double
        % Load corresponding to the operating condition (kN).
    end

    methods
        function obj = OperatingConditionSelection(args)
        %OperatingConditionSelection Construct an operating condition
        % selection.
        %
        %   obj = OperatingConditionSelection(speed=speedHz, load=loadkN)

            arguments
                args.speed (1,1) double ...
                    {mustBeFinite, mustBeReal, mustBePositive}
                args.load (1,1) double {mustBeFinite, mustBeReal}
            end

            obj.speed = args.speed;
            obj.load = args.load;
        end
    end
end
