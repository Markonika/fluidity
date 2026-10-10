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
