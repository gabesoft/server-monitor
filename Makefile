TEMP := $(shell find . -name ".\#*")
CLIENT := client
DIR := $(shell pwd)
BIN := $(DIR)/node_modules/.bin
ELM = elm
NPM = npm
APP_ASSETS = $(DIR)/app/assets/javascripts
ELM_SRC = $(DIR)/client/src
ELM_BUILD_ARGS := make
ELM_INSTALL_ARGS := package install
WATCH = $(BIN)/chokidar
WATCH_ARGS = "$(ELM_SRC)/*.elm" -c 'make elm-build'

scalastyle-config.xml:
	sbt scalastyleGenerateConfig

scalastyle: scalastyle-config.xml clean-temp
	sbt scalastyle

clean-temp:
	$(RM) $(TEMP)

clean: clean-temp
	activator clean

build: clean-temp
	sbt compile -feature

run: clean-temp elm-build
	activator ~run

test: clean-temp
	activator test

test-run: clean-temp
	activator ~test

deploy: clean-temp elm-clean setup elm-build
	activator clean compile stage

start: deploy
	./target/universal/stage/bin/server-monitor -J-Xms128M -J-Xmx512m -J-server

elm-build: $(APP_ASSETS)/main-elm.js

elm-clean:
	$(RM) -f $(APP_ASSETS)/main-elm.js

elm-install:
	@cd $(CLIENT) && $(ELM) $(ELM_INSTALL_ARGS)

elm-watch:
	$(WATCH) $(WATCH_ARGS)

npm-install:
	@$(NPM) install . -d

setup: elm-install npm-install

$(APP_ASSETS)/main-elm.js: $(ELM_SRC)/Main.elm
	@cd $(CLIENT) && $(ELM) $(ELM_BUILD_ARGS) $(ELM_SRC)/Main.elm --output $(APP_ASSETS)/main-elm.js

.PHONY: clean-temp elm-build
