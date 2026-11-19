SHELL := /bin/bash

.PHONY: build check serve clean

# Typically you’ll use jekyll serve while developing locally and jekyll build when you need to generate the site for production.

build:
	bundle exec jekyll build --verbose

check: build
	bundle exec ruby scripts/check-site.rb

serve:
	bundle exec jekyll serve --incremental

clean:
	rm -rf -- _site
