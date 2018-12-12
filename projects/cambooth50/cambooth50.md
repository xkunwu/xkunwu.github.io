---
---
<div style="color:red">Warning: in progress.</div>

# Camera Booth
> DSLR camera array based human body reconstruction.

<figure>
    <img src="/projects/cambooth50/concept_plan.jpg">
    <figcaption>Concept plan of the project.</figcaption>
</figure>

This is an engineering project aiming at 3D human body reconstruction through [photogrammetry](https://en.wikipedia.org/wiki/Photogrammetry) approach.

Acknowledgment: Most of the (dirty) works done by Deshan Gong, when he was a master student at Uni Bath.
He also provided many beautiful images as source material, which are used/modified for figures on this page.
I co-supervised his master final project with [Mac Yang](http://www.yongliangyang.net/) during the summer of 2018, then helped him to wrap up this project into his final dissertation.
During the prototyping stage (spring of 2018), Prof. [Jieqing Feng](http://www.cad.zju.edu.cn/home/jqfeng/) and his group also gave us many very valuable suggestions, especially during my visit of his group around the end of April.

## Introduction
3D reconstruction is one of major method of modern content creation, which is widely studied in research community and applied in industrial fields like film, game, VR, etc.
Human body reconstruction is one of most important topic, as nowadays people are asking for immersive experiences and interactions.

Photogrammetry route is one of the most mature technology, mainly due too the convenience nature of input 2D image acquisition - using smartphone, for example.
> Photogrammetry is the science of making measurements from photographs, especially for recovering the exact positions of surface points.

But it's a very challenge task to apply photogrammetry algorithms for soft-body reconstruction tasks, including human body reconstruction.
The main difficulties come from the potential movements of the target: if we use a single device to take multiple images of the target, there will be time gaps between each shot.
As even subtle differences can cause misalignment between consecutive shots, which leads to accumulated error in a long sequence and fail the algorithm.

<figure>
    <img src="/projects/cambooth50/config_test.jpg">
    <figcaption>A test configuration.</figcaption>
</figure>

Of course, there are many research works on non-rigid registration to attack this problem, but we focus on solving this problem in a relatively brute-force yet more reliable way - we use multiple cameras to take shots simultaneously.
In this project, we have tested many configurations starting from small number of cameras to a moderate large system consisting of 50 cameras.

## System setup

hardware
synchronization
bandwidth

camera distribution

## Software pipeline
Data processing
software compare
parameter settings

## Results

## Future works
image preprocessing automation
adding cameras specially targeted at face
