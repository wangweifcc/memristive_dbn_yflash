# Memristive deep belief network based on two-terminal floating gate memristor

This project deposits the MATLAB code for memristive deep belief nework based on two-terminal floating gate memristor (y-flash device).
It contains:
- Y-flash device behaivor modeling code
- Online traning code for memristive deep belief network

Please refer to our published paper "Wei Wang et al., A memristive deep belief neural network based on silicon synapses, 2022." (Reference Information to be Completed!!) when runing this project. 


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
  
  - Run the code file "mnistdeepbn.m" to start simulation of the online trianing of deep belief network using silicon synapses based on the y-flash memristor (the simulation takes several hours on a type personal computer);
  
  - Run the code file "plot_figures.m" to see the analysis of the online training results (the simulation takes several minutes on a type personal computer).
  
  
## Suggestion for further works based on this project

- Use the y-flash memristor to construct and simulate other types of neural network;

- Change the parameters of the memristive neural network to find optimized online training results;

- Use other memristor modeling behavior to verify and invesitage the on-line training of the memristive deep belief network 


## References
[1] W. Wang et al., “Physical based compact model of Y-Flash memristor for neuromorphic computation,” Appl. Phys. Lett., vol. 119, no. 26, p. 263504, Dec. 2021, doi: 10.1063/5.0069116.

[2] W. Wang et al., “Efficient Training of the Memristive Deep Belief Net Immune to Non‐Idealities of the Synaptic Devices,” Adv. Intell. Syst., vol. 4, no. 5, p. 2100249, May 2022, doi: 10.1002/aisy.202100249.

[3] W. Wang et al., "A memristive deep belief neural network based on silicon synapses," Nat. Electron., 2022. https://doi.org/10.1038/s41928-022-00878-9.



