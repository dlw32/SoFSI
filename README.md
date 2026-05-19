# SoFSI
 The National Soil-Foundation-Structure Interaction Laboratory at the University of Bristol

## Welcome
This repository is for storage and documentation of scripts relating to the lab, including integrating with Servotest's Pulsar software, and data acquisition and analysis.

## Contents
```

├── Pulsar_MATLAB_tools/    # Contains the following MATLAB functions for working with Pulsar
│   ├── sefread.m             # reads a *.sef file and outputs MATLAB variables into the workspace
│   ├── sef2mat.m             # batch process *.sef files using sefread and return structured arrays in a *.mat file
│   ├── sefwrite.m            # creates a *.sef files from MATLAB variables for import to Pulsar
│   ├── convert2sef.m         # batch tool for converting *.csv or *.txt using sefwrite
│   ├── batch_process_ezf     # automates the process of generating EZF files from a csv list of drive files
│   ├── pulsar-plot.m         # plots Pulsar log data from exported *.mat file
│   └── README.md
├── Pulsar_config/          # Contains info on customising the Pulsar configuration and database settings
└── assets/                 # Supporting files
    └── images/

```
>[!TIP]
> Pulsar_MATLAB_tools [README](Pulsar_MATLAB_tools/README.md) gives more detail on function and usage of these scripts.
