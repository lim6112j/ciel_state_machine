# Makefile for CielStateMachine
.PHONY: all deps iex run docs test

# Default target
all: deps iex

# Install dependencies
deps:
	mix deps.get

# Helper function to load .env file
define load_env
	$(eval include .env)
	$(eval export)
endef

# Run the application with IEx
iex:
	$(call load_env)
	iex -S mix

# Run the application without halting
run:
	$(call load_env)
	mix run --no-halt

# Generate documentation
docs:
	mix generate_docs

# Run tests with coverage
test:
	$(call load_env)
	MIX_ENV=test mix coveralls

# Clean the project (optional)
clean:
	mix clean

# Benchmark
bench:
	$(call load_env)
	mix run -e "Benchmark.run(num_cars: 10000, concurrency: 8, num_updates: 10)"
