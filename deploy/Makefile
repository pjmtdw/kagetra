BASE=../public/js
R_JS=../node_modules/requirejs/bin/r.js
COFFEE=../node_modules/coffee-script/bin/coffee
COMPILED=$(BASE)/kagetra.min.js
SRC=$(wildcard $(BASE)/*.coffee)
JS=$(SRC:.coffee=.js)
all:$(COMPILED)

$(COMPILED): $(JS)
	$(R_JS) -o build.js

%.js: %.coffee
	$(COFFEE) -c $<
clean:
	rm -f $(COMPILED) $(JS)
