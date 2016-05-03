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

.PHONY: clean-temp
