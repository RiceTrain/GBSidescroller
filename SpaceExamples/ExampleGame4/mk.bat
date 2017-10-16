rgbasm95 -zFF -otestGame.obj testGame.asm
xlink95 -tg -zFF -ntestGame.sym -mtestGame.map testGame.lnk
rgbfix95 -v testGame.gb
