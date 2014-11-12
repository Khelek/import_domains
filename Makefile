all: install import

install:
	git pull origin master
	bundle install

import:
	BUNDLE_GEMFILE=data_load/Gemfile ruby import_domains.rb

.PHONY: import install all
