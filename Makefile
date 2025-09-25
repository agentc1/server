# Verified Telnet Broadcast Server Makefile

PROFILE ?= Jorvik
ADCF := config/profiles/gnat_$(shell echo $(PROFILE) | tr A-Z a-z).adc
PORT ?= 2323

# Default target - build the server
all: build

# Build the telnet server
build:
	gprbuild -P server_starter.gpr

# Run the telnet server
run: build
	@echo "Starting telnet server on port $(PORT)"
	@echo "Connect with: telnet localhost $(PORT)"
	./bin/telnet_server

# Run server in background for testing
run-bg: build
	@echo "Starting telnet server in background on port $(PORT)"
	./bin/telnet_server &
	@echo "Server PID: $$!"
	@echo "Connect with: telnet localhost $(PORT)"
	@echo "Stop with: make stop"

# Stop background server
stop:
	@pkill -f telnet_server || echo "No server running"

# Set runtime profile (Ravenscar, Jorvik, or custom)
profile:
	@if [ "$(PROFILE)" = "custom" ]; then \
		echo "Using custom real-time configuration"; \
		cp config/profiles/gnat_relaxed.adc gnat.adc || echo "Creating custom config..."; \
		echo "-- Custom real-time configuration for telnet server" > gnat.adc; \
		echo "pragma Task_Dispatching_Policy (FIFO_Within_Priorities);" >> gnat.adc; \
		echo "pragma Locking_Policy (Ceiling_Locking);" >> gnat.adc; \
		echo "pragma Assertion_Policy (Check);" >> gnat.adc; \
		echo "pragma Restrictions (Max_Task_Entries => 1);" >> gnat.adc; \
		echo "pragma Restrictions (No_Abort_Statements);" >> gnat.adc; \
		echo "pragma Restrictions (No_Dynamic_Priorities);" >> gnat.adc; \
		echo "pragma Restrictions (No_Task_Hierarchy);" >> gnat.adc; \
		echo "pragma Restrictions (Max_Protected_Entries => 1);" >> gnat.adc; \
	else \
		cp $(ADCF) gnat.adc && echo "Using profile $(PROFILE)"; \
	fi

# Run formal verification
prove:
	gnatprove -P server_starter.gpr --mode=all --level=2 -j0 --report=all

# Quick proof check (faster)
check:
	gnatprove -P server_starter.gpr --mode=flow -j0

# Test the server with multiple clients
test: build
	@echo "Testing telnet broadcast server..."
	@echo "Starting server in background..."
	@./bin/telnet_server & \
	SERVER_PID=$$!; \
	sleep 2; \
	echo "Testing basic connectivity..."; \
	if command -v nc >/dev/null 2>&1; then \
		echo "Testing with netcat..."; \
		echo "test message" | nc localhost $(PORT) >/dev/null 2>&1 && echo "✅ Server accepts connections" || echo "❌ Server not responding"; \
	else \
		echo "netcat not available, manual test required"; \
	fi; \
	echo "Stopping test server..."; \
	kill $$SERVER_PID 2>/dev/null || true; \
	sleep 1

# Clean build artifacts
clean:
	rm -rf obj bin gnatprove gnatprove.out

# Full clean (including profile config)
distclean: clean
	rm -f gnat.adc

# Show project status
status:
	@echo "=== Telnet Broadcast Server Status ==="
	@echo "Profile: $$(if [ -f gnat.adc ]; then head -1 gnat.adc | sed 's/pragma Profile (\(.*\));/\1/'; else echo 'None set'; fi)"
	@echo "Source files: $$(find src src_boundary -name '*.ads' -o -name '*.adb' | wc -l | tr -d ' ')"
	@echo "Build status: $$(if [ -f bin/telnet_server ]; then echo '✅ Built'; else echo '❌ Not built'; fi)"
	@echo "Server running: $$(if pgrep -f telnet_server >/dev/null; then echo '✅ Running'; else echo '❌ Stopped'; fi)"
	@echo ""
	@echo "Usage:"
	@echo "  make build     - Build the server"
	@echo "  make run       - Run interactively"
	@echo "  make run-bg    - Run in background"
	@echo "  make test      - Basic connectivity test"
	@echo "  make prove     - Run formal verification"
	@echo "  make stop      - Stop background server"

# Development shortcuts
dev: profile build prove
	@echo "Development environment ready!"

# Install git hooks for proof-gated commits
hooks:
	git config core.hooksPath scripts/hooks
	@echo "Git hooks installed - commits now require proofs to pass"

# Remove git hooks
unhooks:
	git config --unset core.hooksPath
	@echo "Git hooks removed"

# Help target
help:
	@echo "Verified Telnet Broadcast Server Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  build      - Build the telnet server"
	@echo "  run        - Run server interactively (Ctrl+C to stop)"
	@echo "  run-bg     - Run server in background"
	@echo "  stop       - Stop background server"
	@echo "  test       - Basic connectivity test"
	@echo ""
	@echo "Configuration:"
	@echo "  profile    - Set runtime profile (PROFILE=Ravenscar|Jorvik|custom)"
	@echo "  dev        - Set profile + build + prove (development setup)"
	@echo ""
	@echo "Verification:"
	@echo "  prove      - Run full formal verification"
	@echo "  check      - Quick flow analysis"
	@echo ""
	@echo "Git integration:"
	@echo "  hooks      - Enable proof-gated commits"
	@echo "  unhooks    - Disable proof-gated commits"
	@echo ""
	@echo "Maintenance:"
	@echo "  clean      - Remove build artifacts"
	@echo "  distclean  - Remove build artifacts + config"
	@echo "  status     - Show project status"
	@echo ""
	@echo "Variables:"
	@echo "  PROFILE=Ravenscar|Jorvik|custom (default: Jorvik)"
	@echo "  PORT=2323 (default port for server)"
	@echo ""
	@echo "Example workflows:"
	@echo "  make dev                    # Setup development environment"
	@echo "  make PROFILE=custom build   # Build with custom profile"
	@echo "  make run PORT=2324          # Run on different port"

.PHONY: all build run run-bg stop profile prove check test clean distclean status dev hooks unhooks help