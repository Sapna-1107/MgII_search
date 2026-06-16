# QSO Continuum Fitting & MgII Absorber Visual Inspection

IDL tools for quasar spectral analysis: automated continuum fitting and interactive visual identification of MgII absorbers.

---

## Files

| File | Purpose |
|------|---------|
| `qso_continuum_fit.pro` | Iterative B-spline continuum fitter for quasar spectra |
| `mgii_visual_check.pro` | Interactive GUI for visually inspecting and measuring MgII doublet absorbers |

---

## `qso_continuum_fit.pro`

### Overview

Fits a smooth continuum to a quasar spectrum using iterative B-spline fitting with sigma-clipping to mask absorption features. The algorithm progressively rejects pixels that are significantly below the fitted continuum (absorption troughs) so that the final fit traces the unabsorbed quasar emission.

### Function Signature

```idl
result = qso_continuum_fit(loglam, flux, invvar, $
                           range=range, $
                           model1=model1, $
                           model2=model2, $
                           model3=model3, $
                           mask=mask, $
                           firstpass=firstpass)
```

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `loglam` | 1D array | Log10 of wavelength (Å) |
| `flux` | 1D array | Flux array |
| `invvar` | 1D array | Inverse variance array (0 = masked pixel) |

### Keyword Outputs

| Keyword | Description |
|---------|-------------|
| `model1` | Continuum from the iterative first-pass B-spline fit |
| `model2` | Smoother continuum from second-pass fit to `model1` (nord=4, everyn=5) |
| `model3` | Final smoothest continuum from third-pass fit to `model2` (nord=7, everyn=10) |
| `mask` | Boolean pixel mask: 1 = rejected (absorption), 0 = good |
| `firstpass` | Value of the first-pass iteration count (set to 30) |

### Return Value

Returns `model2` — the second-pass B-spline continuum, which is the recommended continuum estimate for most use cases.

### Algorithm

The fitting proceeds in three stages:

**Stage 1 — Iterative absorption masking (up to 50 iterations):**

1. Computes an adaptive weight array based on flux and inverse variance, smoothed over 25 pixels.
2. Determines adaptive B-spline breakpoint spacing from the cumulative weight distribution (bounded between 1/170 and 1/50 of total weight).
3. Fits a B-spline to the current unmasked pixels using `bspline_iterfit` with upper/lower rejection thresholds of 10σ / 2σ.
4. Smooths the residuals over 61 pixels to identify broad absorption regions.
5. Masks pixels where the smoothed residual dips below −2σ and the local residual is also below threshold.
6. Recovers pixels where the residual is above −1σ (re-includes them as good).
7. Iterates until no new pixels are masked.

**Stage 2 — Second-pass smooth fit:**

Fits a B-spline (nord=4, everyn=5) to `model1` using the stage-1 mask. Upper/lower rejection: 8σ / 1σ. Output: `model2`.

**Stage 3 — Third-pass ultra-smooth fit:**

Fits a B-spline (nord=7, everyn=10) to `model2` using the stage-1 mask. Upper/lower rejection: 8σ / 2σ. Output: `model3`.

### Key Internal Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| `smoothscale` | 61 | Pixel smoothing scale for residual detection |
| `weightsmooth` | 25 | Pixel smoothing scale for breakpoint weight |
| `firstupper` | 10.0 | Upper sigma threshold (first-pass B-spline) |
| `firstlower` | 2.0 | Lower sigma threshold (first-pass B-spline) |
| `maxiter` | 50 | Maximum masking iterations |

### Dependencies

- `bspline_iterfit` — IDL astronomy library B-spline fitter (part of [idlutils](https://www.sdss.org/dr12/software/idlutils/))

### Example Usage

```idl
; Read a spectrum
aa = mrdfits('spec-XXXX.fits', 1, h)
gdpix = where(aa.IVAR GT 0 AND FINITE(aa.IVAR))
loglam = aa.LOGLAM[gdpix]
flux   = aa.FLUX[gdpix]
invvar = aa.IVAR[gdpix]

; Fit the continuum
conti = qso_continuum_fit(loglam, flux, invvar, $
                          model1=m1, model2=m2, model3=m3, mask=msk)

; conti = m2 (second-pass fit, recommended)
; Plot
plot, 10.^loglam, flux
oplot, 10.^loglam, conti, color=2, thick=2
```

---

## `mgii_visual_check.pro`

### Overview

An interactive IDL widget GUI for visually inspecting candidate MgII absorbers in quasar spectra. The program reads a list of spectra and associated absorption redshifts, displays each spectrum normalized by its continuum, and allows the user to navigate through sources, measure equivalent widths (EW) of the MgII 2796/2803 doublet, and save measurements to file.

### Usage

```idl
mgii_visual_check
```

No arguments. The program reads `Mgii_result.txt` from the current working directory.

### Input File Format

The program reads `Mgii_result.txt` with the following columns (space/tab separated, first line skipped as header):

```
dir_name    file1    zabs    name
```

| Column | Type | Description |
|--------|------|-------------|
| `dir_name` | String | Directory path containing the spectrum file |
| `file1` | String | Spectrum filename (FITS format, SDSS-style) |
| `zabs` | Float | Candidate absorption redshift |
| `name` | String | Source/QSO identifier name |

Spectrum FITS files must contain a binary table (extension 1) with columns: `LOGLAM`, `FLUX`, `IVAR`, `MODEL`.

### GUI Layout

The interface has two side-by-side draw windows:

- **Left window (1000×600 px):** Displays the observed-wavelength spectrum centered on the MgII 2796 Å line (±70 Å window), normalized by the continuum. Both MgII 2796 and 2803 lines are overplotted (the 2803 line is shown by applying the `mgii_ratio = 2803.531/2796.352` wavelength offset).
- **Right window (200×600 px):** Displays four velocity-space panels (±1000 km/s) for the four diagnostic lines defined in `rwave`:

| Panel | Rest Wavelength (Å) | Ion |
|-------|---------------------|-----|
| 1 | 2796.352 | MgII 2796 |
| 2 | 2803.531 | MgII 2803 |
| 3 | 2852.963 | MgI 2853 |
| 4 | 2600.173 | FeII 2600 |

### Buttons

| Button | Action |
|--------|--------|
| **Next** | Advance to the next spectrum in the list |
| **Back** | Return to the previous spectrum |
| **Get_EW** | Interactively measure equivalent widths of MgII 2796 and MgII 2803 by cursor selection |
| **Save** | Save current EW measurements to an output `.dat` file |
| **Done** | Exit the program (prompts for confirmation) |

### Equivalent Width Measurement (`Get_EW`)

When `Get_EW` is pressed:

1. The left window zooms in to a ±50 Å window around MgII 2796.
2. The user clicks two cursor positions (x1, x2) to define the integration range for **MgII 2796**. The pixel with the minimum flux within that range is used to refine `zabs1`.
3. The process repeats for **MgII 2803**, yielding `zabs2`.

EW is computed in the rest frame as:

```
EW = Σ [ (1 - flux/conti) × Δλ ] / (1 + zabs)
```

with error:

```
σ_EW = sqrt( Σ [ (sig/conti × Δλ)² ] ) / (1 + zabs)
```

### Output File (`Save`)

Measurements are saved to:

```
{dir_name}/ewzabs_wc_{name}.dat
```

The file contains a one-line header (written only when the file is first created) followed by one data row per `Save` action:

```
#qso_name       z_abs    ew_1    ew_err1   ew_2    ew_err3  ew_1/ew_3
```

| Column | Description |
|--------|-------------|
| `qso_name` | Source name (20 chars) |
| `z_abs` | Mean absorption redshift: `(zabs1 + zabs2) / 2` |
| `ew_1` | Rest-frame EW of MgII 2796 (Å) |
| `ew_err1` | 1σ uncertainty on EW of MgII 2796 (Å) |
| `ew_2` | Rest-frame EW of MgII 2803 (Å) |
| `ew_err3` | 1σ uncertainty on EW of MgII 2803 (Å) |
| `ew_1/ew_3` | EW ratio MgII 2796 / MgII 2803 (expected ~2 for optically thin gas) |

### Common Variables (IDL Common Blocks)

| Common Block | Variables | Description |
|---|---|---|
| `GMW_1` | `dir_name, file, zabs, name, N_Spectra_files, file_index, file1` | File list and current index |
| `GAP` | `wav, flux, sig, conti, rwave, mgii_ratio, w_obs_mgii, id_plot_mgii, n_plot_mgii` | Spectral data and MgII plot indices |
| `GMW_2` | `drawID_LEFT, drawID_RIGHT` | Widget draw window IDs |
| `GVP` | `z, id_plot, n_plot, w_obs` | Velocity plot variables |
| `MVCE` | `ew1, ew2, sigew1, sigew2, zabs1, zabs2` | EW measurements |

### Dependencies

- IDL 8.x or later
- `mrdfits` — FITS binary table reader ([IDL Astronomy User's Library](https://idlastro.gsfc.nasa.gov/))
- `bspline_iterfit` — B-spline fitter ([idlutils](https://www.sdss.org/dr12/software/idlutils/))
- `readcol` — ASCII table reader (IDL Astronomy User's Library)
- `vline` — Vertical line plotting utility (must be available in IDL path)

---

## Workflow

```
Mgii_result.txt
      │
      ▼
mgii_visual_check          ← launch GUI
      │
      ├── reads spectrum FITS file
      ├── calls qso_continuum_fit  (or uses pre-computed MODEL column)
      ├── displays normalized flux in Left window
      ├── displays velocity plots in Right window
      │
      ├── [Get_EW]  →  cursor selection  →  computes EW1, EW2, zabs1, zabs2
      └── [Save]    →  appends to ewzabs_wc_{name}.dat
```

> **Note:** `mgii_visual_check` uses the `MODEL` column already present in the input FITS files as the continuum (`conti`). `qso_continuum_fit` is the standalone function used to *produce* such continuum models from raw spectra.

---

## Notes & Known Issues

- The right-window velocity plots call `get_vel_plot` with `slect_index`, which is not defined in the main scope — this variable should be `file_index`. Verify before use.
- The `Get_EW` cursor interaction requires an interactive IDL session with a live X display; it will not work in batch/non-interactive mode.
- Pixels with `IVAR ≤ 0` or non-finite `IVAR` are automatically excluded from all fits and plots.
- The EW ratio column in the output file header is labeled `ew_1/ew_3` but represents MgII 2796/MgII 2803 (i.e., ew_1/ew_2).
