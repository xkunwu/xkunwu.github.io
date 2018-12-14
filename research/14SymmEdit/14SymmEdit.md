---
mathjax: true
---

<div style="color:red">Warning: in progress.</div>

# Real-Time Symmetry-Preserving Deformation
<figure>
    <img src="/research/14SymmEdit/center_piece.jpg">
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

## Symmetry group: a primary introduction
Consider a surface $S$ in $R^{3}$ given by a two-manifold $M$ and an embedding $x:M \mapsto R^{3}$, we are interested in _groups_ induced by _Euclidean motions_:
-   A _group_ $G$ is an algebraic structure consisting of a set of elements, which is closed under a binary operation (_group action_). In our discussion, $G$ consists of Euclidean motions.
-   A _Euclidean motion_ $g$ is an affine map whose linear part is an _orthogonal transformation_. Examples in 3D are translations, reflections, and rotations as well as any composition of these.
-   The _orbit_ of an element $p$ on the surface $S$ is the set of elements in $S$ to which $p$ can be moved by the elements of $G$.

The set of Euclidean motions forms the _Euclidean group_ $E(3)$ under composition of maps.
We consider groups with respect to Euclidean motion, because this leads to useful invariants for man-made shapes.

For our experiments, we use standard triangle meshes as discretization of $S$ in $R^{3}$.
In this case, $M$ is the surface mesh itself, while $x$ is the continuous and piece-wise linear map that maps every vertex to its positions in $R^{3}$.

### Symmetry
An _automorphism_ of $M$ is a map $\varphi:M \mapsto M$ that is a _homeomorphism_, i.e. is continuous, bijective and
has a continuous inverse.
Under the composition of maps, the set of automorphisms of $M$ forms a group that we denote by $\Psi(M)$.
This concept is helpful in the following intrinsic formulation of our discussion.

#### Symmetries of $M$ relate to _subgroups_ of $\Psi(M)$.
Any Euclidean motion $g$ can be composed with the embedding $x$, which results in a new map $g\circ x:M \mapsto R^{3}$.
We are interested in surfaces and motions that the motion maps the surface onto itself.

Loosely speaking, a _(Euclidean) symmetry_ of the embedded surface $(M,x)$ is a subgroup $G$ of $E(3)$ such that every $g\in G$ maps $x(M)$ to itself.
More formally, we say that a subgroup $G\leq E(3)$ is a _symmetry_ of $(M,x)$ if there is a subgroup $\Phi\leq\Psi(M)$ such that for every $g \in G$ there is a $\varphi\in\Phi$ such that

$$
g\circ x=x\circ\varphi
$$

and the map $G\mapsto\Phi$ induced by this relation is a _group isomorphism_.

#### Partial symmetry
In addition to symmetries of the whole surface, we consider symmetries of parts of the surface and call them _partial symmetries_.
This makes the concept more powerful as objects often only exhibit symmetries within local regions.

To define partial symmetries, we consider a _submanifold_ $N$ of $M$, which need not be connected.
Then, the restriction $x_{\large| N}$ of $x$ to $N$ is an embedding of $N$ in $R^{3}$;
a symmetry $G$ of $(N,x_{\large| N})$ is a _partial symmetry of $(M,x)$_.

**Note**: It can take a whole year (or a whole life :wink:) for a Math student to study higher algebra, but this short introduction is enough for understanding the background of our paper.
If you think this discussion is boring: I am going to tease you with a beautiful _dihedral group_ before ending this section:

<figure>
    <img src="/research/14SymmEdit/SnowflakesWilsonBentley.jpg">
    <figcaption>Fig~6: <a href="https://en.wikipedia.org/wiki/Wilson_Bentley">Snowflakes</a> have dihedral group structure.</figcaption>
</figure>

## Symmetry-Preserving Deformation
We describe _deformations_ of the surface by variations of $x$.
For this we use a displacement map $u:M\mapsto R^{3}$. Then, the sum $x+u$ describes the deformed surface.

The resulting set of displacements forms a _vector
space_.
For triangle meshes, deformations are described by the displacements of the _vertices_.
Then, the space of displacements equals $R^{3n}$, where $n$ is the number of vertices.

<figure>
    <img src="/research/14SymmEdit/commutatingRelation2.png">
    <figcaption>Fig~7: If the symmetry transformation commutes with the deformation $x+u$ (the automorphism $\varphi$ in the input domain turns into the extrinsic map $g$ here), the deformed shape $[x+u](M)$ will have the same symmetry as $x(M)$.</figcaption>
</figure>

If we have a group $g$ that describes symmetries of the surface, then a displacement $u$ preserves the symmetry if

$$
g\circ(x+u)=(x+u)\circ \varphi,
$$

where $\varphi$ is the automorphism induced by $g$.
Figure~7 illustrates how this condition induces a symmetry-preserving deformation field.

### The lemma of affine subspace
The basis of our surface modeling scheme is the observation that **the set of all symmetry-preserving displacements forms a subspace of the vector space of all possible displacements** (and thus the set of all possible deformations themselves form an affine space).

> Given a symmetry group $G$ of a surface. The set of symmetry-preserving displacements forms a subspace of the vector space of all displacements.

The formal proof is very easy to follow, so please refer to the paper for the details.

#### The implication of this lemma
Knowing that the solution space is a subspace of discussion domain opens the door to _subspace methods_: now we are certain that the solutions to the problem live in a (usually) much small subspace, which can be found through a _constructive algorithm_, i.e. construct a set of basis that spans the target subspace.
This is basically the essence of all classic and modern numerical optimization techniques that try to **reduce the computation cost through factorization**.

## Subspace method based pipeline
If you follow the discussion to here, then you might already figured out how should our pipeline looks like:

1.  Generate a sparse set of symmetric sampled points on the surface,
1.  Construct a basis on those samples,
1.  Formulate a optimization objective given deformation constraints,
1.  Throw your favorite solver onto that objective,
1.  Lifting the displacements throughout the entire surface.

<figure>
    <img src="/research/14SymmEdit/subspace.jpg">
    <figcaption>Fig~8: Subspace method - computation is limited on a small subset of points, and each of them  is associated with a compact support weighting function.</figcaption>
</figure>

Anyway, there are some details worth to see in the following discussions.

### Symmetric sampling
<figure>
    <img src="/research/14SymmEdit/poisson_dist.jpg">
    <figcaption>Fig~9: Symmetric Poisson disk sampling.</figcaption>
</figure>

As optimization is only performed on that sparse set of points, it's obvious that we want maximal sparsity.
Given a fixed threshold $r$ as input parameter to control density, we use [Poisson disk (blue noise)](https://en.wikipedia.org/wiki/Supersampling#Poisson_disc) sampling as the backbone:

<figure>
    <img src="/research/14SymmEdit/symmetric_sample.jpg">
    <figcaption>Fig~10: An illustration of the sampling procedure.</figcaption>
</figure>

1.  First, a random point $p$ on the mesh $M$ is generated,
1.  To achieve symmetric editing, we analyses the (partial) symmetry structure $G$ and extract all the points that lie on the same orbit,
1.  Then we generate another random sample with a distance larger than $r$ to any of the already sampled points,
1.  Repeat the process until the entire domain is covered.

Here is a sampling example of simple airplane model with two symmetries:

<figure>
    <img src="/research/14SymmEdit/symmetric_sample_plane.png">
    <figcaption>Fig~11: Sampling result of the airplane model.</figcaption>
</figure>

#### Nested and overlapping symmetries
<figure>
    <img src="/research/14SymmEdit/transitive.png">
    <figcaption>Fig~12: Nested and overlapping symmetries are treated by propagating samples along transformations.</figcaption>
</figure>

The same construction also works for nested and overlapping symmetry groups, where the transitive closure of the orbits is considered.
The sampling algorithm generates these points by following and concatenating the local transformations during sampling.
Please take a look at the teaser figure on the top of this page as an example, which has 9 symmetries including nesting and overlapping.

### Basis construction
<figure>
    <img src="/research/14SymmEdit/frame_2p.png">
    <figcaption>Fig~13: The airplane model has only one reflective symmetry.</figcaption>
</figure>

Let us first assume that the shape has only one reflective symmetry: during sampling, we collect the reflections that map every seed point to its counterpart.
These seed points can be used to construct the space of symmetry-preserving displacements of the sampling.

#### Symmetry-preserving displacements of samples
<figure>
    <img src="/research/14SymmEdit/local_frame_symmetry.png">
    <figcaption>Fig~14: Each sample point is associated with a local frame $O$.</figcaption>
</figure>

Notice the following fact: whenever a point $p$ is transformed by a Euclidean motion $g(p)=O(p)+t$, a displacement $u$ of the point is transformed only by the orthogonal matrix $O$.
Hence, we obtain a symmetry-preserving displacement of the sampling by displacing one vertex and propagating the displacement to the orbit of the point using only the orthogonal parts $O$ of the Euclidean motions
$g$ (Fig~14 (a)).

<figure>
    <img src="/research/14SymmEdit/frame_2f.png">
    <figcaption>Fig~15: Determine basis vectors placed at symmetric samples.</figcaption>
</figure>

The orbit of any sample point $p$ has exactly three degrees of freedom that we obtain by applying this procedure to the unit displacements of $p$ into each of the three coordinate directions.
To generate a basis of the space of symmetry-preserving displacements, we construct the three basis vectors for every seed point we placed during sampling.

<figure>
    <img src="/research/14SymmEdit/frame_plane.png">
    <figcaption>Fig~16: Symmetric frame construction for the airplane model.</figcaption>
</figure>

#### Degenerate samples
<figure>
    <img src="/research/14SymmEdit/local_frames_degenrate.png">
    <figcaption>Fig~17: Local frames. Left: If a point lies within a transformation-invariant set, it can have more than one frame $O_1,O_2,...$. Right: The problem can be ignored for points in general position as the contributions of the radially-symmetric basis functions cancel out and the low-pass kernel maintains the band-limitation.</figcaption>
</figure>

A special case occurs if a sampling point is visited more than once but with different local frames $O_i$.
This can happen on transformation-invariant sets, such as the diagonals on the left: Here, we have orbits with four points from eight transformations, and each point has two different frames, differing by a reflection.

The correct solution is obtained by reducing the dimension of the basis to those vectors $v$ for which $O_i v = O_j v$ for all $i,j$, which yields is a linear system of equations.
Notice that due to the random sampling, this is rarely encountered in practice.
In relevant cases, we can perform an SVD reduction of the null space to remove spurious degrees of freedom.

If points do not perfectly overlap but only come close (which is still common close to transformation-invariant sets, see Fig~17 right), we do not need to take special measures --- the contributions of the basis functions cancel out exactly; we only obtain some overhead due to too dense sampling.
The overhead is small as it only occurs at transformation-invariant sets of measure zero (reflection planes, rotation centers, Fig~17 right).
