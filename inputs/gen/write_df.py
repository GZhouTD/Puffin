# Temp script containing the code to write the 3 input files for 
# Puffin.
#
# The three files are:
#
#   1) The main input file, describing free parameters and the 
#      integration sampling
#
#   2) The beam input file, which can describe multiple electron 
#      beams if necessary
#
#   3) The seed input file, which can describe multiple seeds
#
# This approach is quite flexible, allowing Puffin to generate
# a simple, more conventional FEL, or a more esoteric configuration
# with multiple seeds and electron beams, with different powers, 
# frequencies, energies, and distributions.
#
# -Lawrence Campbell
#  University of Strathclyde
#  July 2013

import math
import beamClass
import seedClass
import fBoolean

torf = fBoolean.torf

pow = math.pow
pi = math.pi
sqrt = math.sqrt
log = math.log
bm = beamClass.bm
sd = seedClass.sd

# Physical constants

m_e = 9.109e-31
q_e = 1.602e-19
eps_0 = 8.85e-12
c = 2.997924e8

# File names for input files

inputfile = 'example.in'
beamfile = 'beam_file.in'
seedfile = 'seed_file.in'

nbeams = 2
nseeds = 2

# Undulator and beam parameters

aw = 3.182             # 3.182 rms, 4.5 peak
emit = 1e-6 / 587.08   # Unnormalised Emittance
lambda_w = 0.07        # Undulator period
N_w = 4                # Number of undulator periods
gamma = 587.08         # Relativistic factor
ff = math.sqrt(2)      # Focus factor
Q = 3e-12              # Charge
qFlatTopZ2 = 0         # =1 if flat top, else gaussian.
qHardEdgeX = 0         # =1 if disk (circle) in transverse plane, else gaussian.
# E = 300e6            # Beam energy
# gamma = E / (m_e * pow(c,2)) # Rel. factor
sig_gamma = 0.001      # Energy spread


k_w = 2 * pi / lambda_w             # Get wiggler wavenumber
sigt = 3.3356e-15                   # Get sigma in t dimension
sigz = c * sigt                     # Convert sigma in t to z
k_beta = aw * k_w / ( ff * gamma )  # Betatron wavelength
N = Q / q_e                         # Number of real electrons in pulse
lambda_r = lambda_w / (2 * pow(gamma,2)) * (1 + pow(aw,2))
                                    # ^ Resonant wavelength


sigx = sqrt(emit / k_beta)     # Beam standard deviation in x
sigy = sigx                           # and y

sig_av = sqrt(pow(sigx,2) + pow(sigy,2))


########################################
# Beam area and FEL parameter

if qHardEdgeX == 1:
    r_av = sig_av                 # Hard edged circle in x and y
else:
    r_av = math.sqrt(2) * sig_av  # Gaussian dist in x and y

tArea = pi * pow(r_av,2)          # Tranverse beam area

if qFlatTopZ2 == 1:
    lArea = sigz                  # longitudinal integral over charge dist (flat top)
else:
    lArea = sqrt(2*pi) * sigz     # longitudinal integral over charge dist(gaussian)

n_p = N / (tArea * lArea)              # Electron number density
wp = sqrt(pow(q_e,2) * n_p / (eps_0 * m_e) )         # plasma frequency

rho = 1 / gamma * pow((aw * wp / ( 4 * c * k_w )),(2/3))  # FEL parameter


#######################################
# Scaled parameters for Puffin


lambda_z2 = 4*pi*rho              # Resonant wavelength in z2
Lg = lambda_w / lambda_z2         # Gain length
Lc = lambda_r / lambda_z2         # Cooperation length
zbarprop = N_w * lambda_z2        # Length of undulator in zbar (gain lengths)
sigz2 = sigz / Lc                 # Length of pulse in z2 (cooperation lengths)

beta = sqrt(pow(gamma,2) - 1 - pow(aw,2))/gamma    # Average velocity over c
eta = (1-beta)/beta                                # Scaled average velocity

k_beta_bar = k_beta * Lg                           # Scaled betatron wavenumber
emit_bar = emit / (rho * Lc)                       # Scaled emittance
Z_R = pi * pow(r_av,2) / lambda_r                  # Rayleigh range
Z_bar_R = pow(r_av,2) / (Lg * Lc) / (4 * rho)      # Scaled Rayleigh Range
B = pow((2 * Z_bar_R),(3/2))                       # Saldin diffraction parameter


NL = N/sigz2 * lambda_z2                           # electrons per radiation period
Anoise = 6 * sqrt(pi) * rho / (NL * sqrt(log(NL/rho)))  # Spontaneous noise estimate (in scaled units)
Acse = 16 * pow(rho,2)                             # CSE estimate for flat-top current



#################################################
# Chirp - 1% per sigma_z

dgamma = 0.01 * gamma    # Change in gamma per sigma_z
chirp = dgamma / sigz    # Energy chirp in z
chirpz2 = Lc * chirp     # Energy chirp in z2




##################################################
# Sampling

elms_per_wave = 24         # Elements per resonant wavelength
steps_per_per = 96         # should be roughly 4-5* elms_per_wave

if qFlatTopZ2 == 1:
    lez2     = sigz2       # flat-top
    sigz2_in = 1e8 
else:
    lez2     = 9*sigz2     # gaussian
    sigz2_in = sigz2 

lwz2 = 50.0                # Total size of sampled field in z2
lsys_z2 = lwz2 + lez2      # Total length of sampled system in z2

dz2 = lambda_z2 / elms_per_wave    # Node spacing in z2
NNodesZ2 = lsys_z2 / dz2 + 1       # Number of radiation field nodes
NMElecsZ2 = lez2 / dz2 * 2         # MINIMUM number of macroparticles
dz = lambda_z2 / steps_per_per     # Step size in zbar
Nsteps = zbarprop / dz             # Number of steps


###################################################


beam = [bm() for ib in range(nbeams)] # list of electron beams

seeds = [sd() for ic in range(nseeds)] # list of seeds

# Assign electron pulse data to beams


#
#
# ASSIGN DATA
#
#

lex = 1
ley = 1
sigx = sigx / (sqrt(Lg) * sqrt(Lc))

qoned = True
qfieldevo = True
qEevolve  = True
qEFcouple = True
qFocusing = True
qMatchedBeam = True
qDiffraction = True
qFilter = True
qNoise = True
qDump = False
qResume = False
qStepFiles = True
qFormatFiles = True
qWriteZ = True
qWriteA = True
qWritePperp = True
qWritep2 = True
qWritez2 = True
qWritex = True
qWritey = True


beam[0].lex = lex
beam[0].ley = ley
beam[0].lez2 = lez2
beam[0].lepx = 1E0
beam[0].lepy = 1E0
beam[0].lep2 = 1E0

beam[0].sigx = sigx
beam[0].sigy = sigy
beam[0].sigp2 = sig_gamma


beam[0].sigpy = 1E0
beam[0].sigp2 = 1E0

beam[0].NMPX = 1
beam[0].NMPY = 1
beam[0].NMPPX = 1
beam[0].NMPPY = 1
beam[0].NMPP2 = 1

beam[0].eratio = 1
beam[0].emit_bar = 1
beam[0].chirp = 0
beam[0].bcenz2 = 0
beam[0].Q = Q

# for field

NNodesX = 1 # Next, create a class for the field vars
NNodesY = 1 # and a routine to write the seed file

lwx = 1E0
lwy = 1E0

lsys_x = lwx
lsys_y = lwy


filtFrac = 0.3
diffFrac = 1.0


################################################
# Write data

# Main input file:

f = open(inputfile, 'w')

# Header

f.write('!--------------------------------------------------------------------------------------------------!\n')
f.write('!VALUE              TYPE        NAME                       DESCRIPTION\n')
f.write('!--------------------------------------------------------------------------------------------------!\n')


# Options


f.write('!                       OPTIONS\n')
f.write('\n')
f.write('\n')
f.write('{:<24}'.format(torf(qoned)) + 'LOGICAL     qOneD                      If TRUE, model 1D FEL, with only 1 node and 1 macroparticle in transverse dimensions\n')
f.write('{:<24}'.format(torf(qfieldevo)) + 'LOGICAL     qFieldEvolve               if letting the radiation field evolve\n')
f.write('{:<24}'.format(torf(qEevolve)) + 'LOGICAL     qElectronsEvolve           if integrating electron equations\n')
f.write('{:<24}'.format(torf(qEFcouple)) + 'LOGICAL     qElectronFieldCoupling     if allowing field to feedback onto the electron equations\n')
f.write('{:<24}'.format(torf(qFocusing)) + 'LOGICAL     qFocussing                 if focussing is included in the transverse plane\n')
f.write('{:<24}'.format(torf(qMatchedBeam)) + 'LOGICAL     qMatchedBeam               if matching beam to undulator. If TRUE, electron pulse sigma and length in x,y,px,py are automatically calculated\n')
f.write('{:<24}'.format(torf(qDiffraction)) + 'LOGICAL     qDiffraction               if modelling diffraction\n')
f.write('{:<24}'.format(torf(qFilter)) + 'LOGICAL     qFilter                    TRUE to filter, if FALSE the low frequencies will just be ignored during diffraction\n')
f.write('{:<24}'.format(torf(qNoise))  + 'LOGICAL     q_noise                    Shot noise in initial electron beam distribution\n')
f.write('{:<24}'.format(torf(qDump))  + 'LOGICAL     qDump                      Do you wish to dump data so the run can be resumed if anything goes wrong? .TRUE. for yes.\n')
f.write('{:<24}'.format(torf(qResume)) + 'LOGICAL     qResume                    If resuming from dump files left from a previous run\n')
f.write('{:<24}'.format(torf(qStepFiles))  + 'LOGICAL     qSeparateFiles             Write data to separate SDDS files at each step\n')
f.write('{:<24}'.format(torf(qFormatFiles))  + 'LOGICAL     qFormattedFiles            Write data as formatted text(TRUE) or binary(FALSE)\n')
f.write('{:<24}'.format(torf(qWriteZ))  + 'LOGICAL     qWriteZ                    Write out Z data\n')
f.write('{:<24}'.format(torf(qWriteA))  + 'LOGICAL     qWriteA                    Write out A data\n')
f.write('{:<24}'.format(torf(qWritePperp))  + 'LOGICAL     qWritePperp                Write out Pperp data\n')
f.write('{:<24}'.format(torf(qWritep2))  + 'LOGICAL     qWriteP2                   Write out P2 data\n')
f.write('{:<24}'.format(torf(qWritez2))  + 'LOGICAL     qWriteZ2                   Write out Z2 data\n')
f.write('{:<24}'.format(torf(qWritex))  + 'LOGICAL     qWriteX                    Write out X data\n')
f.write('{:<24}'.format(torf(qWritey))  + 'LOGICAL     qWriteY                    Write out Y data\n')
f.write('\n')






# Macroparticle info

f.write('              ELECTRON MACROPARTICLE SAMPLING\n')
f.write('\n')
f.write('\n')
f.write('{:<24}'.format(beamfile) + 'CHARACTER   beam_file                  Name of the beam file\n')
f.write('{:<24.15E}'.format(0.5)   + 'REAL        sEThreshold          Beyond the threshold level(%) * the average of real electrons are removed(ignored)\n')


f.write('\n')
f.write('\n')
f.write('\n')

# Field Sampling

f.write('                  FIELD NODE SAMPLING\n')
f.write('\n')
f.write('\n')
f.write('{:<24d}'.format(int(math.floor(NNodesX)))        + 'INTEGER     iNumNodes(1)         Number of Elements in x direction\n')
f.write('{:<24d}'.format(int(math.floor(NNodesY)))        + 'INTEGER     iNumNodes(2)         Number of Elements in y direction\n')
f.write('{:<24d}'.format(int(math.floor(NNodesZ2)))      + 'INTEGER     iNumNodes(3)         Number of Elements in z2 direction\n')
f.write('{:<24.15E}'.format(lsys_y)   + 'REAL        sFModelLengthX       Length of radiation field model in x direction\n')
f.write('{:<24.15E}'.format(lsys_x)   + 'REAL        sFModelLengthY       Length of radiation field model in y direction\n')
f.write('{:<24.15E}'.format(lsys_z2)  + 'REAL        sWigglerLengthZ2     Length of wiggler in z2-bar direction\n')
f.write('{:<24d}'.format(1)        + 'INTEGER     iRedNodesX           Length of central wiggler section in x where electrons will not leave\n')
f.write('{:<24d}'.format(1)        + 'INTEGER     iRedNodesY           Length of central wiggler section in y where electrons will not leave\n')
f.write('{:<24.15E}'.format(filtFrac)   + 'REAL        sFiltFrac            Specifies cutoff for high pass filter as fraction of resonant frequency\n')
f.write('{:<24.15E}'.format(diffFrac)   + 'REAL        sDiffFrac                  Specifies diffraction step size as fraction of the undulator period\n')
f.write('{:<24}'.format(seedfile) + 'CHARACTER   seed_file                  Name of the seed file\n')


f.write('\n')
f.write('\n')


# Independent Variables

f.write('                 INDEPENDANT VARIABLES\n')
f.write('\n')
f.write('\n')
f.write('Input the scaled independant variables from [1] here\n')
f.write('\n')
f.write('\n')
f.write('{:<24.15E}'.format(rho) + 'REAL        rho                  Pierce parameter, describe the strength of the field\n')
f.write('{:<24.15E}'.format(1.0)   + 'REAL        ux                   Normalised magnitude of wiggler magnetic field x-vector: H=1 is helical, H=0 is planar\n')
f.write('{:<24.15E}'.format(1.0)   + 'REAL        uy                   Normalised magnitude of wiggler magnetic field y-vector: H=1 is helical, H=0 is planar\n')
f.write('{:<24.15E}'.format(eta) + 'REAL        eta                  Scaled longitudinal velocity (1-beta_av) / beta_av\n')
f.write('{:<24.15E}'.format(k_beta_bar) + 'REAL        kbeta                Scaled betatron wavenumber\n')
f.write('{:<24.15E}'.format(ff) + 'REAL        sFocusfactor         Focussing factor f, from the betatron wavenumber\n')
f.write('{:<24.15E}'.format(emit_bar) + 'REAL        sEmit_n              scaled beam emittance\n')
f.write('{:<24.15E}'.format(0.0)      + 'REAL        Dfact                Dispersive strength factor for chicane\n')


f.write('\n')
f.write('\n')

# Integration through undulator


f.write('                      INTEGRATION AND OUTPUT\n')
f.write('\n')
f.write('\n')
f.write('Here,a lattice file can be input to specify an undulator-chicane lattice.\n')
f.write('If it is specified, then the user supplied value of nSteps and \n')
f.write('sStepSize is ignored, and the number of steps per undulator period\n')
f.write('is used instead. Otherwise steps per und period is ignored and use \n')
f.write('nsteps and sstepsize.\n')
f.write('\n')
f.write('What do we want to calculate in the code to output i.e. bunching, pulse current weighted average x, av sigma x etc\n')
f.write('\n')
f.write('\n')
f.write('{:<24}'.format('\'\'')       + 'CHARACTER   lattFile             Contents: N_w(periods), delta(periods) (!!! NO BLANK LINES AT END !!!)Blank if none.\n')
f.write('{:<24.15E}'.format(dz) + 'REAL        sStepSize            Step size for integration (if zero auto calculated)\n')
f.write('{:<24d}'.format(int(round(Nsteps)))    +   'INTEGER     nSteps               Number of steps (if zero,travel one raleigh length in z)\n')
f.write('{:<24.15E}'.format(0.0)    + 'REAL        sZ                   Starting z position\n')
f.write('{:<24}'.format('\'DataFile.dat\'') + 'CHARACTER   zDataFileName        Data file name\n')
f.write('{:<24d}'.format(100)    +  'INTEGER     iWriteNthSteps       Steps to write data at\n')
f.write('{:<24d}'.format(100)    +  'INTEGER     iDumpNthSteps        Steps to dump data at (0 for no dumping)\n')
f.write('{:<24.15E}'.format(100)    +  'REAL        sPEOut               Percentage of macroparticles to write out. Macroparticles are randomly selected.\n')
f.write('\n')

f.close()





#
# beam file

f = open(beamfile, 'w')


f.write('PUFFIN BEAM FILE')


f.write('PUFFIN BEAM FILE\n')
f.write('\n')
f.write('Describes electron beams for input into puffin. Multiple beams with\n')
f.write('different parameters can be used. Please refer to POP-REF for an\n')
f.write('explanation of the scaled variables used, such as z2 and p2.\n')
f.write('\n')
f.write('{:d}'.format(int(nbeams)) + '         # of beams\n')
f.write('\n')
f.write('READ IN BEAM CHARACTERISTICS\n')


# Write beam files

for ib in range(nbeams):
    beam[ib].wrbeam(f,ib+1)

#
# seed file

f = open('seed_file.in', 'w')

f.write('PUFFIN SEED FILE\n')
f.write('\n')
f.write('Describes seed fields for input into puffin. Multiple seeds with\n')
f.write('different frequencies, profiles and positions can be used. Please \n')
f.write('refer to POP-REF for an explanation of the scaled variables used, \n')
f.write('such as z2.\n')
f.write('\n')
f.write('{:d}'.format(int(nseeds)) + '         # of beams\n')
f.write('\n')
f.write('READ IN SEED CHARACTERISTICS\n')

# Write seed data

for ic in range(nseeds):
    seeds[ic].wrseed(f,ic+1)


f.close()
















