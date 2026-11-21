# WU Xiaokun's personal homepage

> This is the code base of [my personal homepage](https://xkunwu.github.io/).

## Why use [GitHub Pages](https://pages.github.com/)?
Markdown is much easier to write - people can concatenate on the content, rather than the messy format tags.
Besides, GitHub is great for code sharing and project management.

## Check the site

Run `make check` to build the site and review its warnings. It checks the generated page structure, teaching term order and redirects, links in every schedule listed under `current` or `archive` in `_data/teaching.yml`, links in Research and Projects entries, and thumbnails in all three lists. Local HTML links are also checked for matching anchors.

To review CI warnings, open the repository’s **Actions** tab, select a **Check site** run, and look for **Site check** in the run summary. The summary groups warnings by source file.

Post-build warnings are advisory and `make check` exits successfully when they are present. A failed Jekyll build returns a nonzero exit status.

**Copyright Notice**: This repo has no "LICENSE", which means ["no permissions"](https://choosealicense.com/no-permission/).
For the formal copyright notice, see [COPYRIGHT](COPYRIGHT.txt).

**Achknowledgement**: I am using [Minimal Mistakes Jekyll theme](https://github.com/mmistakes/minimal-mistakes).
