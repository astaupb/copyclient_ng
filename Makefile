include make.mk

.PHONY: format build deploy clean

format:
	dartfmt -w -l 100 --fix .

build:
	pub get && webdev build

build-workaround:
	# This seems to be a workaround for MissingPortFile error
	pub get && pub run build_runner build -o web:build -r

deploy:
	tar czf copyclient.tar.gz build
	scp copyclient.tar.gz ${REMOTE_USER}@${REMOTE_HOST}:/srv/www/
	rm copyclient.tar.gz
	ssh ${REMOTE_USER}@${REMOTE_HOST} "cd /srv/www && tar xzf copyclient.tar.gz && rm -rf copyclient && mv build copyclient && rm copyclient.tar.gz"

clean:
	rm -rf build

i18n_build_arb: build
	### Generating ARB file from @i18n annotated component templates...
	mkdir -p messages
	find . -name '*.dart' -print0 | xargs -0 \
        pub run intl_translation:extract_to_arb \
		--locale de \
		--output-dir messages

i18n_build_code:
	### Generating Dart library with Intl.messages from messages/intl_messages.arb ...
	mkdir -p lib/messages
	find . -name '*.dart' -print0 | xargs -0 \
        pub run intl_translation:generate_from_arb \
		--output-dir lib/messages \
		messages/*
