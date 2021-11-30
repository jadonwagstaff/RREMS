# rrems

rrems is a pipeline for assembling reduced representation enzymatic methylation sequences. The assembled sequences are analyzed for methylation and filtered for 10X read depth. The final output is a .cov file with percent methylated at each CG (see .cov file documentation in the [Bismark user guide](http://felixkrueger.github.io/Bismark/Docs/)). 

## Installation

### Singularity

For most high performance computing environments, use singularity with the desired version of rrems:
```
singularity build rrems-v0.1.2.sif docker://jadonwagstaff/rrems:v0.1.2
```

### Docker

Alternatively, if docker is installed, download the docker container with the desired version of rrems:
```
docker pull jadonwagstaff/rrems:v0.1.2
```

Access the container in the directory where your data is located:
```
docker run --rm -it -v ${PWD}:/project jadonwagstaff/rrems:v0.1.2
```

Your  "project" directory should have all of the same files as the folder from which you accessed the container. Docker can be exited by running ```exit```.

## Use

The main script is rrems.sh. Instructions for use can be found by running ```singularity exec rrems-v0.1.2.sif rrems -h``` or  ```rrems.sh -h``` in the docker container. Examples of use in paired end and single end read context can be found in the utah_chpc_pipelines folder.
