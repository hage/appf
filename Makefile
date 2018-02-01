RUBY=bundle exec ruby

.PHONY: test

test:
	$(RUBY) test/test-*.rb
