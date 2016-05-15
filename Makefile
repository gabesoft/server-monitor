TEMP := $(shell find . -name ".\#*")
CLIENT := client
DIR := $(shell pwd)
BIN := $(DIR)/node_modules/.bin
ELM = elm
NPM = npm
APP_ASSETS = $(DIR)/app/assets/javascripts
ELM_ASSETS = $(APP_ASSETS)/elm
ELM_SRC = $(DIR)/client/src
ELM_BUILD := make
ELM_INSTALL := package install
ASSETS = $(DIR)/public/javascripts
UGLIFY = $(BIN)/uglifyjs
UGLIFY_ARGS = --compress --mangle
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

elm-run: clean-temp elm-link
	activator ~elm

elm-build: $(APP_ASSETS)/main-elm.js

elm-clean:
	$(RM) -f $(ASSETS)/main-elm.js
	$(RM) -f $(ASSETS)/main-elm.min.js
	$(RM) -f $(APP_ASSETS)/main-elm.js

$(ASSETS)/main-elm.min.js.gz: $(ASSETS)/main-elm.min.js
	@gzip -f -k -9 $(ASSETS)/main-elm.min.js

$(ASSETS)/main-elm.min.js: $(ASSETS)/main-elm.js
	@$(UGLIFY) $(UGLIFY_ARGS) --output $(ASSETS)/main-elm.min.js -- $(ASSETS)/main-elm.js 2> /dev/null

$(ASSETS)/main-elm.js: $(ELM_SRC)/Main.elm
	@cd $(CLIENT) && $(ELM) $(ELM_BUILD) $(ELM_SRC)/Main.elm --output $(ASSETS)/main-elm.js

$(APP_ASSETS)/main-elm.js: $(ELM_SRC)/Main.elm
	@cd $(CLIENT) && $(ELM) $(ELM_BUILD) $(ELM_SRC)/Main.elm --output $(APP_ASSETS)/main-elm.js

elm-install:
	@cd $(CLIENT) && $(ELM) $(ELM_INSTALL)

elm-link:
	@mkdir -p $(ELM_ASSETS)
	@ln -s -f -v $(ELM_SRC) $(ELM_ASSETS)

elm-watch:
	$(WATCH) $(WATCH_ARGS)

npm-install:
	@$(NPM) install . -d

setup: elm-install npm-install


.PHONY: clean-temp elm-build
