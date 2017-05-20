{ pkgs }:

''
  alt - return        : open -b com.apple.Terminal ""
  alt - j             : kwmc window -f west
  alt - k             : kwmc window -f south
  alt - l             : kwmc window -f north
  alt - 0x29          : kwmc window -f east
  alt - space         : kwmc config focus-follows-mouse toggle

  alt + shift - j     : kwmc window -m west
  alt + shift - k     : kwmc window -m south
  alt + shift - l     : kwmc window -m north
  alt + shift - 0x29  : kwmc window -m east

  alt - f             : kwmc window -z fullscreen
  alt - v             : kwmc display -c vertical
  alt - h             : kwmc display -c horizontal
  alt - r             : print "maybe with prefix?"

  alt - e             : kwmc window -c type bsp
  alt - s             : kwmc window -c type monocle
  alt - w             : kwmc window -c type monocle

  alt + shift - space : kwmc window -t focused

  alt - 1             : kwmc space -fExperimental 2
  alt - 2             : kwmc space -fExperimental 3
  alt - 3             : kwmc space -fExperimental 4
  alt - 4             : kwmc space -fExperimental 5
  alt - 5             : kwmc space -fExperimental 6
  alt - 6             : kwmc space -fExperimental 7

  alt + shift - 1     : kwmc window -m space 1
  alt + shift - 2     : kwmc window -m space 2
  alt + shift - 3     : kwmc window -m space 3
  alt + shift - 4     : kwmc window -m space 4
  alt + shift - 5     : kwmc window -m space 5
  alt + shift - 6     : kwmc window -m space 6

  alt + shift - c     : kwmc config reload
  alt + shift - r     : kwmc quit
  alt + shift - e     : kwmc quit
''
