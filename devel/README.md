# SFRFs Toolbox - API Reference


## Data Layer


### Dataset (+data package)

- createXJTUSYEnsemble - Create and configure a fileEnsembleDatastore from the XJTU-SY dataset.
- getXJTUSYEnsemble - Retrieve an already-registered XJTU-SY ensemble from the registry.


### Dataset Metadata

- OperatingConditions - Encapsulates speed, load, and operating regime.
- ParametersSnapshot - Defines sampling frequency, duration, and stride.


## Ensemble Mediation Layer


### File data ensemble access

- EnsembleBroker - Base class for managing ensemble metadata and naming conventions.
- SFRFsEnsembleBroker - Specialization for SFRF-related column mapping.


### Registry of fileEnsembleDatastore objects

- EnsembleDatastoreRegistry - Central registry for fileEnsembleDatastore objects.


## Component knowledge


### Diagnostics

- FaultFrequencyBands - Abstract representation of fault frequency bands.
- BearingFrequencyBands - Derived class for computing bearing-related fault frequencies.


### Geometry parameters

- ParametersRollingBearings - Bearing geometry and physical parameters.


## Perception model


### Receptive field gain functions (RFGFs)

- FrequencyMask - Generates Gaussian and Super-Gaussian frequency-domain masks.
- MaskParameters - Abstract base class for mask profile parameterization.
- SuperGaussianMaskParameters - Parameter container for super-Gaussian mask profiles.
- GaussianMaskParameters - Parameter container for Gaussian mask profiles.
- ReceptiveFieldGainFunctions - Generates center/surround gain functions per fault and operating condition.


### Computational mappings

- ReceptiveFieldResponseFunctions - A standard library with common receptive field response functions (RFRFs).
- ContrastMappings - A standard library of contrast mappings (CMs) for center-surround opponency.


### SFRF parameter specification

- SFRFsParameters - Generic SFRF parameter definition.
- SFRFsParametersRollingBearings - Bearing-specific SFRF parameter specialization.


## Compute Layer


### Ensemble processing

- EnsembleProcessor - Applies operations row-wise over an ensemble.
- FFTEnsembleProcessor - Computes frequency-domain representations.
- SFRFsEnsembleProcessor - Computes SFRFs for a full ensemble.


### SFRF computation

- SFRFsCompute - Main entry point for calculating SFRFs from temporal or spectral data.
- CenterSurroundCompute - Compute center/surround responses via RFGFs.


## Schema Layer


### Dictionary keys (+dicts package)

- BandMapSchema - String keys for frequency-band records used in receptive-field construction.


### Struct fields (+structs)

- FaultBandsExtractSchema - Centralizes field-name constants for the struct output of extractBands().
- FrequencyBankMasksSchema - Field-name constants for frequency-bank mask table records.
- OpponentBandsSchema - Field-name constants for center-surround opponent frequency-band pairs.


### Table columns (+tables)

- FaultConditionTableMetaSchema - Column-name constants for fault-condition table records.
- FaultsBandsTableSchema - Extends FaultConditionTableMetaSchema with fault-frequency band definitions.
- GainFunctionsTableSchema - Adds RFGF and response columns to FaultBandsTableSchema .
- OperatingConditionsTableSchema -  Defines column name constants for operating-condition tables.


## Utils

- EnsembleUtil - Utility methods for ensemble manipulation.
- FaultConditionSelector - Resolve a fault-condition key to a unique row.
- OperatingConditionSelection - Select an operating condition (speed, load).


## Observability

- SFRFsLogger - Singleton logger with per-worker file management.


## Visualization layer

- RFGFViewer - Embeddable viewer for receptive field gain functions (RFGFs).
- RunToFailureRFGFsFilteredSpectraViewer - Viewer for log-scale run-to-failure spectra filtered by RFGF masks.
- RunToFailureSFRFsViewer - Viewer for failure-dependent SFRF trajectories.
- RunToFailureSpectraViewer - Viewer for run-to-failure spectra.


## API Index (alphabetical)

- BandMapSchema - Key constants for band map records.
- BearingFrequencyBands - Computes bearing-related fault frequency bands from geometry and operating conditions.
- CenterSurroundCompute - Compute center/surround responses via RFGFs.
- ContrastMappings - A standard library of contrast mappings (CMs) for center-surround opponency.
- createXJTUSYEnsemble - Creates and configures a fileEnsembleDatastore from the XJTU-SY dataset.
- EnsembleBroker - Base class for managing ensemble metadata and naming conventions.
- EnsembleDatastoreRegistry - Central registry for storing and retrieving fileEnsembleDatastore objects.
- EnsembleProcessor - Applies processing functions row-wise over ensemble data.
- EnsembleUtil - Utility functions for ensemble manipulation and inspection.
- FaultBandsExtractSchema - Field names for extractBands output structs.
- FaultBandsTableSchema - Column names for fault bands tables.
- FaultConditionSelector - Resolve a fault-condition key to a unique row.
- FaultConditionTableMetaSchema - Base columns for fault-condition tables.
- FaultFrequencyBands - Abstract representation of fault frequency bands.
- FFTEnsembleProcessor - Computes and stores frequency-domain representations for ensemble data.
- FrequencyBankMasksSchema - Field names for frequency-bank mask records.
- FrequencyMask - Generates Gaussian and super-Gaussian frequency-domain masks.
- GainFunctionsTableSchema - Column names for gain-functions tables.
- GaussianMaskParameters - Parameter container for Gaussian mask profiles.
- getXJTUSYEnsemble - Retrieves a registered XJTU-SY ensemble from the registry.
- MaskParameters - Abstract base class for mask profile parameterization.
- OperatingConditions - Encapsulates speed, load, and operating condition definitions.
- OperatingConditionSelection - Select an operating condition (speed, load).
- OperatingConditionsTableSchema - Column names for operating conditions tables.
- OpponentBandsSchema - Field names for opponent band intervals.
- ParametersRollingBearings - Stores bearing geometry and physical parameters.
- ParametersSnapshot - Defines sampling frequency, duration, and stride for signal snapshots.
- ReceptiveFieldGainFunctions - Builds frequency-domain gain functions from fault bands.
- ReceptiveFieldResponseFunctions - A standard library with common receptive field response functions (RFRFs).
- RFGFViewer - Embeddable viewer for receptive field gain functions (RFGFs).
- RunToFailureRFGFsFilteredSpectraViewer - Viewer for log-scale run-to-failure spectra filtered by RFGF masks.
- RunToFailureSpectraViewer - Viewer for run-to-failure spectra.
- SFRFsCompute - Computes Spectral Fault Receptive Fields from temporal or spectral data.
- SFRFsEnsembleBroker - Specialization of EnsembleBroker for SFRF column handling.
- SFRFsEnsembleProcessor - Computes SFRFs across an entire ensemble.
- SFRFsLogger - Centralized, per-process logger for the SFRFs toolbox.
- SFRFsParameters - Generic parameter container for SFRF definition.
- SFRFsParametersRollingBearings - Rolling bearing–specific SFRF parameter specialization.
- SuperGaussianMaskParameters - Parameter container for super-Gaussian mask profiles.

