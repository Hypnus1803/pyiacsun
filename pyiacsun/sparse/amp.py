import scipy.linalg
import numpy as np
import matplotlib.pyplot as pl

def eta(x, threshold):
    return np.sign(x) * np.fmax(np.abs(x) - threshold, 0)

def etaprime(x, threshold):
    return (x > threshold) + (x < -threshold)

def largestElement(x, n):
    lenx = len(x)
    if (n > lenx):
        n = lenx-1
    if (n < 0):
        n = 0

    t = np.sort(x)[::-1]
    return t[n]

def amp(A, AT, x0, eta, etaprime, b, mu, maxIter=5000, tol=1e-8, alpha=1.0):
    """Solve a linear system of equations imposing a sparsity constraint using the 
    Approximate Message Passing (AMP) algorithm
    
    Ax=b, where A is a matrix, b is a vector and x is the solution, over which a sparsity
    constraint is used.
    
    It solves the following problem
    
    |Ax-b|_2^2 + lambda*psi(x)
    
    where psi(x) is a regularization function whose proximal operator can be obtained
    
    Args:
        A (function): operator that applies the matrix A to an arbitry vector (e.g., A = lambda z : AMatrix.dot(z))
        AT (function): operator that applies the transpose matrix A.T to an arbitry vector (e.g., A = lambda z : AMatrix.T.dot(z))
        x0 (array): vector with the initial solution 
        eta (function): proximal operator associated with the sparsity constraint 
            (e.g., eta = x, threshold : np.sign(x) * np.fmax(np.abs(x) - threshold, 0) for l1 constraint)
        etaprime (TYPE): derivative of the proximal operator associated with the sparsity constraint 
            (e.g., etaprime = x, threshold : (x > threshold) + (x < -threshold) for l1 constraint)
        b (array): vector with the right-hand-side of the equation
        mu (float): regularization parameter
        maxIter (int, optional): maximum number of iterations        
        tol (float, optional): final tolerance
        alpha (float, optional): parameter that can be used to damp the iterations. Useful when using a sensing matrix
            that is not iid Gaussian, the only situation in which AMP is proved to converge
    
    Returns:
        TYPE: Description
    """
    xhat = np.copy(x0)
    z = np.copy(b)
    
    delta = 1.0 * len(b) / len(xhat)

    err = []

    gamm = 0.0

    loop = 0

    continueIteration = True

    while(continueIteration):
        xhat = alpha * eta(xhat + AT(z), mu + gamm) + (1.0-alpha) * xhat

        z = alpha * (b - A(xhat) + z / delta * np.mean(etaprime(xhat + AT(z), mu + gamm))) + (1.0-alpha) * z

        gamm = (mu+gamm) / delta * np.mean(etaprime(xhat + AT(z), mu + gamm))

        stopping = np.linalg.norm(b - A(xhat)) / np.linalg.norm(b)
        err.append(stopping)

        continueIteration = (stopping > tol) and (loop < maxIter)

        if (loop % 10 == 0):
            print("It: {0} - rel. error: {1}".format(loop, stopping))

        loop += 1
        
    return xhat, err

if (__name__ == "__main__"):
    M = 200
    N = 1000
    K = 10

    mu = 0.0005
    sigma = 0.00001

    # Create sparse signal
    x = np.zeros(N)
    ind = np.random.permutation(N)
    x[ind[0:K]] = 1.0

    # Define matrix
    AMat = np.random.normal(size=(M,N))
    AMat /= np.linalg.norm(AMat, 2)

    # Define observation vector
    b = AMat.dot(x)
    b += np.random.normal(scale=sigma, size=b.shape)

    # Initial state
    x0 = np.zeros(N)

    A = lambda z : AMat.dot(z)
    At = lambda z : AMat.T.dot(z)

    sol, err = amp(A, At, x0, eta, etaprime, b, mu, 500, 1e-6, alpha=1.0)

    pl.plot(sol)
    pl.plot(x, 'o')
