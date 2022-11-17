# bakery

Serving freshly baked [Eclairs](https://github.com/luc-tielen/eclair-lang) over HTTP.

Bakery is a simple webserver in front of the Eclair compiler that makes it
possible to compile a program by submitting the program via an endpoint, and
getting the compiled WASM program back as a result.

The compiled WASM can be used directly in combination with
[eclair-wasm-bindings](https://github.com/luc-tielen/eclair-wasm-bindings).
