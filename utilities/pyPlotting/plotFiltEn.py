# Copyright (c) 2012-2017, University of Strathclyde
# Authors: Lawrence T. Campbell
# License: BSD-3-Clause

"""
This is an examplar script to produce a plot of the filtered energy.
"""

import sys, glob, os
import numpy as np
from numpy import pi
from numpy import arange
import matplotlib.pyplot as plt
from matplotlib.pyplot import specgram
import tables


#t = np.linspace(-1, 1, 200, endpoint=False)

#sig  = np.cos(2 * np.pi * 7 * t) + \
#     np.real(np.exp(-7*(t-0.4)**2)*np.exp(1j*2*np.pi*2*(t-0.4)))



# you want the NFFT to be smaller than the total signal size, 
# it is the length of the local FFT.

#specP, freqs, time, image = specgram(sig, NFFT=25, Fs=200, noverlap=10)

#plt.imshow(specP)
#plt.show()




def FilterField(field,crfr,distfr,nZ2,sLengthOfElmZ2, rho, q1d):

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#% filter - HARD FILTER

#%crfr=1.4167;
#%distfr=0.2;

    nn = np.round(sLengthOfElmZ2 * nZ2 * crfr / (4*pi*rho))
    nns = np.round(sLengthOfElmZ2 * nZ2 * distfr / (4*pi*rho))
    #print str(nn) + str(nns)
    if (q1d == 1):

#%%%%%    1D    %%%%%%%

        ftfield = np.fft.fft(field)

        ftfield[0:np.int(nn-nns)] = 0
        ftfield[np.int(nn+nns-1):np.int(np.ceil(nZ2/2))] = 0

        ftfield[np.int(np.ceil(nZ2/2) + 1 - 1):np.int(nZ2-(nn+nns)+2)] = 0
        ftfield[np.int(nZ2 - (nn-nns) + 2 - 1 ) : np.int(nZ2)] = 0

        field = np.fft.ifft(ftfield)

        xfield = np.real(field)

    else:

#%%%%%    3D    %%%%%%%

      ftfield = np.fft.fft(field)


      #ftfield[:,:,0:(nn-nns)] = 0
      #ftfield[:,:,(nn+nns-1):np.ceil(nZ2/2)] = 0
      sn = 1
      ftfield[:,:,0:sn] = 0
      ftfield[:,:,sn+1:np.ceil(nZ2/2)] = 0

      ftfield[:,:,np.ceil(nZ2/2) + 1 - 1:-sn] = 0
#      ftfield[:,:,-sn+1:] = 0

#      ftfield[:,:,0:(nn-nns)] = 0
#      ftfield[:,:,(nn+nns-1):np.ceil(nZ2/2)] = 0
#    
#      ftfield[:,:,np.ceil(nZ2/2) + 1 - 1:nZ2-(nn+nns)+2] = 0
#      ftfield[:,:,(nZ2 - (nn-nns) + 2 -1 ) : nZ2] = 0

      field = np.fft.ifft(ftfield)

      xfield = np.real(field)

    return xfield

#%%%%%%%%%%%%%%%%%%%%%%




##################################################################
#
##



def getMagPhase(Ex,nZ2,rho,syslen):

    wavel=4*pi*rho

    ax=1
    thix=-1

    xaxis = np.linspace(0,syslen,nZ2)  # xaxis for real space
# %Ex = ax*cos(xaxis/(2*rho)+thix); %Define x field

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# MAGNITUDE:
# 2*df is the number of nodes spanning a resonant wavelength
# de is the number of nodes to the left to average from
# dg is the number of nodes to the right
# so average around node_index-de:node_index+dg
# first of all, find the number of nodes corresponding to one lamda_r,nnl
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    lr=wavel
    nsp=syslen/(nZ2-1)
    nel=np.round(lr/nsp)
    nnl=nel+1

    df=np.floor((nnl)/2)
    dg=df

    if (np.mod(nnl,2)==1):
        de=df
    else:
        de=df-1
        
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Specify a segment around the current node
# and average around it over a wavelength
# intxrms is rms square root of the mean intensity, or
# the rms absolute field.
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    intxrms=np.zeros(nZ2)
    intyrms=np.zeros(nZ2)

    for m in np.arange(nZ2):
        lo=m-de
        hi=lo+(nnl-2) # hi=m+dg
        if lo<1:
            lo=0
        if hi>nZ2:
            hi=nZ2-1
        tar = np.square(Ex[np.int_(lo):np.int_(hi+1)])
        tvar = np.mean(tar)
        intxrms[m]=np.sqrt(tvar)

    magxrms=np.sqrt(2)*intxrms # magxrms is the rms magnitude of the wave

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# PHASE:
# First create the "reference" wave, cos(\omega t)
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    z2cyclic=xaxis-(4*pi*rho*np.floor(xaxis/(4*pi*rho)))
    z2cyclic=z2cyclic/(2*rho)

    slopy=-np.sin(2*pi*xaxis/wavel)

    invcosx = np.zeros(nZ2)

    for a in np.arange(nZ2):
        if (Ex[a]/magxrms[a] < -1 ) or ((Ex[a]/magxrms[a] > 1 )):
            invcosx[a] = 0
        else:
            invcosx[a]=np.arccos(Ex[a]/magxrms[a])

    for a in np.arange(nZ2):
      if (abs(Ex[a])>=magxrms[a]):
          if (Ex[a]>0):
              invcosx[a]=0
          elif (Ex[a]<0):
              invcosx[a]=pi


    for a in arange(nZ2-1):
        if Ex[a]<Ex[a+1]: # best way to do this may be taking 
             #### gradient of Ex. If negative, then shift
             #### to 3rd and 4th quadrant....
             # invcosx(a)=invcosx(a)*(-1)
            invcosx[a]=(2*np.pi)-invcosx[a]

    phasex=invcosx-z2cyclic

    for a in np.arange(nZ2):
        if phasex[a]<0:
            phasex[a]=2*pi-np.absolute(phasex[a])

    return magxrms, phasex



def getFileSlices(baseName):
  """ getTimeSlices(baseName) gets a list of files

  That will be used down the line...
  """
  filelist=glob.glob(os.getcwd()+os.sep+baseName+'_aperp_C_*.h5')
  
  dumpStepNos=[]
  for thisFile in filelist:
    thisDump=int(thisFile.split(os.sep)[-1].split('.')[0].split('_')[-1])
    dumpStepNos.append(thisDump)

  for i in range(len(dumpStepNos)):
    filelist[i]=baseName+'_aperp_C_'+str(sorted(dumpStepNos)[i])+'.h5'
  return filelist



def getFiltPow(h5fname):
    
    h5f = tables.open_file(h5fname, mode='r')

    dz2 = h5f.root.runInfo._v_attrs.sLengthOfElmZ2
    nz2 = h5f.root.runInfo._v_attrs.nZ2
    rho = h5f.root.runInfo._v_attrs.rho

    sampleFreq = 1.0 / dz2

#   To select temporal slice of field....
    
    #z2s = 50
    #z2e = 80

    #z2si = int(np.floor(z2s / dz2))
    #z2ei = int(np.floor(z2e / dz2))

    #z2axis = (np.arange(z2si,z2ei) - z2si) * dz2


#    ...otherwise take full field

    lenz2 = (nz2-1) * dz2
    z2axis = (np.arange(0,nz2)) * dz2

    xf = h5f.root.aperp[:,:,:,0]
    # xfs = xf[z2si:z2ei]   # for selecting slice...

    yf = h5f.root.aperp[:,:,:,1]


    cfr = 1.0
    dfr = 1.0

    xf = FilterField(xf, cfr, dfr, nz2, dz2, rho, 0)
    yf = FilterField(yf, cfr, dfr, nz2, dz2, rho, 0)

    intens = np.square(xf) + np.square(yf)
    h5f.close()

    return intens


def getZData(fname):
    h5f = tables.open_file(fname, mode='r')
    zD = h5f.root.aperp._v_attrs.zTotal
    h5f.close()
    return zD



def plotFiltEn(basename):


    filelist = getFileSlices(basename)
    print filelist
    h5f = tables.open_file(filelist[0], mode='r')

    dz2 = h5f.root.runInfo._v_attrs.sLengthOfElmZ2
    nz2 = h5f.root.runInfo._v_attrs.nZ2
    rho = h5f.root.runInfo._v_attrs.rho
    
    nx = h5f.root.runInfo._v_attrs.nX
    ny = h5f.root.runInfo._v_attrs.nY
    dx = h5f.root.runInfo._v_attrs.sLengthOfElmX
    dy = h5f.root.runInfo._v_attrs.sLengthOfElmY

    sampleFreq = 1.0 / dz2

#   To select temporal slice of field....
    
    #z2s = 50
    #z2e = 80

    #z2si = int(np.floor(z2s / dz2))
    #z2ei = int(np.floor(z2e / dz2))

    #z2axis = (np.arange(z2si,z2ei) - z2si) * dz2


#    ...otherwise take full field

    lenz2 = (nz2-1) * dz2
    z2axis = (np.arange(0,nz2)) * dz2
    xaxis = (np.arange(0,nx)) * dx
    yaxis = (np.arange(0,ny)) * dy

    h5f.close()

    fcount = 0
    
    ens = np.zeros(len(filelist))
    zData = np.zeros(len(filelist))
#    zData[fieldCount] = h5in.root._f_get_child("power")._v_attrs.zTotal 
    
    for ij in filelist:
        tintens = getFiltPow(ij)
        #print "first", np.shape(xaxis), np.shape(tintens)
        tintensx = np.trapz(tintens, x=xaxis, axis=0)
        #print "second", np.shape(xaxis), np.shape(tintensx)
        tintensxy = np.trapz(tintensx, x=yaxis, axis=0)
        ens[fcount] = np.trapz(tintensxy, x=z2axis) / lenz2
        zData[fcount] = getZData(ij)
        fcount += 1


    h = 6.626e-34 # Planck constant
    q_e = 1.60217646e-19 # Charge on electron
    c_0 = 2.99792458e8 # Speed of light in vacuum

    ax1 = plt.subplot(111)
    plt.semilogy(zData, ens, label='Scaled Power')
    ax1.set_title('Filtered Power')
    ax1.set_ylim([1e-10,1e-1])
    #plt.legend()

    outname = "Power_" + basename + "1"

    plt.savefig(outname)
    plt.show()


#    plt.show(block=False)
    h5f.close()


if __name__ == '__main__':
    basename=sys.argv[1]
    plotFiltEn(basename)
    
