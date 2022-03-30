#!/bin/bash

find /var/lib/mod_tile/default/13/ -type f -exec touch -t 199001010000  {} \;
find /var/lib/mod_tile/default/14/ -type f -exec touch -t 199001010000  {} \;