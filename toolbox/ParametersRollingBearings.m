classdef ParametersRollingBearings
%PARAMETERSROLLINGBEARINGS Bearing geometry and configuration parameters
%
%   Geometric parameters of a rolling element bearing:
%   number and size of rolling elements, pitch diameter, and contact angle.
%
%   All properties are public and set during construction.
%
%   Properties (all mandatory):
%       NumRollingElements (integer >= 1)
%           Number of rolling elements (balls/rollers) in the bearing.
%
%       BallDiameter (double > 0) [mm]
%           Diameter of each rolling element.
%
%       PitchDiameter (double > 0) [mm]
%           Pitch diameter of the bearing.
%
%       ContactAngle (double, 0 <= angle <= 90) [degrees]
%           Contact angle between the rolling elements and the races.
%
%   Example:
%       bp = ParametersRollingBearings( ...
%           'numRollingElements',8, ...
%           'ballDiameter',7.92, ...
%           'pitchDiameter',34.55, ...
%           'contactAngle',0);
%
%   See also: bearingFaultBands, BearingFrequencyBands

    properties (SetAccess = immutable)
        numRollingElements
        ballDiameter
        pitchDiameter
        contactAngle
    end

    methods
        function obj = ParametersRollingBearings(args)
            % Constructor using name-value arguments
            arguments
                args.numRollingElements (1,1) {...
                    mustBeInteger, mustBePositive}
                args.ballDiameter (1,1) double {mustBePositive}
                args.pitchDiameter (1,1) double {mustBePositive}
                args.contactAngle (1,1) double {...
                    mustBeGreaterThanOrEqual(args.contactAngle,0), ...
                    mustBeLessThanOrEqual(args.contactAngle,90)}
            end

            % Assign directly to public properties
            obj.numRollingElements = args.numRollingElements;
            obj.ballDiameter = args.ballDiameter;
            obj.pitchDiameter = args.pitchDiameter;
            obj.contactAngle = args.contactAngle;

            log = SFRFsLogger.getLogger();
            if log.isFineEnabled()
                log.fine(obj.toString())
            end
        end

        function str = toString(obj)
            % Return a formatted string representation
            str = sprintf( ...
                [ ...
                '[ParametersRollingBearings: '...
                'numRollingElements: %d, ballDiameter: %.3f mm, ' ...
                'pitchDiameter: %.3f mm, contactAngle: %.2f degrees]'], ...
                obj.numRollingElements, obj.ballDiameter, ...
                obj.pitchDiameter, obj.contactAngle);
        end
    end
end
