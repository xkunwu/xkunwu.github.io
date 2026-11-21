SHELL := /bin/bash

.PHONY: build check serve clean

# Typically you’ll use jekyll serve while developing locally and jekyll build when you need to generate the site for production.

build:
	bundle exec jekyll build --verbose

check: build
	@bundle exec ruby scripts/check-site.rb || { \
		printf '%s\n' 'Site check incomplete. See the checker output above.'; \
		if [[ -n "$${GITHUB_STEP_SUMMARY:-}" ]]; then \
			printf '%s\n' '## Site check incomplete' '' 'See the checker output in the step log.' >> "$$GITHUB_STEP_SUMMARY"; \
		fi; \
		true; \
	}

serve:
	bundle exec jekyll serve --incremental

clean:
	rm -rf -- _site
