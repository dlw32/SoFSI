# Pulsar MATLAB tools

MATLAB scripts/functions for working with Servotest's Pulsar software

## Importing files to Pulsar

These functions are useful for converting time histories into `*.sef` format for importing to Pulsar. Note that time histories need to first be resampled to a rate of power of 2 (e.g. 256 Hz, 512 Hz) for them to work properly with Pulsar.

<details>

<summary>sefwrite.m</summary>

### [sefwrite.m](Pulsar_MATLAB_tools\sefwrite.m)
Converts data from a `*.txt` or `*.csv` file into `*.sef` binary format. The input file should contain data in columns.

The output is `filename.sef` in MATLAB's current working directory.

#### Input variables

| Variable      | Description                       |
|---------------|-----------------------------------|
| `filename`    | Character array                   |
| `loggingrate` | Sample rate in Hz                 |
| `names`       | Character array of channel names  |
| `scales`      | Array of channel scale factors    |
| `units`       | Character array of channel units  |
| `matrix`      | Array containing the input data (one channel per column)   |
| `comments`    | Character array                   |

#### Usage
Call the function as below, specifying the input variables in order.

```MATLAB
sefwrite(filename, loggingrate, names, scales, units, matrix, comments)
```

</details>

<details>

<summary>convert2sef.m</summary>

### [convert2sef.m](Pulsar_MATLAB_tools\convert2sef.m)

Converts data from multiple input files to `*.sef` for use as drive files in Pulsar's ICS. The function attempts to remove any header lines in the files before resampling the data to 512 Hz and adding a 3 second tail before and after.

The output is a batch of files named `filename_target.sef` in the same folder as the input files.

#### Prerequisites
- `sefwrite.m` must be in your MATLAB path.

- `*.txt` or `*.csv` input files

#### Usage
Type `convert2sef` and enter the required information when prompted. Or provide input when calling the function using:

```MATLAB
convert2sef('InputRate', 512, 'NumChannels', 3)
```
If not provided, the function will default to 512 Hz for the input sample rate and 3 channels.

A user interface will appear for selecting the input files.

</details>

## Converting Pulsar output

Pulsar log files (`*.sef` format) can be exported individually by opening the file > edit > save as .mat. The following functions provide the same functionality, and enable bulk conversion of multiple files.

<details>

<summary>sefread.m</summary>

### [sefread.m](Pulsar_MATLAB_tools\sefread.m)

Extracts data from individual `*.sef` binary files and outputs the following variables to MATLAB:

| Variable      | Description                       |
|---------------|-----------------------------------|
| `loggingrate` | Sample rate in Hz                 |
| `names`       | Character array of channel names  |
| `units`       | Character array of channel units  |
| `comments`    | File comments                     |
| `matrix`      | Data - one channel per column     |
| `ScaleArry`   | Channel scales                    |
| `read_error`  | 1 = error, 0 = file read okay     |

#### Usage

```MATLAB
sefread(filename)
```
Output variable names can be defined by passing names to the function when calling.
```MATLAB
[loggingrate, names, units, comments, matrix, ScaleArry, read_error] = sefread(filename)
```

</details>

<details>

<summary>sef2mat.m</summary>

### [sef2mat.m](Pulsar_MATLAB_tools\sef2mat.m)

Converts multiple `*.sef` binary files to `*.mat` format.

The output is a batch of files named `filename.mat` each with a _struct_ variable containing the following:

```
└── filename              # structure named as per input file
    ├──sefFileInfo        # structure with info on original  *.sef input file from MATLAB's dir() function
    │   ├── name          # character array
    │   ├── folder        # character array
    │   ├── date          # character array
    │   ├── bytes         # double
    │   ├── isdir         # logical
    │   ├── datenum       # double
    │   └── conversion    # string
    ├── comments          # character array
    ├── loggingrate       # double - in Hz
    ├── matrix            # double - one channel per column
    ├── names             # character array
    ├── read_error        # double - should be 0 if no errors converting
    ├── scales            # double
    └── units             # character array
```

#### Prerequisites
- `sefread.m` must be in your MATLAB path.

- `*.sef` input file(s)

#### Usage

Run `sef2mat` and select the input file(s) and destination folder in the GUI.

</details>

## Data visualisation

Functions for plotting data from Pulsar

<details>

<summary>pulsar_plot.m</summary>

### [pulsar_plot.m](Pulsar_MATLAB_tools\pulsar_plot.m)

Requests user selection of `*.mat` file, then offers choice of plotting all channels or selecting one channel to display. Plotting all channels gives a tiled layout similar to that displayed by Pulsar.

![Matlab figure window showing a tiled layout of plots](/assets/images/pulsar_plot_output.png)
_Example pulsar_plot output_

</details>

## Working with EZFlows

<details>

<summary>batch_process_ezf.m</summary>

### [batch_process_ezf.m](Pulsar_MATLAB_tools\batch_process_ezf.m)

A function to automate setup of EZFlows for use in Pulsar. The function uses a template `*.ezf` to extract the template filename and filepath, then replaces this with the filenames and filepaths in the list provide. File selection by GUI.

The output is a batch of `*.ezf` files with filenames derived from the input list in MATLAB's current working directory.

#### Prerequisites
- A template `*.ezf` file using `!!FILENAME!!'` as a placeholder within elements where the drive file name is needed
- A `*.csv` or `*.txt` file listing the full file paths of drive files in the format `fullFilePath\...\Drive_filename.sef`

#### Usage
Run `batch_process_ezf` and select the files requested via the GUI.

</details>
