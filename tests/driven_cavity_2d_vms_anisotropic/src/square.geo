// Lid-driven cavity domain, corner-graded initial mesh.
// Base element size away from corners, with finer sizing near all
// four corners so the first adaptivity cycles already have a
// reasonable starting resolution to detect corner vortices from.

lc_base = 0.02;
lc_corner = 0.004;

Point (1) = {0.0, 0.0, 0, lc_corner};
Point (2) = {1.0, 0.0, 0, lc_corner};
Point (3) = {1.0, 1.0, 0, lc_corner};
Point (4) = {0.0, 1.0, 0, lc_corner};

Line (1) = {1, 2};
Line (2) = {2, 3};
Line (3) = {3, 4};
Line (4) = {4, 1};

Line Loop (5) = {1, 2, 3, 4};
Plane Surface (6) = {5};

// Grade mesh size from lc_corner near the four corners back out to
// lc_base over a distance of ~0.15 (comparable to the secondary
// vortex length scale reported in Hachem et al. 2010 / Coupez &
// Hachem 2013).
Field[1] = Distance;
Field[1].NodesList = {1, 2, 3, 4};

Field[2] = Threshold;
Field[2].IField = 1;
Field[2].LcMin = lc_corner;
Field[2].LcMax = lc_base;
Field[2].DistMin = 0.02;
Field[2].DistMax = 0.2;

Background Field = 2;
Mesh.CharacteristicLengthExtendFromBoundary = 0;

// Volume number for whole domain.
Physical Surface (1) = {6};
// Top of the box (the moving lid).
Physical Line(333) = {3};
// Bottom of the box.
Physical Line(444) = {1};
// Side walls.
Physical Line(666) = {2,4};
