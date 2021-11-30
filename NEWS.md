# rrems v0.1.2

## Backward compatable changes

* countz.sh has an optional 3rd parameter for specifying minimum read depth (default is 10 which was hard coded in previous versions).

# rrems v0.1.1

## Backward compatible changes

* Now supports single end reads.

## Minor changes

* Deletes temporary folder after completion of bismark (TempDelme)

* barcode.awk replaced by faster add_barcodes.py in docker image. (Should not change output.)

# rrems v0.1.0
Pipeline works for paired end reads.
