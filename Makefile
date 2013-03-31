ALL=mine.js mine.css mine-win98.css

.PHONY: all
all: $(ALL)

%.js: %.coffee
	coffee -c $<

%.css: %.scss
	sass $< $@

.PHONY: clean
clean:
	rm -rf $(ALL)
