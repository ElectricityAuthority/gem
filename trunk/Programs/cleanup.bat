rem	A batch script to erase unwanted debris from the GEM programs folder.

if exist *.op*               erase *.op* /q
if exist *.ref               erase *.ref /q
if exist temp.bat            erase temp.bat /q
if exist run*.lst            erase run*.lst /q
if exist run*.txt            erase run*.txt /q
if exist GEM*.lst            erase GEM*.lst /q
if exist GEMdata.g00         erase GEMdata.g00 /q
if exist GEMsolve.g00        erase GEMsolve.g00 /q
if exist GEMreports.g00      erase GEMreports.g00 /q
if exist GEMsolve.log        erase GEMsolve.log /q
if exist MIPtrace.txt        erase MIPtrace.txt /q
if exist diffile.gdx         erase diffile.gdx /q
if exist GEM*.gdx            erase GEM*.gdx /q
if exist selected*.gdx       erase selected*.gdx /q
if exist all_selected*.gdx   erase all_selected*.gdx /q
if exist all_Report*.gdx     erase all_Report*.gdx /q
