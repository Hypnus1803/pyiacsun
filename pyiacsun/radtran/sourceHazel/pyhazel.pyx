from numpy cimport ndarray as ar
from numpy import empty
import numpy as np
from copy import deepcopy

cdef extern from "pyhazel.h":
	void c_hazel(int* synModeInput, int* nSlabsInput, double* B1Input, double* B2Input, double* hInput, double* tau1Input, double* tau2Input, 
		double* boundaryInput, int* transInput, int* atomicPolInput, double* anglesInput, int* nLambdaInput, double* lambdaAxisInput,  
		double* dopplerWidthInput, double* dopplerWidth2Input, double* dampingInput, double* dopplerVelocityInput, 
		double* dopplerVelocity2Input, double* ffInput, double* betaInput, double* nbarInput, double* omegaInput, 
		double* wavelengthOutput, double* stokesOutput, double* epsOutput, double* etaOutput)
		
	void c_init()

def _synth(int synModeInput, int nSlabsInput, ar[double,ndim=1] B1Input, ar[double,ndim=1] B2Input, double hInput, 
	double tau1Input, double tau2Input, 
	ar[double,ndim=1] boundaryInput, int transInput, int atomicPolInput, ar[double,ndim=1] anglesInput, 
	int nLambdaInput, ar[double,ndim=1] lambdaAxisInput,
	double dopplerWidthInput, double dopplerWidth2Input, double dampingInput, double dopplerVelocityInput, 
	double dopplerVelocity2Input, double ffInput, double betaInput, ar[double,ndim=1] nbarInput, ar[double,ndim=1] omegaInput):
	
	"""
	Carry out a synthesis with Hazel
	
	Args: (see the manual for the meaning of all of them)
		- synModeInput: (int) synthesis mode
		- nSlabsInput: (int) number of slabs
		- B1Input: (float) vector of size 3 with the magnetic field vector in spherical coordinates for the first component
		- B2Input: (float) vector of size 3 with the magnetic field vector in spherical coordinates for the second component
		- hInput: (float) height
		- tau1Input: (float) optical depth of the first component
		- tau2Input: (float) optical depth of the second component        
		- boundaryInput: (float) vector of size 4 with the boundary condition for (I,Q,U,V)
		- transInput: (int) transition to compute from the model atom
		- atomicPolInput: (int) include or not atomic polarization
		- anglesInput: (float) vector of size 3 describing the LOS
		- nLambdaInput: (int) number of wavelength points
		- lambdaAxisInput: (float) vector of size nLambdaInput with the wavelength axis (relative to 10829.0911 A)		
		- dopplerWidth1Input: (float) Doppler width of the first component
		- dopplerWidth2Input: (float) Doppler width of the second component
		- dampingInput: (float) damping
		- dopplerVelocityInput: (float) bulk velocity affecting the first component
		- dopplerVelocity2Input: (float) bulk velocity affecting the second component
		- ffInput: (float) filling factor
		- betaInput: (float) value to be multiplied by the source function of the second component to allow for emission lines in the disk
		- nbarInput: (float) vector of size 4 to define nbar for every transition of the model atom (set them to zero to use Allen's)
		- omegaInput: (float) vector of size 4 to define omega for every transition of the model atom (set them to zero to use Allen's)
		
    Returns:
        wavelengthOutput: (float) vector of size nLambdaInput with the wavelength axis
        stokesOutput: (float) array of size (4,nLambdaInput) with the emergent Stokes profiles
        epsOutput: (float) array of size (4,nLambdaInput) with the emissivity vector at each wavelength
        etaOutput: (float) array of size (4,4,nLambdaInput) with the propagation matrix at each wavelength
	"""
	
	cdef:
		ar[double,ndim=1] wavelengthOutput = empty(nLambdaInput, order='F')
		ar[double,ndim=2] stokesOutput = empty((4,nLambdaInput), order='F')
		ar[double,ndim=2] epsOutput = empty((4,nLambdaInput), order='F')
		ar[double,ndim=3] etaOutput = empty((4,4,nLambdaInput), order='F')
   
	c_hazel(&synModeInput, &nSlabsInput, &B1Input[0], &B2Input[0], &hInput, &tau1Input, &tau2Input, 
		&boundaryInput[0], &transInput, &atomicPolInput, &anglesInput[0], &nLambdaInput, &lambdaAxisInput[0],  
		&dopplerWidthInput, &dopplerWidth2Input, &dampingInput, &dopplerVelocityInput, 
		&dopplerVelocity2Input, &ffInput, &betaInput, &nbarInput[0], &omegaInput[0], <double*> wavelengthOutput.data, 
		<double*> stokesOutput.data, <double*> epsOutput.data, <double*> etaOutput.data)
    
	return wavelengthOutput, stokesOutput, epsOutput, etaOutput
	
def init():
	"""
	Initialize and do some precomputations that can be avoided in the subsequent calls to the synthesis
	
	Args:
        None
    Returns:
        None
	"""
	c_init()
