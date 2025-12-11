classdef ParametersSnapshot < handle    
% ParametersSnapshot: Parameter object describing snapshot metadata
% Independent parameters for sampling and snapshot timing.
%
% Properties:
%   samplingFrequency - Sampling frequency (Hz)
%   duration          - Snapshot window duration (seconds)
%   stride            - Time interval between consecutive snapshot 
%                       start times (seconds)
%
% Example:
%   params = ParametersSnapshot(...
%       'samplingFrequency', 25600, ...
%       'duration', 1.28, ...
%       'stride', 60);
%   disp(params.toString())
%
    
    properties (SetAccess = immutable)
        
        samplingFrequency  % Sampling frequency (Hz)
        duration           % Snapshot window duration (seconds)
        stride             % Time interval between consecutive snapshot 
                           % start times (seconds)
    end
    properties (Access = private)
        totalSamples = NaN  % Cached total samples
    end
    
    methods
        function obj = ParametersSnapshot(args)
            arguments
                args.samplingFrequency (1,1) double {mustBePositive}
                args.duration (1,1) double {mustBePositive}
                args.stride (1,1) double {mustBePositive}
            end
            
            obj.samplingFrequency = args.samplingFrequency;
            obj.duration = args.duration;
            obj.stride = args.stride;
            log = SFRFsLogger.getLogger();
            if log.isFineEnabled()
                log.fine(obj.toString());
            end
        end
        
        function n = getTotalSamples(obj)
            % Returns total number of samples in the snapshot window
            if isnan(obj.totalSamples)
                n = round(obj.samplingFrequency * obj.duration);
                obj.totalSamples = n;
            else
                n = obj.totalSamples;
            end
        end
        
        function str = toString(obj)
            % Returns a formatted string describing this object
            str = sprintf(['[ParametersSnapshot: fs=%.2f Hz, ' ...
               'duration=%.3f s, stride=%.3f s]'], ...
               obj.samplingFrequency, obj.duration, obj.stride);
        end

        function freqAxis = getFrequencyDomain(obj)
        % getFrequencyDomain Compute FFT frequency axis for the snapshot.
        %
        % Returns a vector of frequencies corresponding to the FFT bins of 
        % the snapshot data assumed to have length obj.snapshotLength and 
        % sampled at obj.samplingFrequency Hz.
        %
        % Returns:
        %   freqAxis - Column vector of frequencies in Hz covering the full 
        %              FFT.

            % number of samples (rounded)
            N = obj.getTotalSamples(); 
            Fs = obj.samplingFrequency;

            freqAxis = (0:N-1)' * (Fs / N);
        end
        
        function timeAxis = getTimeAxis(obj)
        % getTimeAxis Return the time axis for a single snapshot.
        %
        % Returns:
        %   timeAxis - [Nx1] column vector of time values (in seconds) 
        %              corresponding to each sample in the snapshot.
                N = obj.getTotalSamples(); 
                % Time axis in seconds
                timeAxis = (0:N-1)' / obj.samplingFrequency; 
            end

    end
end

