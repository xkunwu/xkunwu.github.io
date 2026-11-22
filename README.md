# WU Xiaokun's personal homepage

> This is the code base of [my personal homepage](https://xkunwu.github.io/).

## Why use [GitHub Pages](https://pages.github.com/)?
Markdown is much easier to write - people can concatenate on the content, rather than the messy format tags.
Besides, GitHub is great for code sharing and project management.

## Maintenance docs

- [站点需求文档](docs/requirements.md)
- [站点架构设计文档](docs/architecture.md)

## Check the site

Run `make check` to build the site and review its warnings. It checks the generated page structure, teaching term order and redirects, thumbnail URLs in the teaching catalog and the Research and Projects lists, and local links and resource URLs across all generated HTML. It checks HTML fragments against their targets and leaves `#/` routes in Reveal slide decks to the slide runtime.

Run `bundle exec ruby scripts/site-references-test.rb` to test reference checking with small generated-site fixtures.

To review CI warnings, open the repository’s **Actions** tab, select a **Check site** run, and look for **Site check** in the run summary. The summary groups site reference warnings by generated page and groups specialized warnings by their associated file.

Post-build warnings are advisory and `make check` exits successfully when they are present. A failed Jekyll build returns a nonzero exit status.

**Copyright Notice**: This repo has no "LICENSE", which means ["no permissions"](https://choosealicense.com/no-permission/).
For the formal copyright notice, see [COPYRIGHT](COPYRIGHT.txt).

**Achknowledgement**: I am using [Minimal Mistakes Jekyll theme](https://github.com/mmistakes/minimal-mistakes).
