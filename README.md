# SoFSI
 The National Soil-Foundation-Structure Interaction Laboratory at the University of Bristol

## Welcome
This repository is for storage and documentation of scripts relating to the lab, including integrating with Servotest's Pulsar software, and data acquisition and analysis.

## Contents
`/Pulsar_MATLAB_tools` Contains the following MATLAB functions for working with Pulsar:

- `sefread.m` reads a `*.sef` file and outputs MATLAB variables into the workspace

- `sef2mat.m` will batch process `*.sef` files using `sefread` and return structured arrays in a `*.mat` file
  
- `sefwrite.m` creates a `*.sef` files from MATLAB variables for import to Pulsar
  
- `convert2sef.m` is a batch tool for converting `*.csv` or `*.txt` using `sefwrite`
  
- `batch_process_ezf` automates the process of generating EZF files from a csv list of drive files
