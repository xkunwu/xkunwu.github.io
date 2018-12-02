SHELL := /bin/bash

build:
	bundle exec jekyll build --verbose

serve:
	bundle exec jekyll serve --incremental
