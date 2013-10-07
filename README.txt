==================== Puffin v1.4.0 ======================

The code 'Puffin' solves the unaveraged 3D FEL system of equations. 
The code requires FFTW_2.5.1 and uses MPI.

Puffin (Parallel Unaveraged Fel INtegrator) is described in:-
LT Campbell and BWJ McNeil, Physics of Plasmas 19, 093119 (2012)

The code has been improved since then, and no longer uses an
external linear solver. The only external package now required is FFTW.

The sub-directories include:

  source/  -  This contains the main source code written in Fortran 90.
  compile/ -  Some example compilation and linking scripts.
  submit/  -  Example subission script for the Archie-WEST HPC.  
  inputs/  -  Some example input files.

FFTW v2.1.5 and MPI compilers must be loaded into
your environment before compiling. e.g. on Archie, do

module load compilers/gcc/4.6.2
module load mpi/gcc/openmpi/1.6
module load /libs/gcc/fftw2/double-mpi/2.1.5

You may wish to put these commands into your .bashrc script (or
equivalent) to save typing this every time you log in.

The example job submission script lanches a job on 1 node, using 12 
processes. The line

#$ -pe mpi-verbose 1

specifies the number of nodes. There are 12 processors per node,
so we use 12 MPI processes per node here. However, you can use
less than this if you desire. You can technically use more 
MPI processes than physical processors, but this is probably
not a good idea. The MPI job is launched with 

mpirun -np 12 ~/bin/puffin1.4 hidding.in

where the 2nd last argument points to the executable, and the
last argument is the input file for Puffin. The option -np 
specifies the number of MPI processes.

The input files consist of a main parameter file, a beam file,
and a seed file. The beam and seed files enable you to input
multiple electron beams with different energies and 
distributions, and multiple seeds with different frequencies
and different distributions. The parameter file specifies
the name of the seed and beam files to be used.

For a 1D run it is unlikely you will need more than a node
to improve the computation time. A full 3D run will
require many nodes, and plenty of memory. You may wish, on a
larger machine, to use 1 MPI process per node, and lots of 
nodes, to maximize the RAM for each process.

=========================HISTORY==========================

Puffin is the result of work performed by a group of people 
at the University of Strathclyde over the period
2005-2013. A brief history is as follows:

The code had its origins in a 1D version briefly described in:
BWJ McNeil, GRM Robb and D Jaroszynski,
�Self Amplification of Coherent Spontaneous Emission in the Free Electron Laser',
Optics Comm., 165, p 65, 1999

The first 3D version of the code was originally developed by 
Dr Cynthia Nam, Dr Pamela Johnston and Dr Brian McNeil and was 
reported in:
Unaveraged Three-Dimensional Modelling of the FEL, Proceedings 
of the 30th International Free Electron Laser Conference, 
Gyeongju, Korea (2008)

It was significantly redeveloped by Lawrence Campbell (et al) a further two times
improving the algortithms (Fourier method back to Finite Element) and the 
parallelism with MPI. This development has been reported in the 
following proceedings of FEL conferences:

L.T. Campbell, R. Martin and B.W.J. McNeil, 
'A Fully Unaveraged, Non-localised, Parallelized Computational Model of the FEL', 
Proceedings of the 31st International Free Electron Laser Conference, 
Liverpool, United Kingdom (2009)

L.T. Campbell and B.W.J. McNeil, 
'An Unaveraged Computational Model of a Variably Polarized Undulator FEL', 
Proceedings of the 32nd International Free Electron Laser Conference, 
Malmo, Sweden (2010)

L.T. Campbell and B.W.J. McNeil, 
'Generation of Variable Polarization in a Short Wavelength FEL Amplifier', 
Proceedings of the 32nd International Free Electron Laser Conference, 
Malmo, Sweden (2010)

The final working equations and scaling were reported in:
LT Campbell and BWJ McNeil, 
'Puffin: A three dimensional, unaveraged free electron laser simulation code'
Physics of Plasmas 19, 093119 (2012)

The code algorithm has been improved since and no longer needs an
external linear solver for the coupled electron-radiation field equations.
The only external package now required by Puffin is FFTW.

=============================================================
