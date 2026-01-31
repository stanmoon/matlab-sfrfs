% SFRFs Toolbox - Core Toolbox Folder
% Version 1.1.0
%
% Core API classes, utilities, and live documentation for the
% Spectral Fault Receptive Fields (SFRFs) toolbox.
%
% Core Classes and Functions
%   BearingFrequencyBands           Bearing fault frequency bands
%   FaultFrequencyBands             Base class for frequency-band models
%   ParametersRollingBearings       Rolling-bearing geometry parameters
%   SFRFsParametersRollingBearings  Parameters for bearing SFRFs
%
%   MaskParameters                  Abstract mask parameter base class
%   GaussianMaskParameters          Gaussian spectral mask parameters
%   SuperGaussianMaskParameters     Super-Gaussian spectral mask parameters
%   FrequencyMask                   Frequency-domain spectral masking
%
%   ReceptiveFieldGainFunctions     Receptive field gain functions (RFGFs)
%   ReceptiveFieldResponseFunctions Response functions for SFRFs
%   ContrastMappings                Center–surround contrast operators
%   CenterSurroundCompute           Center–surround contrast computation
%
%   SFRFsParameters                 Base class for SFRF parameters
%   SFRFsCompute                    Core SFRF computation
%
%   EnsembleProcessor               Abstract ensemble processor
%   FFTEnsembleProcessor            FFT-based ensemble processing
%   SFRFsEnsembleProcessor          Ensemble-level SFRF computation
%
%   EnsembleBroker                  Ensemble data access and mediation
%   SFRFsEnsembleBroker             SFRF-specific ensemble broker
%   EnsembleDatastoreRegistry       Registry of ensemble datastore objects
%   EnsembleUtil                    Utilities for ensemble data handling
%
%   OperatingConditions             Operating-condition metadata
%   OperatingConditionSelection    Selection of operating conditions
%   FaultConditionSelector          Selection of fault conditions
%   ParametersSnapshot              Metada
