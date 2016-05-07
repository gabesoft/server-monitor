TEMP := $(shell find . -name ".\#*")


scalastyle-config.xml:
	sbt scalastyleGenerateConfig

scalastyle: scalastyle-config.xml clean-temp
	sbt scalastyle

clean-temp:
	$(RM) $(TEMP)

build: clean-temp
	sbt compile -feature

run: clean-temp
	activator ~run

test: clean-temp
	activator test

test-run: clean-temp
	activator ~test

deploy: clean-temp
	activator clean compile stage

start: deploy
	./target/universal/stage/bin/server-monitor -J-Xms128M -J-Xmx512m -J-server

.PHONY: clean-temp
