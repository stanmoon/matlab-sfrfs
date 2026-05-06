classdef EngineConfig
% EngineConfig
%
% EngineConfig represents the policy configuration of an evolutionary
% engine instance. It encapsulates the parameters that govern how the
% engine operates.
%
% Design intent
% -------------
% - configuration is instance-scoped (not global)
% - configuration objects are immutable after construction
% - configuration describes policy, not behavior
% - validation occurs at construction
% - logging representation must be single-row for SFRFsLogger

    properties (Constant)
        % Canonical configuration keys (constants, immutable)
        POPULATION_SIZE = "populationSize"
        MAX_GENERATIONS = "maxGenerations"
        MUTATION_RATE   = "mutationRate"
        POWER_LAW_ALPHA = "powerLawAlpha"
        POWER_LAW_RMIN  = "powerLawRMin"
    end

    properties (Constant, Access = private)
        % Default values
        DEFAULT_POPULATION_SIZE = 100
        DEFAULT_MAX_GENERATIONS = 100
        DEFAULT_MUTATION_RATE   = 0.01
        DEFAULT_POWER_LAW_ALPHA = 1.5
        DEFAULT_POWER_LAW_RMIN  = 1.0e-10
    end

    properties (GetAccess = private, SetAccess = immutable)
        % Internal canonical storage
        config dictionary
    end

    methods

        function obj = EngineConfig(args)
        % EngineConfig Construct immutable configuration using
        % Name=Value arguments.

            arguments
                args.populationSize (1,1) double = ...
                    epistemic.tools.evolutionary.EngineConfig. ...
                    DEFAULT_POPULATION_SIZE

                args.maxGenerations (1,1) double = ...
                    epistemic.tools.evolutionary.EngineConfig. ...
                    DEFAULT_MAX_GENERATIONS

                args.mutationRate (1,1) double = ...
                    epistemic.tools.evolutionary.EngineConfig. ...
                    DEFAULT_MUTATION_RATE

                args.powerLawAlpha (1,1) double = ...
                    epistemic.tools.evolutionary.EngineConfig. ...
                    DEFAULT_POWER_LAW_ALPHA

                args.powerLawRMin (1,1) double = ...
                    epistemic.tools.evolutionary.EngineConfig. ...
                    DEFAULT_POWER_LAW_RMIN
            end

            epistemic.tools.evolutionary.internal.ConfigValidator. ...
                validateAllConfigurationParameters( ...
                args.populationSize, ...
                args.maxGenerations, ...
                args.mutationRate, ...
                args.powerLawAlpha, ...
                args.powerLawRMin);

            cfg = dictionary;

            cfg(epistemic.tools.evolutionary.EngineConfig. ...
                POPULATION_SIZE) = {args.populationSize};

            cfg(epistemic.tools.evolutionary.EngineConfig. ...
                MAX_GENERATIONS) = {args.maxGenerations};

            cfg(epistemic.tools.evolutionary.EngineConfig. ...
                MUTATION_RATE) = {args.mutationRate};

            cfg(epistemic.tools.evolutionary.EngineConfig. ...
                POWER_LAW_ALPHA) = {args.powerLawAlpha};

            cfg(epistemic.tools.evolutionary.EngineConfig. ...
                POWER_LAW_RMIN) = {args.powerLawRMin};

            obj.config = cfg;

        end

        function value = getConfig(obj, key)
        % getConfig Return configuration value for a key.

            value = obj.config(key);
            value = value{1};

        end

        function txt = toString(obj)
        % toString Return deterministic single-row representation.

            keys = [ ...
                epistemic.tools.evolutionary.EngineConfig. ...
                    POPULATION_SIZE
                epistemic.tools.evolutionary.EngineConfig. ...
                    MAX_GENERATIONS
                epistemic.tools.evolutionary.EngineConfig. ...
                    MUTATION_RATE
                epistemic.tools.evolutionary.EngineConfig. ...
                    POWER_LAW_ALPHA
                epistemic.tools.evolutionary.EngineConfig. ...
                    POWER_LAW_RMIN];

            txt = "";

            for i = 1:numel(keys)

                key = keys(i);
                value = obj.config(key);
                value = value{1};

                if i > 1
                    txt = txt + ",";
                end

                txt = txt + key + "=" + string(value);

            end

            txt = "EngineConfig[" + txt + "]";

        end

    end

end