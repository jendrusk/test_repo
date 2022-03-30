#!/bin/bash

find /srv/mapnik/mod_tile/regions/ -type f -exec touch -t 199001010000  {} \;
