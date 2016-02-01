# Projection Kit

<img src="https://raw.github.com/youldash/ProjectionKit/master/Projections/Screenshots/MinimumSpanningTreeIn2D.png" width="100%" />

Projection Kit is a multivariate data projection and visualization toolkit. Developed as part of my Ph.D. research objectives at La Trobe University for the purpose of projecting and visualizing high-dimensional data in lower-dimensions.

The repository contains both Objective-C source code implementations of two algorithms (the generalized Geometric Coordinatizer algorithm, and the Polyhedral Projection algorithm), experimental data files, and visual projections (in both two- and three-dimensional displays).

## Dependencies

Projection Kit was developed for the purpose of visualizing high-dimensional data sets, on top of existing Application Programming Interfaces (APIs) mainly: the Open Graphics Library (OpenGL), Apple's GLKit and Scene Kit APIs.

## Algorithms
The following represents two specific algorithms implementations: the Geometric Coordinatizer, and the Polyhedral Projection algorithms.

### Geometric Coordinatizer
A method for coordinatizing (i.e. geometrically plotting) κ-dimensional points based on converting their pairwise distances in higher-dimensional spaces. 

### Polyhedral Projection
A generalized method for mapping from higher-dimensions in κ-dimensions, κ ≥ 2. Its implementation is based on the implementation of the Geometric Coordinatizer algorithm.

## Sponsors
Projection Kit is sponsored in part by the [College of Computer and Information Systems](http://cis.uqu.edu.sa/) at Umm Al-Qura University, Mecca, Saudi Arabia.

## License

Projection Kit is published under the MIT license. See [LICENSE](https://github.com/youldash/ProjectionKit/blob/master/LICENSE.md) for details.