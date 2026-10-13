# Reference data extracted from the two papers, for comparison against this run

Run configuration: Re = 5000 (U_lid = 1, L = 1, nu = 2e-4), 2D lid-driven cavity,
new `direction_magnitude_combined` anisotropic metric (target_nodes=15000),
new `vms` stabilisation scheme.

## 1. Number of resolved (secondary/corner) vortices vs Reynolds number

Hachem, Rivaux, Kloczko, Digonnet, Coupez (2010), JCP 229, Table 2.
("Fine mesh" 180x180, isotropic.)

| Re     | Vortices |
|--------|----------|
| 1,000  | 3        |
| 5,000  | 5        |
| 10,000 | 6        |
| 20,000 | 8        |
| 30,000 | 10       |
| 50,000 | 13       |

**Target for this run (Re=5000): 5 resolved vortices** (1 primary + at least
2 pairs of corner/secondary vortices — bottom-left, bottom-right, and the
onset of further splitting).

## 2. Vortex centre coordinates (Hachem et al. 2010, Tables 3-4)

Coordinates (x, y), "Current" = their computed value, "Reference" = Ghia
et al. (1982) / Erturk et al. for Re <= 20,000.

| Vortex | Re=10,000 (current) | Re=10,000 (reference) |
|--------|---------------------|------------------------|
| V1a (primary)       | (0.5110, 0.5310) | (0.5117, 0.5330) |
| V2a (bottom-right)  | (0.7670, 0.0594) | (0.7656, 0.0586) |
| V2b (bottom-right 2)| (0.9330, 0.0689) | (0.9336, 0.0625) |
| V3a (bottom-left)   | (0.0589, 0.1600) | (0.0586, 0.1641) |
| V3b (bottom-left 2) | (0.0160, 0.0191) | (0.0156, 0.0195) |
| V4a (top-left)      | (0.0710, 0.9110) | (0.0703, 0.9141) |

(Re=5000 rows are not individually tabulated in the paper -- 10,000 is the
first row given -- but the Re=5000 case lies between the Re=1000 3-vortex
state and this Re=10000 6-vortex state, so we expect the two Re=10000
bottom-right vortices V2a/V2b to just be forming / a single still-merged
bottom-right vortex plus a single bottom-left vortex, totalling 5.)

## 3. Velocity profiles at Re=5000 (Coupez & Hachem 2013, Tables 3-9)

Reference solution = isotropic 600x600 mesh (converged); comparison =
their anisotropic adaptive mesh (~10,000 nodes). These are the values to
compare our own Vx/Vy profiles against directly, extracted along the same
cross-sections. The near-wall lines (y=0.05, y=0.99) are the most sensitive
to corner-vortex resolution.

### Vy along y = 0.05 (Table 4), Re = 5000, selected points near the walls
(x, Isotropic Vy, Anisotropic Vy):

| x      | Isotropic  | Anisotropic |
|--------|------------|-------------|
| 1      | 0.0000000  | 0.0000000   |
| 0.995  | 0.0001999  | 0.0002589   |
| 0.99   | 0.0005127  | 0.0006799   |
| 0.98   | 0.0013517  | 0.0017475   |
| 0.9609 | 0.0023451  | 0.0028201   |
| 0.5    | -0.0040949 | -0.0001514  |
| 0.35   | 0.0187300  | 0.0134464   |
| 0.2266 | 0.0130740  | 0.0146643   |
| 0.0625 | 0.0074276  | 0.0038367   |
| 0.01   | -0.0018998 | -0.0019808  |
| 0      | 0.0000000  | 0.0000000   |

### Vx along y = 0.1 (Table 3), Re = 5000, selected points
(x, Isotropic Vx, Anisotropic Vx):

| x      | Isotropic  | Anisotropic |
|--------|------------|-------------|
| 1      | 0.0000000  | 0.0000000   |
| 0.995  | 0.0022609  | 0.0026411   |
| 0.9688 | 0.0113088  | 0.0117912   |
| 0.68   | -0.0310814 | -0.0389244  |
| 0.5    | -0.0072652 | -0.0022773  |
| 0.35   | 0.1331670  | 0.1330430   |
| 0.2266 | 0.1279270  | 0.1247830   |
| 0.0625 | -0.0081142 | -0.0084361  |
| 0.01   | -0.0154073 | -0.0154550  |
| 0      | 0.0000000  | 0.0000000   |

## 4. Pressure extrema (Table 1, Hachem et al. 2010), coarse 64x64, Re=10,000
(not 5000, but included as an order-of-magnitude sanity check)

Present work: p_min = -0.1319, p_max = 0.9142

## How to compare

1. Count distinct closed-streamline regions (vortices) visible in the
   converged Vorticity2D / streamfunction field -- target: 5 at Re=5000.
2. Extract Vx along x=0.5 and Vy along y=0.5 (the standard profile cuts)
   and the near-wall cuts above, and compare point-by-point against the
   anisotropic-mesh columns in Tables 3-9 (Coupez & Hachem 2013).
3. Corner vortex centres (once resolved) can be compared in spirit against
   the pattern in Table 3-4 of Hachem et al. 2010, bearing in mind our Re
   falls between their tabulated 1,000 and 10,000 rows.

## 5. Verified 2D reference quantities (Nika, "Lid-Driven Cavity Flow from
Re=1e2 to 1e6" review, 2026), independent of Hachem/Coupez, derived from
the audited acenumerics benchmark and Burggraf (1966)/Erturk et al. theory

These are the most precise, directly-comparable 2D targets available,
since they are Re=5000-specific and come from a verified numerical
benchmark (not a transcription-error-prone digitisation):

- Core vorticity (Batchelor-Burggraf uniform-vorticity core), Re=5000:
  **|omega_c| = 1.941** (acenumerics, verified), consistent with the
  fitted asymptotic law |omega_c| = 1.870 + 4.99*Re^-1/2 -> 1.9406 at
  Re=5000. Asymptotic value as Re->infinity: 1.886 (Burggraf 1966).
- Centre velocity u(0.5,0.5), Re=5000: **-0.0321** (acenumerics).
- Moffatt (1964) corner-eddy sequence ratios (Re-independent, local
  Stokes-flow theory near a 90-degree corner): successive deep corner
  eddies shrink in size by a factor **16.57** and weaken in
  stream-function magnitude by a factor **3.63e4**; acenumerics
  confirms 16.4-18.3 and (3.5-4.1)e4 respectively. Only resolvable with
  deep, very fine corner mesh refinement (each deeper eddy needs ~17x
  finer local resolution) -- not expected to be visible with our
  current corner refinement (element size ~0.003, versus the
  ~0.0007L needed to resolve a 3rd/4th-order eddy at Re~1000).

**Important caveat on 3D experimental data** (Prasad & Koseff 1989 LDA,
Liberzon et al. 2011 PIV): the review found that real (3D, finite-span)
cavities rotate at only 15-30% of the 2D core vorticity, essentially
independent of Re from 1480 to 7e5, due to end-wall friction (a 2D
solver "agreeing" with 3D experimental centreline data would be agreeing
for the wrong reason). **3D experimental data is therefore not a valid
quantitative target for this 2D code** -- only the 2D numerical/
theoretical references above are.

The review also explicitly recommends regularising the lid-corner
velocity discontinuity for any corner-sensitive validation (its exact
words: "a validation report should state which is done") -- this run
uses the Botella & Peyret (1998) regularised lid profile
u(x) = (1-(2x-1)^8)^2 for exactly this reason.

## 6. Results obtained (this run, final validated configuration:
anisotropic direction+magnitude + vorticity-Hessian metric, smoothed
lid BC, no VMS stabilisation -- see commit history for why VMS was
tried and then disabled)

- Core vorticity at (0.5,0.5): **-1.29** (66% of the verified -1.941
  reference; -1.33 at t=64, -1.29 at t=80 -- converged, not transient).
- u(0.5,0.5): **-0.0206** (64% of the verified -0.0321 reference).
- Primary vortex centre (streamfunction extremum): **(0.513, 0.533)**,
  matching the Hachem et al. Re=10,000 primary at (0.511, 0.531)
  closely (expected to be even closer to centre at our lower Re).
- Distinct secondary vortices resolved: **4** (primary + bottom-left +
  bottom-right + a newly-resolved top-left), up from 3 (primary +
  bottom-left + bottom-right only, top-left undetectable) in the
  initial VMS-stabilised run -- approaching but not yet matching the
  Table 2 target of 5 at Re=5000.
- Velocity profile point comparison (Vx along y=0.1, Vy along y=0.05)
  still shows substantial disagreement with Coupez & Hachem's tabulated
  values in the mid-domain (e.g. sign flips at some stations), despite
  the much-improved core vorticity and vortex count -- the near-wall
  secondary-vortex-driven profile shape is not yet fully converged to
  the papers' pattern.
- For context (ablation, same mesh/BC/metric, VMS self-advection +
  grad-div stabilisation active instead of no_stabilisation): core
  vorticity only -0.59 (30% of reference), only 3 vortices resolved,
  BL/BR corner vorticity visually and quantitatively weaker despite
  being individually larger in this one metric -- VMS was net harmful
  for this problem as implemented, even after a partial fix (adding
  the missing pressure-gradient term to the self-advection residual,
  which closed only part of the gap: -1.06 -> -1.17 at matched time).
