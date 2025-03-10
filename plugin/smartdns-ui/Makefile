
# Copyright (C) 2018-2023 Ruilin Peng (Nick) <pymumu@gmail.com>.
#
# smartdns is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# smartdns is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
BIN=smartdns-ui
PREFIX := /usr
SBINDIR := $(PREFIX)/sbin
SLIBDIR := $(PREFIX)/lib
DESTDIR :=
SMARTDNS_SRC_DIR=../../src

# Default to native target if not specified
TARGET ?= $(shell rustc -vV | grep host | cut -d' ' -f2)
CARGO_TARGET = $(TARGET)

ifdef DEBUG
CARGO_BUILD_TYPE=
CARGO_BUILD_PATH=target/$(CARGO_TARGET)/debug
SMARTDNS_BUILD_TYPE=DEBUG=1
else
CARGO_BUILD_TYPE=--release
CARGO_BUILD_PATH=target/$(CARGO_TARGET)/release
SMARTDNS_BUILD_TYPE=
endif

.PHONY: all clean install $(BIN)

all: $(BIN)

test-prepare:
	$(MAKE) -C $(SMARTDNS_SRC_DIR) libsmartdns-test.a

$(BIN):
	@echo "CARGO_TARGET=$(CARGO_TARGET)"
	@echo "CARGO_BUILD_PATH=$(CARGO_BUILD_PATH)"
	MAKEFLAGS= cargo build $(CARGO_BUILD_TYPE) --target=$(CARGO_TARGET) --features "build-release"
	@if [ ! -f "$(CARGO_BUILD_PATH)/libsmartdns_ui.so" ]; then \
		echo "Error: $(CARGO_BUILD_PATH)/libsmartdns_ui.so not found"; \
		ls -l $(CARGO_BUILD_PATH) || echo "Directory $(CARGO_BUILD_PATH) does not exist"; \
		exit 1; \
	fi
	@echo "Copying $(CARGO_BUILD_PATH)/libsmartdns_ui.so to target/"
	cp $(CARGO_BUILD_PATH)/libsmartdns_ui.so target/

install: $(BIN)
	install -v -m 0644 -D -t $(DESTDIR)$(SLIBDIR)/smartdns target/libsmartdns_ui.so

test: test-prepare
	MAKEFLAGS= cargo test --target=$(CARGO_TARGET)

clean:
	cargo clean
	$(MAKE) -C $(SMARTDNS_SRC_DIR) clean
	rm -rf target/libsmartdns_ui.so