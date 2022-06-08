SHELL := /bin/bash

# Typically you’ll use jekyll serve while developing locally and jekyll build when you need to generate the site for production.

build:
	bundle exec jekyll build --verbose

serve:
	bundle exec jekyll serve --incremental
