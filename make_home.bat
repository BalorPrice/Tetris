chdir "F:\Program Files (x86)\pyz80"
xcopy "F:\Dropbox\Wombles\Game conversions\Archived\Tetris" "F:\Program Files (x86)\pyz80\test" /E /C /Q /R /Y
pyz80.py -I test/samdos2 -D DEBUG --exportfile=symbol.txt --mapfile=auto.map test/auto.asm
del /Q "F:\Program Files (x86)\pyz80\test\*.*"
move /Y "F:\Program Files (x86)\pyz80\auto.dsk" "F:\Dropbox\Wombles\Game conversions\Archived\Tetris\auto.dsk"
move /Y "F:\Program Files (x86)\pyz80\symbol.txt" "F:\Dropbox\Wombles\Game conversions\Archived\Tetris\symbol.txt"
move /Y "F:\Program Files (x86)\pyz80\auto.map" "F:\Dropbox\Wombles\Game conversions\Archived\Tetris\auto.map"
"F:\Dropbox\Wombles\Game conversions\Archived\Tetris\auto.dsk"