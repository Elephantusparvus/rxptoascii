This script converts laserscans in the rxp-format to ascii with the help of SLAM6D and the riegl library.

You need to have a SLAM6D version linked against the riegl library.

When running the program you have to specify the path of the riegl project, the
path of the slam6d binary, the output directory for the renamed rxp scans and
the output directory for the ascii converted scans.

The script iterates through all ScanPos folders of a RIEGL-Laserscan project
and converts one scan per pose(the last recorded) to ascii-format using slam6d
linked against the riegl library.
Each scan is saved to the defined folder with the following format:
scan[PosNr].txt ($PosNr is the three digit number of the ScanPos)

Usage:
./rxptoascii /path/to/rieglproj/ /path/to/slam6d /path/to/renamedrxpdir /path/to/asciidir

/path/to/rieglproj/ (root directory of the scan project)
/path/to/slam6d/ (root directory of slam6d)
/path/to/renamedrxpdir/ (will contain copies of the rxp renamed to scanXXX.rxp)
/path/to/asciidir (will contain the asciiconverted scans)


Example:
./rxptoascii.sh /path/to/rieglproj/ /path/to/slam6d /path/to/renamedrxpdir /path/to/asciidir

Example for scanpos001:
/path/to/rieglproj/SCANS/ScanPos001/SINGLESCANS/160624_120918.rxp

results in:
/path/to/rxpdir/scan001.rxp
and
/path/to/asciidir/scan001.3d
