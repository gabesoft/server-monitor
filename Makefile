TEMP := $(shell find . -name ".\#*")
CLIENT := client
DIR := $(shell pwd)

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

elm: clean-temp
	activator ~elm

test: clean-temp
	activator test

test-run: clean-temp
	activator ~test

deploy: clean-temp
	activator clean compile stage

start: deploy
	./target/universal/stage/bin/server-monitor -J-Xms128M -J-Xmx512m -J-server

build-elm:
	@cd $(CLIENT) && elm make src/Main.elm --output ../public/javascripts/main-elm.js

install-elm:
	@cd $(CLIENT) && elm package install

link-elm:
	@ln -s -f -v $(DIR)/client $(DIR)/app/assets/elm

.PHONY: clean-temp
