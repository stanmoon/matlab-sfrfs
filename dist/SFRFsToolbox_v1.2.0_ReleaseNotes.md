# SFRFs Toolbox — Release Notes

## Version 1.2.0

Version 1.2.0 extends the Spectral Fault Receptive Fields (SFRFs) Toolbox with harmonic-resolved spectral representations and contrast-polarity analysis for vibration-based condition monitoring of rotating machinery.

This release introduces harmonic-indexed receptive-field gain functions and response computation, cross-sensor contrast-polarity filtering, temporal polarity-event detection, and structured dataset construction. An interactive explorer supports the examination of stored contrast-polarity representations across bearing runs and monitored fault-frequency families.

The new components extend the existing compositional perception framework while maintaining a separation between representation construction, descriptive exploration, and diagnostic or prognostic interpretation.

## Harmonic-Resolved SFRF Computation

Version 1.2.0 introduces harmonic-resolved receptive-field computation, extending the original aggregated SFRF representations by preserving the contributions of individual harmonic components.

The new implementation separates the construction of harmonic-indexed spectral gain functions from their subsequent application to spectral observations. This supports the examination of harmonic-specific responses and their temporal evolution while retaining compatibility with the existing receptive-field framework.

**Harmonic-indexed gain functions and responses**

| Aspect | Description |
|---|---|
| Harmonic gain functions | `LiftedHarmonicGainFunctions` constructs harmonic-indexed center and surround spectral masks, preserving individual harmonic components. |
| Response computation | `LiftedHarmonicResponseCompute` applies precomputed harmonic masks to spectral observations using configurable receptive-field response functions. |
| Harmonic resolution | Individual harmonic responses remain accessible instead of being combined into a single aggregated receptive-field response. |
| Computational separation | Separates spectral-mask construction from response evaluation, supporting reuse of precomputed masks. |
| Framework integration | Extends the existing SFRF computation architecture without replacing aggregated receptive-field workflows. |

## Contrast-Polarity Analysis and Temporal Event Detection

Version 1.2.0 introduces contrast-polarity analysis for harmonic-resolved spectral representations, supporting the examination of cross-sensor agreement, polarity transitions, and temporally localized events.

The new components provide complementary operations for resolving harmonic contrast representations and characterizing their temporal behavior.

**Contrast-polarity filtering and event detection**

| Aspect | Description |
|---|---|
| Cross-sensor agreement | `ContrastPolarityFilter` resolves harmonic-indexed contrasts using polarity agreement across sensor-local representations. |
| Adaptive agreement filtering | Applies an asymmetrically smoothed agreement floor to regulate the contribution of supported harmonic contrasts. |
| Polarity reversal detection | `PolarityReversalDetector` identifies harmonic contrast-polarity reversals and summarizes their occurrence along observation trajectories. |
| Signed ON/OFF events | `OnOffContrastPolarityDetector` detects positive and negative temporal contrast events and computes per-harmonic event counts. |
| Representation preservation | Maintains harmonic-level information and temporal indexing for subsequent analysis and exploration. |
| Interpretation | Produces descriptive contrast-polarity representations and event indicators without independently establishing fault diagnoses or degradation states. |

## Dataset Construction and Interactive Exploration

Version 1.2.0 introduces dedicated components for constructing, organizing, and exploring harmonic-resolved contrast-polarity representations across bearing runs and monitored fault-frequency families.

The workflow separates computationally intensive representation construction from subsequent interactive exploration, enabling previously generated datasets to be examined without repeating the underlying spectral computations.

**Dataset builders and visualization**

| Aspect | Description |
|---|---|
| Channel dataset construction | `ContrastPolarityChannelDatasetBuilder` constructs harmonic contrast and polarity-event channels from bearing-run spectral observations, integrating receptive-field computation, cross-sensor filtering, and temporal event detection. |
| Exploration dataset construction | `ContrastPolarityExplorationDatasetBuilder` organizes stored representations into canonical exploration datasets indexed by bearing run and monitored fault-frequency family. |
| Interactive exploration | `viz.ContrastPolarityDegradationExplorer` provides an interactive graphical interface for examining previously computed representations. |
| Complementary visualization modes | Supports direct observables, epistemic support, event density, polarity balance, harmonic polarity trajectories, and harmonic relevance. |
| Metadata integration | Preserves available operating-condition information, representation dimensions, and externally supplied bearing failure annotations. |
| Computational reuse | Enables repeated exploration of stored datasets without regenerating spectral fault receptive fields or contrast-polarity channels. |
| Interpretation scope | Supports descriptive exploration and hypothesis development without automatically inferring degradation states, fault diagnoses, or remaining useful life. |

## Architectural and API Enhancements

The new components extend the existing compositional perception framework without replacing established interfaces. The API reference has been updated to include harmonic-resolved computation, contrast-polarity analysis, dataset construction, and interactive exploration, with dedicated MATLAB Live Script documentation and executable examples.

## Validation and Testing

Automated tests cover the new harmonic-resolved computation, contrast-polarity filtering, temporal event detection, and dataset-construction components.

The interactive contrast-polarity explorer was tested using previously computed XJTU-SY representations, including visualization modes, bearing and fault-family selection, and diagnostic annotation displays.

Installation and full regression testing of the packaged v1.2.0 toolbox remain pending final release validation.

## Compatibility

- Version 1.2.0 preserves the public interfaces and workflows introduced in previous releases.
- Existing SFRF computation pipelines remain supported.
- Harmonic-resolved computation and contrast-polarity analysis are introduced as additional capabilities without requiring migration of existing workflows.

## Previous Releases

- **v1.1.0** — Generalized perceptual framework, compositional response functions, and contrast mappings.
- **v1.0.0** — First stable public release.
