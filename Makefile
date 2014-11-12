all: install import

install:
	bundle

import:
	BUNDLE_GEMFILE=data_load/Gemfile ruby import_domains.rb

.PHONY: import install all
