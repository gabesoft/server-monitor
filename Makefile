TEMP := $(shell find . -name ".\#*")
CLIENT := client
DIR := $(shell pwd)
ELM_ASSETS_SRC = $(DIR)/app/assets/elm/src
ELM_SRC = $(DIR)/client/src 

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

run: clean-temp
	activator ~run

run-elm: clean-temp link-elm
	activator ~elm

test: clean-temp
	activator test

test-run: clean-temp
	activator ~test

deploy: clean-temp build-elm
	activator clean compile stage

start: deploy
	./target/universal/stage/bin/server-monitor -J-Xms128M -J-Xmx512m -J-server

build-elm:
	@cd $(CLIENT) && elm make src/Main.elm --output ../public/javascripts/main-elm.js

install-elm:
	@cd $(CLIENT) && elm package install

link-elm:
	@mkdir -p $(ELM_ASSETS_SRC)
	@ln -s -f -v $(ELM_SRC) $(ELM_ASSETS_SRC)

.PHONY: clean-temp
