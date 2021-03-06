help: Makefile
	@awk -F':.*?##' '/^[a-z0-9\\%!:-]+:.*##/{gsub("%","*",$$1);gsub("\\\\",":*",$$1);printf "\033[36m%8s\033[0m %s\n",$$1,$$2}' $<

ci: lib deps ## Run CI scripts
	@npm run test -- --color

deps: package*.json
	@(((ls node_modules | grep .) > /dev/null 2>&1) || npm i) || true
