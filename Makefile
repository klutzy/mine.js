ALL=mine.js

.PHONY: all
all: $(ALL)

%.js: %.coffee
	coffee -c $<

%.css: %.scss
	sass $< $@

.PHONY: clean
clean:
	rm -rf $(ALL)
