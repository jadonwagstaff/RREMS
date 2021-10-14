import argparse

### arguments ###
parser = argparse.ArgumentParser(description='this script grabs the barcode from one fastq file and pairs it with the read in fastq file with the actual data')
parser.add_argument('-d','--dataFile', help='name of file with sequencing data',required=True)
parser.add_argument('-b','--barcodeFile', help='name of file with barcodes',required=True)
parser.add_argument('-o','--outputFileName', help='output file name',required=True)
parser.add_argument('-s','--sampleName', help='sample name',required=True)
parser.add_argument('-n','--barcodeSize', help='size of barcode',required=True)


### parsing arguments ###
args = vars(parser.parse_args())

dataFileName=str(args['dataFile'])
barcodeFileName=str(args['barcodeFile'])
outputFileName=str(args['outputFileName'])
sampleName=str(args['sampleName'])
barcodeSize=int(args['barcodeSize'])


# make dictionary of barcodes
barcodeDict={}
with open(barcodeFileName,"r") as barcodeFile:
	barcodeCodeData=barcodeFile.readlines()

	for i in range(0,len(barcodeCodeData),1):
		line=barcodeCodeData[i]
		if i % 4 == 0:
			readName=line.strip("\n").split(" ")[0]
			barcode=barcodeCodeData[i+1].rstrip()[:barcodeSize] # this script also grabs the specified length of barcode
			barcodeDict[readName]=barcode


# add barcodes to data file
with open(dataFileName, "r") as dataFile:

	with open(outputFileName,"w") as outFile:

		i = 0
		for line in dataFile:
			if i % 4 == 0:
				line = line.strip("\n").split(" ")
				myReadName=line[0]
				sampleBarcode=line[1] # just grabbing the sample barcode 3:N:0:CGTGTAAT
				line=myReadName+"-"+sampleBarcode+"+"+barcodeDict[myReadName]+"\n"
			i = i + 1

			outFile.write(line)
