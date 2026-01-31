# SFRFs Toolbox v1.1.0 — Release Notes

Version **1.1.0** extends the Spectral Fault Receptive Fields (SFRFs) Toolbox 
from a single Difference-of-Gaussians (DoG) condition-indicator model into a 
more general *compositional perception framework*, while improving research 
agility via function injection and strengthening parallel robustness and 
release engineering.

Core v1.0.0 workflows remain fully supported and backward compatible.

---

## Highlights

**Generalized perceptual model beyond DoG**

- Super-Gaussian spectral masks introduced as first-class mask family
- Receptive Field Response Functions (RFRFs) generalized beyond fixed integral magnitude
- Contrast mappings generalized beyond difference contrasts
- Multiple perceptual channels supported via:
  - mask family selection
  - response aggregator selection
  - contrast mapping selection

**Composable function-based architecture**

- Response aggregators injectable via function handles
- Contrast mappings injectable via function handles
- Clean separation of:
  - spectral selectivity (mask)
  - response aggregation (RFRF)
  - contrast mapping

**Schema-based metadata contracts**

- Formalized schema packages for:
  - table column schemas
  - struct field schemas
  - dictionary key schemas
- Stable naming contracts across pipeline stages
- Reduced risk of silent metadata drift

**Expanded visualization layer (incipient)**

- New and evolving `viz` package with viewers for:
  - receptive field gain functions
  - run-to-failure spectra
  - SFRF trajectories
  - filtered spectra
- Supports perceptual inspection and interpretability workflows
- Visualization API is incipient and may evolve in future releases

**Worker-safe parallel ensemble processing**

- Cluster-aware worker limit detection
- Sorting data files by size to better balance worker loads.
- Fail-fast validation on excessive worker requests

---

## Conceptual and Model Extensions

### Generalized spectral mask model

- Super-Gaussian spectral masks supported alongside Gaussian masks
- Mask profiles parameterized by:
  - scale alpha (bandwidth control)
  - shape parameter beta
- Gaussian masks remain supported as special case (beta = 2)
- Continuous interpolation from box-like to Gaussian-like profiles
- Explicit support for non-Gaussian admissible spectral masks

### Receptive Field Response Functions (RFRFs)

- Response layer generalized to RFRF abstraction
- Response-function library with injectable aggregators:
  - magnitude integrals
  - frequency-scaled (fractional-order) integrals
  - entropy-based measures
- Response explicitly modeled as:

```
mask × spectrum → aggregation → scalar response
```

### Generalized contrast mappings

- Center–surround opponency extended beyond DoG formulation
- Contrast mapping library with injectable operators:
  - difference
  - ratio
  - log-ratio
  - normalized difference
- Contrast mappings treated as first-class mapping functions with consistent signatures
- Supports nonlinear and scale-invariant contrast formulations

---

## Architectural and API Enhancements

**Layered conceptual architecture documented**

The toolbox architecture is now documented around conceptual layers:

- Dataset & metadata
- Ensemble mediation
- Diagnostic component knowledge
- Perception model
- Compute layer
- Schema layer (tables / structs / dicts)
- Observability
- Visualization

The API reference reflects this layered conceptual model.  
Explicit layer namespaces are not yet enforced; introducing them would be a 
**future major-version change** due to backward-compatibility impact.

---

## Ensemble and Parallel Processing Robustness

- Strict pool size enforcement.
- Basic balancing of loads by processing larger-files-first approach.
- Early fail on misconfiguration of pool sizes.

---

## Numerical and Modeling Fixes

**Rolling-element sideband correction**

- Rolling-element (ball spin) sideband modulation corrected.
- Sidebands now computed using Fundamental Train Frequency (FTF) instead of shaft rotational frequency.
- Aligns with bearing fault models and MATLAB bearing fault band conventions.

---

## Release Engineering Improvements

**Unified versioned release pipeline**

- Release labeling integrated into release script
- Versioned toolbox artifacts produced directly:

```
SFRFsToolbox_vX.Y.Z.mltbx
```

- Install workflow aligned with versioned artifacts
- Eliminated label/install mismatch cases


## Compatibility

- Fully backward compatible with v1.0.0 user code
- Existing SFRF pipelines run unchanged
- DoG-style CI workflows remain valid special cases within the generalized framework

---

## Testing

Run the full test suite with a single script:

```matlab
test_sfrfs
```

All tests pass under clean install/uninstall cycles and bounded worker pools.

---

## Previous Releases

- **v1.0.0 — First public stable release**  
  See archived release notes for full details.
