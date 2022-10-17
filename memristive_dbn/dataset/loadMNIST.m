clc
clear
close all


% LOAD DATASET
% You should fisrt downloand and unzip the MNIST dataset files from internet
% for instance, from "https://deepai.org/dataset/mnist"

images_tr = loadMNISTImages('./train-images-idx3-ubyte');
labels_tr = loadMNISTLabels('./train-labels-idx1-ubyte');
images_ts = loadMNISTImages('./t10k-images-idx3-ubyte');
labels_ts = loadMNISTLabels('./t10k-labels-idx1-ubyte');

images_tr = images_tr';
images_ts = images_ts';

labels_tr = one_hot(labels_tr, 10);
labels_ts = one_hot(labels_ts, 10);

save MNIST.mat images_tr images_ts labels_tr labels_ts
