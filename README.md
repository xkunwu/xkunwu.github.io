# WU Xiaokun's personal homepage

> This is the code base of [my personal homepage](https://xkunwu.github.io/).

## Why use [GitHub Pages](https://pages.github.com/)?
Markdown is much easier to write - people can concatenate on the content, rather than the messy format tags.
Besides, GitHub is great for code sharing and project management.

## Check the site

Run `make check` to build the site and review its warnings. It checks the generated page structure, teaching term order and redirects, links in every schedule listed under `current` or `archive` in `_data/teaching.yml`, links in Research and Projects entries, and thumbnails in all three lists. Local HTML links are also checked for matching anchors.

The terminal and the GitHub Actions **Site check** summary group warnings by source file. Post-build warnings are advisory and `make check` exits successfully when they are present. A failed Jekyll build returns a nonzero exit status.

### Historical teaching links to fix

The first check of all listed schedules flagged 47 links to missing or empty targets across 16 historical schedules. Relative URLs below are resolved from the schedule that links to them.

<details>
<summary>47 links to review</summary>

- [`teach/Algorithm21H/A2021H.html`](teach/Algorithm21H/A2021H.html)
  - `https://xkunwu.github.io/teach/Algorithm/2021H.html`
- [`teach/Algorithm21H/A2022H.html`](teach/Algorithm21H/A2022H.html)
  - `https://xkunwu.github.io/teach/Algorithm/2022H.html`
- [`teach/Algorithm21H/A2023H.html`](teach/Algorithm21H/A2023H.html)
  - `https://xkunwu.github.io/teach/Algorithm/`
- [`teach/Algorithm21H/A2024F.html`](teach/Algorithm21H/A2024F.html)
  - `https://xkunwu.github.io/teach/Algorithm/`
- [`teach/Algorithm21H/A2024H.html`](teach/Algorithm21H/A2024H.html)
  - `https://xkunwu.github.io/teach/Algorithm/`
- [`teach/Algorithm21H/A2025H.html`](teach/Algorithm21H/A2025H.html)
  - `https://xkunwu.github.io/teach/Algorithm/`
- [`teach/DeepLearning22F/DL2022F.html`](teach/DeepLearning22F/DL2022F.html)
  - `raster/S01.dl22f_intro.pdf`
  - `raster/S02.preliminaries.pdf`
  - `raster/S03.linear_model.pdf`
  - `raster/S04.perceptrons.pdf`
  - `raster/S04.overfit.pdf`
  - `raster/S05.deep_computation.pdf`
  - `raster/S06.convolutional.pdf`
  - `raster/S07.modern_cnn.pdf`
  - `raster/S08.vision_I.pdf`
  - `raster/S09.vision_II.pdf`
  - `raster/S10.recurrent.pdf`
  - `raster/S10.modern_rnn.pdf`
  - `raster/S12.sequence_I.pdf`
  - `raster/S11.attention.pdf`
  - `raster/S11.transformers.pdf`
- [`teach/DeepLearning22F/DL2023F.html`](teach/DeepLearning22F/DL2023F.html)
  - `../MachineLearning23f/`
  - `../SpeechLanguage22S/`
- [`teach/EmbeddedSystem24/STM2024H.html`](teach/EmbeddedSystem24/STM2024H.html)
  - `../media/stm32/led_rock.mp4`
  - `../media/stm32/led_breath.mp4`
  - `../media/stm32/wheel_speed.mp4`
  - `../media/stm32/stand_soft.mp4`
  - `../media/stm32/reduce_oscillations.mp4`
  - `../media/stm32/resist_push.mp4`
- [`teach/Graphics21H/CG2021H.html`](teach/Graphics21H/CG2021H.html)
  - `S01.introduction.html`
- [`teach/MachineLearning23/ML2023F.html`](teach/MachineLearning23/ML2023F.html)
  - `../DeepLearning22S/`
  - `../SpeechLanguage22S/`
- [`teach/MachineLearning23/ML2024F.html`](teach/MachineLearning23/ML2024F.html)
  - `../DeepLearning22S/`
  - `../SpeechLanguage22S/`
  - `raster/S04.feed_forward`
  - `../DeepLearning22F/raster/S09.vision_I`
  - `../DeepLearning22F/raster/S09.vision_II`
- [`teach/MachineLearning23/ML2024H.html`](teach/MachineLearning23/ML2024H.html)
  - `../DeepLearning22S/`
  - `../SpeechLanguage22S/`
  - `raster/S04.feed_forward`
- [`teach/MachineLearning23/ML2025H.html`](teach/MachineLearning23/ML2025H.html)
  - `../DeepLearning22S/`
  - `../SpeechLanguage22S/`
  - `raster/S04.feed_forward`
- [`teach/SpeechLanguage22F/NLP2022F.html`](teach/SpeechLanguage22F/NLP2022F.html)
  - `../DeepLearning22F/raster/S10.recurrent.pdf`
  - `../DeepLearning22F/raster/S10.modern_rnn.pdf`
- [`teach/SpeechLanguage22F/NLP2023F.html`](teach/SpeechLanguage22F/NLP2023F.html)
  - `../MachineLearning23f/`
  - `../DeepLearning22S/`

</details>

**Copyright Notice**: This repo has no "LICENSE", which means ["no permissions"](https://choosealicense.com/no-permission/).
For the formal copyright notice, see [COPYRIGHT](COPYRIGHT.txt).

**Achknowledgement**: I am using [Minimal Mistakes Jekyll theme](https://github.com/mmistakes/minimal-mistakes).
