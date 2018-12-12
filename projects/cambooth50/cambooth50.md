---
---
<div style="color:red">Warning: in progress.</div>

# Camera Booth
> DSLR camera array based human body reconstruction.

<figure>
    <img src="/projects/cambooth50/concept_plan.jpg">
    <figcaption>Fig~1: Concept plan of the project.</figcaption>
</figure>

This is an engineering/experimental/student training project aiming at 3D human body reconstruction through [photogrammetry](https://en.wikipedia.org/wiki/Photogrammetry) approach.

Acknowledgment: Most of the (dirty) works done by Deshan Gong, when he was a master student at Uni Bath.
He also provided many beautiful images as raw materials, which are used/modified for figures on this page.
I co-supervised his master final project with [Mac Yang](http://www.yongliangyang.net/) during the summer of 2018, then helped him to wrap up this project into his final dissertation.
During the prototyping stage (spring of 2018), Prof. [Jieqing Feng](http://www.cad.zju.edu.cn/home/jqfeng/) and his students also gave us many very valuable suggestions, especially during my visit of his lab in the end of April.

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
    <figcaption>Fig~2: A test configuration.</figcaption>
</figure>

Of course, there are many research works on non-rigid registration to attack this problem, but we focus on solving this problem in a relatively brute-force yet more reliable way - we use multiple cameras to take shots simultaneously.
In this project, we have tested many configurations starting from small number of cameras to a moderate large system consisting of 48 cameras.

## System setup
The studio of [CAMERA group](https://www.camera.ac.uk/) roughly looks like this:

<figure>
    <img src="/projects/cambooth50/camera_studio.jpg">
    <figcaption>Fig~3: The CAMERA studio.</figcaption>
</figure>

To cover the target's full body in as many view directions as possible, we spatially partition the poles into 8 uniformly distributed groups (imagine from the top view of Fig~1).
Each group contains the same number of cameras: we start from a simple 16-camera configuration, then gradually add cameras until the final 48-camera configuration.
All the 8 groups are hardware chained together into a ring structure, and then connected to the server/power supply/shutter trigger.

### Hardware connections

#### Attach cameras to the pole
<figure>
    <img src="/projects/cambooth50/attach_camera.jpg">
    <figcaption>Fig~4: Camera attachment steps.</figcaption>
</figure>

Standard socket-clamps are used to attach cameras to the poles.

#### Wiring interface
<figure>
    <img src="/projects/cambooth50/canon1300D.jpg">
    <figcaption>Fig~5: The cameras used in our project.</figcaption>
</figure>

We use the same model of entry-level cameras in our project, which has three types of interfaces that we care:
-   Trigger port for trigger shutter,
-   Mini USB port for data transfer,
-   Power directly supplied from the fixed socket (we do not use batteries since we want to prevent sudden power-run-out-of problem).

#### Hardware synchronization
This is the biggest headache: we need to make sure the shutter of all the cameras are triggered simultaneously.
After some research, we decided to go for commercial solution:

<figure>
    <img src="/projects/cambooth50/trigger_box.jpg">
    <figcaption>Fig~6: Trigger boxes for signal amplification.</figcaption>
</figure>

These trigger boxes are basically deconcentrator, which sends the input trigger signal to several outlets.
It can also act as relay, which amplify the input signal and pass onto the next hub.
So we can build a hierarchical connection structure to host all the cameras, when the total number is greater than outlets on a single hub.

#### Data bandwidth
The data cables should connected to USB hubs in a hierarchical structure, which gather all the links together into the USB ports of the server.
But there is a bandwidth issue: a single USB port can only handle up to 16 data cables that topologically connected to it.
As there are usually 2 USB ports on a single PCI-e card, we mounted two extra PCI-e cards onto our server, which can handle a maximum of 48 cameras simultaneously.

Also, the USB standard only allow a maximum of 3 level hubs daisy chained together, while the maximum USB cable length allowed is 5m, so there is a upper limit of 20m that data cable can reach.
It's not a problem in our case, as our studio is 6x7m.
But people who are interested might need to consider that cables are best go along peripheral boundary, if you do not want messy cables go along your room.

#### Camera distribution
<figure>
    <img src="/projects/cambooth50/single_group.jpg">
    <figcaption>Fig~7: Cameras in a single group.</figcaption>
</figure>

Here comes the first version of our capture system in full size: Fig~7 shows the camera numbering rule within a single group out of 8 groups in total.

A sample shot of our model "Dotty" is shown below:

<figure>
    <img src="/projects/cambooth50/dotty.jpg">
    <figcaption>Fig~8: A shot of Dotty.</figcaption>
</figure>

## Software pipeline
Programming is not the major concern in this training project, so we compared reconstruction quality of two well-known software:
-   [PhotoScan](http://www.agisoft.com/),
-   [COLMAP](https://colmap.github.io/).

### Data preprocessing

[video](https://youtu.be/Mm1DMJK_04k)

software compare
parameter settings

## Results

## Future works
image preprocessing automation
adding cameras specially targeted at face: stereo pair.
