# rrems

rrems is a pipeline for assembling sequences for reduced representation enzymatic methylation sequences. The assembled sequences are analyzed for methylation and filtered for 10X read depth. The final output is a .cov file with percent methylated at each CG (see .cov file documentation in the [Bismark user guide](http://felixkrueger.github.io/Bismark/Docs/)). 

## Installation

### Singularity

For most high performance computing environments use singularity with the desired version of rrems:
```
singularity build rrems-v0.1.1.sif docker://jadonwagstaff/rrems:v0.1.1
```

### Docker

Alternatively, if docker is installed, download the docker container with the desired version of rrems:
```
docker pull jadonwagstaff/rrems:v0.1.1
```

Access the container in the directory where your data is located:
```
docker run --rm -it -v ${PWD}:/project jadonwagstaff/rrems:testing
```

Your  "project" directory should have all of the same files as the folder from which you accessed the container. Docker can be exited by running ```exit```.

## Use

The main script is rrems.sh. Instructions for use can be found by running ```singularity exec rrems-v0.1.1.sif rrems -h``` or  ```rrems.sh -h``` in the docker container.
