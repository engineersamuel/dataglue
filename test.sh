#!/bin/bash

mocha --require should --compilers coffee:coffee-script -R spec src/dataglue/test/*.coffee

