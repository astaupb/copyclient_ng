.PHONY: format build deploy clean

format:
	dartfmt -w -l 100 --fix .

build:
	pub get && webdev build
deploy: build
	tar czf copyclient.tar.gz build
	scp copyclient.tar.gz root@shiva:/srv/www/
	rm copyclient.tar.gz
	ssh root@shiva "cd /srv/www && tar xzf copyclient.tar.gz && rm -rf copyclient && mv build copyclient && rm copyclient.tar.gz" 

clean:
	rm -rf build
