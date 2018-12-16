SHELL := /bin/bash

build:
	# Typically you’ll use jekyll serve while developing locally and jekyll build when you need to generate the site for production.
	bundle exec jekyll build --verbose

serve:
	bundle exec jekyll serve --incremental
