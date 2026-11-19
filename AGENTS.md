# Repository Guidelines

## Project Structure

This is WU Xiaokun’s personal and academic site, built with Jekyll for GitHub Pages using the Minimal Mistakes theme. Edit home and about content in `pages/`, essays in `essay/`, and section landing pages in `research/research.md`, `projects/projects.md`, and `teach/teach.md`. Research and project media live alongside their content. Teaching directories contain term schedules, slides, and course assets.

Use `_config.yml` for site settings, `_data/navigation.yml` for navigation, and `_layouts/` and `_includes/` for template overrides. Shared images and styles live in `assets/`, with site styles in `assets/css/main.scss`.

## Build and Local Preview

Use the Ruby version in `.ruby-version` (3.4.12) and the Bundler version in `Gemfile.lock`. Run these commands from the repository root in a UTF-8 locale. If needed, run `export LC_ALL=en_US.UTF-8` on macOS or `export LC_ALL=C.UTF-8` on Linux.

- `bundle install` installs the versions in `Gemfile.lock`.
- `make serve` starts Jekyll’s incremental preview at `http://localhost:4000`.
- `make build` runs a verbose Jekyll build and writes the generated site to `_site/`.
- `make check` runs the full build and checks the generated pages, assets, and course redirects in `_site/`.

## Editing Conventions

Use Markdown and YAML front matter for Jekyll pages. Preserve existing permalinks and use two-space indentation for nested YAML. Match surrounding HTML and Liquid indentation, and use four spaces in `assets/css/main.scss`.

Follow the course’s filename pattern for new terms. For example, `A2026H.html` is the autumn Algorithm schedule and `A2024F.html` is the spring schedule. Add the new schedule to its course directory and list its filename and label first under the course’s `terms` in `_data/teaching.yml`. Jekyll uses that first term for the course entry and displays all terms in the listed order. Keep older term pages available at their existing URLs.

## Verification

Run `make check`, then preview changed pages and follow their navigation, media, and download links. For teaching updates, verify that the course index opens the intended term and that linked slides load.

## Commits and Pull Requests

Use short, change-specific commit subjects, following examples in the history such as `ml setup labs` and `exam trainer front page`. In pull requests, summarize the affected pages or terms and record the build and preview checks. Link a related issue when one exists and include a screenshot for visible layout changes.
