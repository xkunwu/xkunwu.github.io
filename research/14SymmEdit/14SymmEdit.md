---
mathjax: true
---

<div style="color:red">Warning: in progress.</div>

# Real-Time Symmetry-Preserving Deformation
<figure>
    <img src="/research/14SymmEdit/CenterPiece.gif">
</figure>

> In PG 2014. Other authors: Xiaokun Wu, Michael Wand, Klaus Hildebrandt, Pushmeet Kohli, Hans-Peter Seidel

<links>
    [<a href="https://github.com/xkunwu/zum-GeoXL35">Code</a>]
    [<a href="/research/14SymmEdit/14SymmEdit.prepress.pdf">Paper</a>]
    [<a href="/research/14SymmEdit/14SymmEdit.slides.pdf">Slides</a>]
    [<a href="/research/14SymmEdit/14SymmEdit.24.mp4">Video</a>]
    [<a href="/research/14SymmEdit/Wu14SymmEdit.txt">BibTex</a>]
</links>

## Abstrct
In this paper, we address the problem of structure-aware shape deformation: We specifically consider deformations that preserve symmetries of the shape being edited. While this is an elegant approach for obtaining plausible shape variations from minimal assumptions, a straightforward optimization is numerically expensive and poorly conditioned. Our paper introduces an explicit construction of bases of linear spaces of shape deformations that exactly preserve symmetries for any user-defined level of detail. This permits the construction of low-dimensional spaces of low-frequency deformations that preserve the symmetries. We obtain substantial speed-ups over alternative approaches for symmetry-preserving shape editing due to (i) the sub-space approach, which permits low-res editing, (ii) the removal of redundant, symmetric information, and (iii) the simplification of the numerical formulation due to hard-coded symmetry preservation. We demonstrate the utility in practice by applying our framework to symmetry-preserving co-rotated iterative Laplace surface editing of models with complex symmetry structure, including partial and nested symmetry.

## Problem statement
Our work is targeted at the problem of _3D content creation_, which is an important step for providing wide variety of artistic data.

<figure>
    <img src="/research/14SymmEdit/bottles.png">
    <figcaption>Fig~1: Maximize variance, while keeping shape structure.
.</figcaption>
</figure>

To create new model, people normally start from a _exist template shape_. Such as these bottles, they look different, but all of the left three are derived from the right most neutral shape.
That relates to human’s ability of abstracting structures, and infer new variance in the mean while.

<figure>
    <img src="/research/14SymmEdit/eiffel.png">
    <figcaption>Fig~2: Symmetry - invariant to spatial transformation.</figcaption>
</figure>

Structural organization is a very natural way for people to understand the target shape. So it is no coincidence that man-made shapes tend to have some prominent structure.
One rigorous mathematical study of shape structure is [symmetry group](https://en.wikipedia.org/wiki/Symmetry_group), which in 3D space basically means _invariant to 3D transformations_.

<figure>
    <img src="/research/14SymmEdit/understand_symmetry.png">
    <figcaption>Fig~3: We need a modeling tool that understands the target shape.</figcaption>
</figure>

We adopt this notion in our work, and use symmetries as our structure representation.
In the case of our content creation problem, we need a modeling tool that can understand the symmetry structure of target shape.

<figure>
    <img src="/research/14SymmEdit/ffd.png">
    <figcaption>Fig~4: Minimal interaction – maximal intended effect. Image source: 3ds Max tutorial.</figcaption>
</figure>

Modern modeling software has greatly improved productivity. For example, in this [FFD](https://en.wikipedia.org/wiki/Free-form_deformation) application, a selected segment can be easily manipulated by very few control points.
But for models with complex symmetry structure, how can we formulate symmetric editing?

## Related work
Before going into the details of our construction, we would like to list some closely related work back in 2014.

<figure>
    <img src="/research/14SymmEdit/related.png">
    <figcaption>Fig~5: Related work (among many others not listed).</figcaption>
</figure>

#### Symmetry detection
The first element is _symmetry detection_, which provides the input to our pipeline.
[Wang et al. 2011](https://onlinelibrary.wiley.com/doi/full/10.1111/j.1467-8659.2011.01885.x) organized symmetries in a hierarchical way for better understanding very complex shape composition.
_Symmetry groups_ are studied in [Tevs et al. 2014](https://dl.acm.org/citation.cfm?id=2601220), which follows a very detailed classification philosophy (our work uses the results provided by this work).

#### Symmetric editing
The seminal work from [Gal et al. 2009](https://dl.acm.org/citation.cfm?id=1531339) uses a feature based description of shape structure, and can keep certain Euclidean invariance through optimization.
Another work by [Kurz et al. 2014](https://onlinelibrary.wiley.com/doi/full/10.1111/cgf.12344) Builds symmetric mapping from a template shape to the target scan data.

#### Interactive editing
For achieving interactive editing, one line of research resort to _subspace method_.
The method restricts the deformation on a predetermined subset of variables, then propagates the motion to the entire mesh.
For example, [Huang et al. 2006](https://dl.acm.org/citation.cfm?id=1142003) builds a coarse control mesh around the original mesh; while [Jacobson et al. 2012](https://dl.acm.org/citation.cfm?id=2185573)'s work, control points can be disconnected.

Our goal is to combine all these ingredients, and propose a generic editing framework.

## Symmetries: group theory
