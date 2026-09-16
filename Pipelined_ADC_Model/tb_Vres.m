clear; clc; close all;
addpath(fileparts(mfilename('fullpath')));


parameters;
system_model;
Vin = linspace(0,VREF,nPoints).';
[VresIdeal,Dideal] = model.mdacStage(Vin,pIdeal);
[VresMismatch,Dmismatch] = model.mdacStage(Vin,pMismatch);
[VresOffset,Doffset] = model.mdacStage(Vin,pOffset);
[finiteResidue,finiteDecision] = model.mdacStage(Vin,pFinite);


plot_Vres;
