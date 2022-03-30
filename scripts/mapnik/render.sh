#!/bin/bash

#wz�r
#render_list-rect.pl <zref> <x0> <x1> <y0> <y1> <z0> <z1>

# ostrzesz�w
#http://b.tile.openstreetmap.org/13/4414/2589.png

# twrdosin
#http://c.tile.openstreetmap.org/13/4659/2816.png


#./render_list-rect.pl 15  18165 10908 11212 1 17

nice --adjustment=10 ./render_list-rect.pl 10 549 576 325 353 1 13 -n 2 -m ajt
