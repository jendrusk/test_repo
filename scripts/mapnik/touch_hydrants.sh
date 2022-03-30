#!/bin/bash

find /srv/mapnik/mod_tile/emergency/ -type f -exec touch -t 199001010000  {} \;
