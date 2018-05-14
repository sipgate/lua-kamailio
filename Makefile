SHELL=/bin/bash
LUA_VERSION=5.1
TARGET=/usr/local/share/lua/$(LUA_VERSION)/
LIBRARY_NAME=kamailio


install: tests
	@echo
	@mkdir -p $(TARGET) || die "Can't create directory $(TARGET)"
	@install -d $(TARGET)/$(LIBRARY_NAME) || die "Can't create directory $(TARGET)/$(LIBRARY_NAME)"
	@install -m 644 src/kamailio/* $(TARGET)/$(LIBRARY_NAME)
	@echo "Library successfully installed."
	@echo "You have to install src/kamailio-basic-kemi-lua.lua manually to the desired directory"
	@echo "and instruct your example Kamailio Kemi config file to use it."

tests:
	which busted || die "No busted installed. Please install busted so we can run unit tests!"
	busted spec/[[:alpha:]]*_spec.lua