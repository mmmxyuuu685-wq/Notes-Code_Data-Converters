clear; clc; close all;
addpath(fileparts(mfilename('fullpath')));

parameters;
system_model;

Vin = linspace(0,VREF,nPoints).';
[codeIdeal,bitsIdeal,residuesIdeal] = model.pipelineADC(Vin,stagesIdeal);
[codeMismatch,bitsMismatch,residuesMismatch] = model.pipelineADC(Vin,stagesMismatch);
[codeOffset,bitsOffset,residuesOffset] = model.pipelineADC(Vin,stagesOffset);
[codeFinite,bitsFinite,residuesFinite] = model.pipelineADC(Vin,stagesFinite);

plot_transfer;
