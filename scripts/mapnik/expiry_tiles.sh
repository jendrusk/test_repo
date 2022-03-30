#Usage: render_expired [OPTION] ...
#  -m, --map=MAP        render tiles in this map (defaults to 'default')
#  -s, --socket=SOCKET  unix domain socket name for contacting renderd
#  -n, --num-threads=N the number of parallel request threads (default 1)
#  -t, --tile-dir       tile cache directory (defaults to '/var/lib/mod_tile')
#  -z, --min-zoom=ZOOM  filter input to only render tiles greater or equal to this zoom level (default is 0)
#  -Z, --max-zoom=ZOOM  filter input to only render tiles less than or equal to this zoom level (default is 18)
#  -d, --delete-from=ZOOM  when expiring tiles of ZOOM or higher, delete them instead of re-rendering (default is off)
#  -T, --touch-from=ZOOM   when expiring tiles of ZOOM or higher, touch them instead of re-rendering (default is off)
#Send a list of tiles to be rendered from STDIN in the format:
#  z/x/y
#e.g.
#  1/0/1
#  1/1/1
#  1/0/0
#  1/1/0
#The above would cause all 4 tiles at zoom 1 to be rendered
# To potrafi tylko renderować kafelki z listy. Bez listy nie da rady


render_expired --map=base --num-threads=8 --min-zoom=13 --max-zoom=13 --touch-from=13


