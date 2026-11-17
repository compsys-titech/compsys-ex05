# GNU Make >= 3.81. CC is one executable, not a shell command.
.DEFAULT_GOAL := help
ifeq ($(origin CC),default)
  CC :=
endif
export CC CFLAGS LDFLAGS
export EX05_RUN_TIMEOUT EX05_BUILD_TIMEOUT EX05_OUTPUT_LIMIT

.PHONY: help check examples all test-a test-b test example-adder example-alu test-student clean
ifeq ($(OS),Windows_NT)
SHELL := cmd.exe
help check examples all test-a test-b test example-adder example-alu test-student clean:
	@powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/run.ps1 $@
else
SHELL := /bin/sh
help check examples all test-a test-b test example-adder example-alu test-student clean:
	@sh tools/run.sh $@
endif
