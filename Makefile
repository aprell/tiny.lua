test:
	@cd test && ./test.lua
	@echo "Running expect tests"
	@test/expect.sh

.PHONY: test
