# RAW Image Processing Pipeline

A MATLAB pipeline for processing RAW sensor images from Bayer CFA capture through demosaicing and colour correction. Built for the Tel Aviv University Image Sensors Lab (Semester I, Lab Work 3).

---

## Overview

This project implements a full ISP (Image Signal Processing) pipeline on two RAW `.tiff` images:

| Image | Description |
|---|---|
| `natural.tiff` | A naturally-focused scene |
| `outoffocus.tiff` | The same scene captured out-of-focus (used for noise calibration) |

The pipeline covers thirteen tasks, from raw loading to final colour-corrected output.

---

## Pipeline Tasks

### Step 1 — Load Images
Reads both RAW `.tiff` files as `double` arrays.

### Step 2 — Visualise Raw Images & Bayer Mosaic
Displays the raw grayscale images and overlays a false-colour CFA (Colour Filter Array) visualisation using an assumed **RGGB** Bayer pattern.

### Step 3 — Extract Bayer Subchannels
Demultiplexes the interleaved Bayer mosaic into four half-resolution subchannels: **R**, **G1**, **G2**, **B**.

### Step 4 — Mean–Variance Analysis
Uses `blockproc` with a 15×15 sliding window to compute local mean and variance for each subchannel of the out-of-focus image. Produces scatter plots to reveal the signal-dependent noise structure.

### Step 5 — Fit Affine Variance Model
Fits the linear model `variance = a·mean + b` per channel using `robustfit`. The slope `a` relates to photon shot noise gain; the intercept `b` captures read noise.

### Step 6 — Anscombe Transform
Applies the generalised Anscombe transform to stabilise (variance-normalise) the signal:

```
f(x) = 2 · sqrt(x/a + 3/8 + b/a²)
```

Applied to both the natural and out-of-focus images using the per-channel coefficients from Task 5.

### Step 7 — Verify Variance Stabilisation
Repeats the mean–variance scatter plot on the Anscombe-transformed out-of-focus channels to confirm the variance is approximately constant.

### Step 8 — DCT Denoising (Sliding Patch Filter)
Applies a patch-based DCT hard-thresholding filter (Yu & Sapiro style) to the natural image:
- Patch size: **8×8**, stride: **4**
- Threshold: **λ = k · σ** with k = 3
- Run in both the **raw domain** and the **Anscombe-transformed domain**

### Step 9 — Inverse Anscombe Transform
Converts the Anscombe-domain denoised image back to the raw signal domain using the closed-form asymptotically unbiased inverse.

### Step 10 — Compare Denoising Strategies
Side-by-side comparison of:
- Raw-domain DCT denoising
- Anscombe → DCT → Inverse Anscombe denoising

### Step 11 — Simple Demosaicing
Interpolates each Bayer subchannel to full resolution using bilinear (`interp2`) interpolation, with nearest-neighbour fallback for border pixels. The two green channels are averaged to produce the final G plane.

### Step 12 — White Balancing
Balances colour using the **max-V HSV** method: finds the pixel with the highest HSV value (assumed to be white), then normalises each RGB channel by that pixel's reference value.

### Step 13 — Contrast & Saturation Correction
Post-processes the white-balanced images with:
- Contrast stretching
- Saturation boost in HSV space (×1.8)
- Histogram equalisation on the V channel
- Gamma correction (γ = 0.7)

---

## Requirements

- MATLAB R2019b or later
- Image Processing Toolbox (`blockproc`, `imadjust`, `histeq`, `dct2`, `idct2`)
- Statistics and Machine Learning Toolbox (`robustfit`)



