# Memristive deep belief network based on two-terminal floating gate memristor

This project deposits the MATLAB code for memristive deep belief nework based on two-terminal floating gate memristor (y-flash).
It contains:
- Y-flash device behaivor modeling code
- Online traning code for memristive deep belief network


## System requirements
Hardware requirements
- A standard computer that can install and run MATLAB.

Software requirements
- OS Requirements:
  - This package is supported for Windows, macOS and Linux.
Has been tested on MacOS (Apple Silicon).

- Matlab requirements:
  - Matlab >= R2020a.

## Instructions to running the code

- Download the project files into your local disk, and browse the MATLAB working folder into the root folder of this project.

### Y-flash device behavior modeling
- Read I-V and write behavior

  - Browse the MATLAB working folder to "/yflash_write_read_model";

  - Run the code file "read_model.m" to simulate the Read I-V curves of the Y-Flash devices;
  
  - Run the code file "write_model.m" to simulate the write behavior (Program and Erase) of the Y-Flash devices; 

- Cycle-to-cycle variation

  - Browse the MATLAB working folder to "/yflash_cycling_degradation";
 
  - Run the code file "cycling_degradation_model.m" to see the modelled write behaivor degradation;
  
  - Run the code file "cycling_degradation_data_vs_model.m" to see the comparison between the modelled write behaivor degradation and the experimental data;

- Device-to-device variation

  - Browse the MATLAB working folder to "/yflash_device2device_variation";
 
  - Run the code file "plot_prog_erase_d2d_model.m" to see the modelled device-to-device variations and its comparsion with experimental data;
  

### Memristive deep belief network for on-line training of MNIST

- Download and load the MNIST dataset

  - Downlaod the MNIST dataset files from the Internet (e.g. "https://deepai.org/dataset/mnist"), unzip and save the files in the folder "/memristive_dbn/dataset"
  
  - Browse the MATLAB working folder to "/memristive_dbn/dataset";
  
  - Run the code file "loadMNIST.m" to load the MNIST dataset;

- On-line training of MNIST based on the memristive deep belief network

  - Browse the MATLAB working folder to "/memristive_dbn";
  
  - Run the code file "mnistdeepbn.m" to start simulation of the online trianing of deep belief network using silicon synapses based on the y-flash memristor;
  
  - Run the code file "plot_figures.m" to see the analysis of the online training results.
  
  
## Suggestion for further works based on this project

- Use the y-flash memristor to construct and simulate other types of neural network

- On-line training of the memristive deep belief network using other memristor modeling behavior
