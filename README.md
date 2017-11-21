# MQTT.jl

[![Build Status](https://travis-ci.org/kivaari/MQTT.jl.svg?branch=master)](https://travis-ci.org/kivaari/MQTT.jl)
[![Coverage Status](https://coveralls.io/repos/github/kivaari/MQTT.jl/badge.svg?branch=master)](https://coveralls.io/github/kivaari/MQTT.jl?branch=master)

MQTT Client Library

## How to install
#### Using Julia's package manager 
```julia
Pkg.clone("https://github.com/kivaari/MQTT.jl.git")
Pkg.test("MQTT")
```
#### Manually
```julia
# Add the src folder to the load path inside the .juliarc.jl
push!(LOAD_PATH, "~/MQTT.jl/src")
```

```sh
# Run runtests.jl inside the test dir
~/MQTT.jl/test/$ julia runtests.jl
```
