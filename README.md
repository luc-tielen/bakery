# bakery

Serving freshly baked [Eclairs](https://github.com/luc-tielen/eclair-lang) over HTTP.

Bakery is a simple webserver in front of the Eclair compiler that makes it
possible to compile a program by submitting the program via an endpoint, and
getting the compiled WASM program back as a result.

The compiled WASM can be used directly in combination with
[eclair-wasm-bindings](https://github.com/luc-tielen/eclair-wasm-bindings).

## Running the server

A Dockerfile is provided. Run the following commands to clone this repo, build
the image and run it:

```bash
$ git clone git@github.com:luc-tielen/bakery.git && cd bakery
$ docker build -f Dockerfile . -t bakery
$ bakery λ docker run -p 8080:8080 --rm -it bakery
```
