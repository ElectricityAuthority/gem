* GEMchecksums.gms

* This program computes checksums for the designated files.
* It puts the results into a file called checksums.txt in the working directory.
* It calls the cksum utility from the GAMS system directory.

* GEM programs
$call cksum GEMdeclarations.gms  >  "%system.fp%\checksums.txt"
$call cksum GEMdata.gms          >> "%system.fp%\checksums.txt"
$call cksum GEMsolve.gms         >> "%system.fp%\checksums.txt"
$call cksum GEMreports.gms       >> "%system.fp%\checksums.txt"

* GEM input data files
$call cksum "%system.fp%..\Data\GEM2.0 input data (2Reg 9Block mds1).gdx" >> "%system.fp%\checksums.txt"
$call cksum "%system.fp%..\Data\GEM2.0 input data (2Reg 9Block mds2).gdx" >> "%system.fp%\checksums.txt"
$call cksum "%system.fp%..\Data\GEM2.0 input data (2Reg 9Block mds3).gdx" >> "%system.fp%\checksums.txt"
$call cksum "%system.fp%..\Data\GEM2.0 input data (2Reg 9Block mds4).gdx" >> "%system.fp%\checksums.txt"
$call cksum "%system.fp%..\Data\GEM2.0 input data (2Reg 9Block mds5).gdx" >> "%system.fp%\checksums.txt"
