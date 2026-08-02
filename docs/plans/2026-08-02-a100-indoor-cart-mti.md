# A100 Indoor Cart MTI Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a reproducible GNU Octave community case study for LFMCW simulation, low-speed cart detection, measured CTSAI-A100 data analysis, and MTI static-clutter suppression.

**Architecture:** A self-contained project under `community/projects/a100-indoor-cart-mti/` separates simulation, measured ADC processing, RadarTools target parsing, plotting, tests, raw data, and documentation. Simulation axes use verified physical parameters; measured ADC plots use bins where hardware waveform/DDMA parameters are incomplete.

**Tech Stack:** GNU Octave 11.3.0, Octave `signal` package, MATLAB-compatible `.m` files, Markdown, PNG, CSV/ASC/TXT, Git/GitHub CLI.

---

### Task 1: Project skeleton and environment checks

**Files:**
- Create: `community/projects/a100-indoor-cart-mti/run_all.m`
- Create: `community/projects/a100-indoor-cart-mti/src/default_simulation_config.m`
- Create: `community/projects/a100-indoor-cart-mti/src/prepare_environment.m`
- Create: `community/projects/a100-indoor-cart-mti/tests/run_tests.m`

**Step 1:** Write an environment test that verifies Octave is supported, the `signal` package loads, and output directories can be created.

**Step 2:** Run `octave-cli --no-gui --quiet community/projects/a100-indoor-cart-mti/tests/run_tests.m`; expect the new test to fail because helpers do not exist.

**Step 3:** Implement the minimal environment/config helpers and entry point.

**Step 4:** Re-run the test; expect PASS.

### Task 2: Strict ADC text loader

**Files:**
- Create: `community/projects/a100-indoor-cart-mti/src/load_a100_adc.m`
- Create: `community/projects/a100-indoor-cart-mti/src/unpack_a100_words.m`
- Create: `community/projects/a100-indoor-cart-mti/tests/test_adc_loader.m`

**Step 1:** Add temporary-file tests for a valid three-field header, validated zero padding, a wrong channel/header, insufficient words, and non-zero excess data.

**Step 2:** Run the ADC loader tests; expect failures for missing functions.

**Step 3:** Parse numeric tokens, validate `[channel, 1024, 256]`, require exactly 131072 packed words after validated padding removal, unpack high/low signed 16-bit samples, and return `1024×256`.

**Step 4:** Run unit tests and then load every effective 2026-08-02 ADC file; expect all dimensions and channel headers to match and `retry2` never to be referenced.

### Task 3: LFMCW, FFT, and MTI simulation

**Files:**
- Create: `community/projects/a100-indoor-cart-mti/src/simulate_lfmcw_scene.m`
- Create: `community/projects/a100-indoor-cart-mti/src/compute_range_doppler.m`
- Create: `community/projects/a100-indoor-cart-mti/src/apply_mti.m`
- Create: `community/projects/a100-indoor-cart-mti/src/db_normalize.m`
- Create: `community/projects/a100-indoor-cart-mti/scripts/run_simulation.m`
- Create: `community/projects/a100-indoor-cart-mti/tests/test_signal_processing.m`

**Step 1:** Add deterministic tests for a target near a known range/velocity bin and for static cancellation.

**Step 2:** Run tests; expect missing-function failures.

**Step 3:** Implement complex-baseband transmit/echo/dechirp generation, windowed range FFT, centered Doppler FFT, and configurable pulse canceller order.

**Step 4:** Generate waveform, echo, beat, spectrogram, range FFT, and pre/post-MTI range—Doppler figures; verify expected target peaks and static-clutter suppression numerically.

### Task 4: Parameter studies

**Files:**
- Create: `community/projects/a100-indoor-cart-mti/scripts/run_parameter_studies.m`
- Create: `community/projects/a100-indoor-cart-mti/src/evaluate_simulation_case.m`

**Step 1:** Define one-variable-at-a-time cases for bandwidth, chirp duration, PRF, target velocity, target count, and MTI order.

**Step 2:** Run all cases with a fixed random seed and collect range resolution, velocity resolution, peak location, and clutter suppression metrics.

**Step 3:** Export six labeled PNG comparisons and a machine-readable CSV summary.

**Step 4:** Verify every requested parameter appears in the CSV and each figure is non-empty.

### Task 5: Measured ADC processing

**Files:**
- Create: `community/projects/a100-indoor-cart-mti/scripts/run_measured_adc_analysis.m`
- Create: `community/projects/a100-indoor-cart-mti/src/process_measured_adc.m`
- Create: `community/projects/a100-indoor-cart-mti/data/adc/README.md`

**Step 1:** Load the four-channel static-box and empty-background captures plus Rx0 approaching and final receding captures through the strict loader.

**Step 2:** Produce comparable range-bin profiles and pre/post-MTI range—normalized-Doppler maps.

**Step 3:** Record header/dimension validation and suppression metrics without converting Doppler bins to physical velocity.

**Step 4:** Verify no script or document references `adc_receding_box_rx0_retry2_20260802164229830` as an input.

### Task 6: RadarTools point-cloud/track analysis

**Files:**
- Create: `community/projects/a100-indoor-cart-mti/src/read_radartools_targets.m`
- Create: `community/projects/a100-indoor-cart-mti/scripts/run_target_analysis.m`
- Create: `community/projects/a100-indoor-cart-mti/tests/test_target_parser.m`
- Create: `community/projects/a100-indoor-cart-mti/data/targets/README.md`

**Step 1:** Write a fixture containing the CSV header, metadata lines, and valid target rows.

**Step 2:** Implement tolerant parsing that only accepts rows matching the header and numeric key fields.

**Step 3:** Plot distance/time trends and XY trajectories for static, empty, approaching, and receding scenes; export robust per-scene statistics.

**Step 4:** Verify approaching/receding interpretations against the parsed distance trend and explicitly flag sparse or missing tracking output.

### Task 7: Package data, figures, and technical article

**Files:**
- Create: `community/projects/a100-indoor-cart-mti/data/manifest.csv`
- Create: `community/projects/a100-indoor-cart-mti/docs/technical-article.md`
- Create: `community/projects/a100-indoor-cart-mti/README.md`
- Modify: `community/projects/README.md`

**Step 1:** Copy only the four effective ADC datasets and the four scenes' non-empty ASC/RawTarget/TraTarget files into the project.

**Step 2:** Generate a manifest containing scenario, relative path, byte size, and SHA-256; verify hashes against the acquisition workspace.

**Step 3:** Write the scene layout, acquisition method, file structure, algorithms, parameter effects, results, limitations, and simulation-versus-measurement comparison.

**Step 4:** Confirm `retry2`, zero-byte videos, unrelated 2026-08-01 files, and `RadarToolsConfig.ini` are absent from the Git diff.

### Task 8: Full verification and publication

**Files:**
- Create: `community/projects/a100-indoor-cart-mti/results/metrics.csv`
- Create: `community/projects/a100-indoor-cart-mti/results/parameter_studies.csv`
- Create: `.github` PR body only through GitHub, not as a repository file.

**Step 1:** Run all unit tests and `run_all.m` in GNU Octave 11.3.0; expect a zero exit code.

**Step 2:** Inspect generated figures, verify all referenced paths, and run repository-wide forbidden-file checks.

**Step 3:** Check `gh auth status` and local Git author/committer are `yyqdbngt`; commit only intentional files.

**Step 4:** Push `btlqql/issue-8-indoor-cart-mti` to the `yyqdbngt/CTSAI-A100` fork and open a PR to `Super-Radar/CTSAI-A100:main` with `Closes #8` or `Relates to #8` as appropriate.

