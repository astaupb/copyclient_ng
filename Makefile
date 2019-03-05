.PHONY: build deploy clean

build:
	pub get && webdev build
deploy: build
	tar cf copyclient.tar build
	scp copyclient.tar root@shiva:/srv/www/
	rm copyclient.tar
	ssh root@shiva "cd /srv/www && tar xf copyclient.tar && rm -rf copyclient && mv build copyclient && rm copyclient.tar" 

clean:
	rm -rf build
