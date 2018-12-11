---
---

<div style="color:red">Warning: in progress.</div>

# HandMap: Robust hand pose estimation via intermediate dense guidance map supervision
<figure>
    <img src="/research/18HandPose/eccv2018pipeline.png">
</figure>

> In ECCV 2018

<links>
  [<a href="https://github.com/xkunwu/depth-hand">Code</a>]
  [<a href="http://openaccess.thecvf.com/content_ECCV_2018/papers/Xiaokun_Wu_HandMap_Robust_Hand_ECCV_2018_paper.pdf">Paper</a>]
  [<a href="/research/18HandPose/eccv2018poster1813.pdf">Poster</a>]
  [<a href="/research/18HandPose/Wu18HandPose.txt">BibTex</a>]
</links>

## Abstrct
This work presents a novel hand pose estimation framework via intermediate dense guidance map supervision. By leveraging the advantage of predicting heat maps of hand joints in detection-based methods, we propose to use dense feature maps through intermediate supervision in a regression-based framework that is not limited to the resolution of the heat map. Our dense feature maps are delicately designed to encode the hand geometry and the spatial relation between local joint and global hand. The proposed framework significantly improves the state-of-the-art in both 2D and 3D on the recent benchmark datasets.

## Problem statement and motivation
The goal is to accurately estimate hand pose, i.e. 3D location for each joint, given single depth image.

### Why is the topic important?
<figure>
    <img src="/research/18HandPose/interactive-vr.png" alt="Interactive VR" />
    <figcaption><a href="https://www.leapmotion.com/">Image from the web.</a></figcaption>
</figure>

Robust hand pose estimation is essential for emerging applications in human-computer interaction, such as virtual and mixed reality, computer games, and freehand user interfaces.
The hand is also the most flexible and expressive part of human body, so the study of hand poses provides a great source of input to human behavior recognition task, which further benefits studies in computer vision in general.

### Why is the problem difficult?
The difficulties come from several sources:
-   Human skin is relatively uniform in color and surface property, which can only provide weak feature descriptors.
-   Strong ambiguity due to self-similarity between fingers.
-   The area of hands in a full body scale image is often very small, which means low signal-noise ratio.
-   Severe self-occlusion, especially in interactive applications.

### Justify the use of depth image
Traditional computer vision algorithms usually focus on color channels, which can hardly provide robust output given the challenges listed above.
But nowadays depth cameras are becoming much easier accessible (e.g. my $800 laptop in 2016 has a build-in depth camera), which provides extra geometric information in the depth dimension.
Many recent works found that this added accuracy can cope with spatial ambiguity problem well.

## Robustness
sparse vs dense intermediate supervision
### The failure of discriminative approach
confidence score and support of heatmaps
ambiguity, false positives

### Euclidean distance function

### Geodesics

### Approximation

## Framework
Combine detection and regression

## Stand on the shoulder of giants
Our algorithm alone might not fully convince you.
But please note that the core Dense GMS Module in our algorithm is "hot-pluggable": we can easily plug it into other state-of-the-art (SOTA) methods, and achieve better performance due to added robustness.
Please check the paper for details about performance enhancements.

In short: the best of our standalone algorithms is roughly comparable to the SOTA, but we achieved much better performance after combined our algorithms with the SOTA.

## "Forthcoming Research" already came
In the poster that I prepared for the ECCV2018 conference, you can see that:
> Future work will explore temporal hand tracking using our framework ...

Well, actually this has already been realized.
Please visit the [hand tracking project](https://xkunwu.github.io/projects/depth-hand/depth-hand/) if you are interested.
