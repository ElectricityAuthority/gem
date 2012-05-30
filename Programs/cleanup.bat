rem	A batch script to erase unwanted debris from the GEM programs folder.

if exist *.op*                erase *.op* /q
if exist *.ref                erase *.ref /q
if exist temp.bat             erase temp.bat /q
if exist run*.lst             erase run*.lst /q
if exist run*.txt             erase run*.txt /q
if exist GEM*.lst             erase GEM*.lst /q
if exist GEMdata.g00          erase GEMdata.g00 /q
if exist GEMsolve.g00         erase GEMsolve.g00 /q
if exist GEMreports.g00       erase GEMreports.g00 /q
if exist GEMsolve.log         erase GEMsolve.log /q
if exist Report.txt           erase Report.txt /q
if exist VOLLplant.inc        erase VOLLplant.inc /q
if exist *.gdx                erase *.gdx /q
