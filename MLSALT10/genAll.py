import subprocess
import numpy as np
from scipy.optimize import minimize
import pdb
from numpy.linalg import pinv as inv 
import numpy as np
from multiprocessing import Pool
from time import time

gvarmean = subprocess.check_output(['./bin/x2x', '+da', 'models/hts/gv-mcep.pdf'])
gvarmean= gvarmean.split()

gmeans = gvarmean[0:60]
gsig = gvarmean[60:120]

def retDur(durationFile):
    durations =[]
    with open(durationFile, 'r') as f:
        lines = f.read().splitlines()
        for row in lines:
            moment = row.split()
            if len(moment)==10:
                for i in range(5):
                    durations.append(int(round(float(moment[i]))))
    return durations

def meansAndVar(uttfile, durations):
    with open(uttfile, "r") as f:
        means=[]
        var = []
        T = sum(durations)
        lines = f.read().splitlines()
        for line in lines:
            expts = line.split()
            if len(expts)==6:
                means.append(expts[0:3])
                var.append(expts[3:6])
        
    meansFinal = np.zeros(T * 3)
    varFinal = np.zeros(T * 3)
    
    frame = 0
    
    for i in range(len(durations)):
        for t in range(durations[i]):
            meansFinal[frame:frame+3] = means[i]
            varFinal[frame:frame+3] = var[i]
            frame+=3
    
    varFinal = np.diag(varFinal)   
    return (meansFinal, varFinal)


def weightMate(durations,T):
    T = sum(durations)
    window = np.array([[0.0,0.0,1.0,0.0,0.0],[-0.2,-0.1,0.0,0.1,0.2],[0.285714,-0.142857,-0.285714,-0.142857,0.285714]])
    W = np.zeros([3*T,T])  
    frame = 0
    counter = 0
    for i in range(T):
        if i==0:
            W[frame:frame+3,0:3]= window[:,2:]
            
        elif i==1:
            W[frame:frame+3,0:4]= window[:,1:]
        
        elif counter>=T-4:
            W[frame:frame+3, counter:counter+T-i+2] = window[:,:T-i+2]
            counter+=1
        else:
            W[frame:frame+3, counter:counter+5] = window
            counter+=1
        frame+=3    
    return W

def traj(W, means, var):
    varinv = np.linalg.pinv(var)
    varMaj = np.linalg.pinv(np.dot(np.dot(np.transpose(W),varinv),W))
    mu = np.dot(np.dot(np.dot(varMaj, np.transpose(W)),varinv),means)
    return mu, varMaj

def gvExpt(x,*args):
    T = args[0]
    trajmeans = args[1]
    trajvarinv = args[2]
    gmu = args[3]
    gvar = args[4]

    
    alpha = 3*T
    
    orig = (1/2)*np.dot(np.dot(np.transpose(x - trajmeans),trajvarinv), (x-trajmeans))
    globvar = (alpha/2) *(x.var()-gmu )**2/gvar
    print (orig+globvar)
    return (orig+globvar)

def jacobian(x,*args):
    T = args[0]
    trajmeans = args[1]
    trajvarinv = args[2]
    gmu = args[3]
    gvar = args[4]

    alpha = 3*T
    orig =  np.dot(np.transpose(x-trajmeans), trajvarinv)
    globvar = (2*alpha/(gvar*T))*(x.var()-gmu)*(x-np.mean(x))
    return (orig+globvar)

def gvConst(lambda_,*args):
    
    T = args[0]
    trajmeans = args[1]
    trajvarinv = args[2]
    gmu = args[3]
    gvar = args[4]
    P = args[5]
    I = args[6]
    b = args[7]
    onevec = args[8]
    
    
    alpha = 3*T
    x = cGen(lambda_,P, I, b,onevec,T)
    orig = (1/2)*np.dot(np.dot(np.transpose(x - trajmeans),trajvarinv), (x-trajmeans))
    globvar = (alpha/2) *(x.var()-gmu )**2/gvar
    return (orig+globvar)

def cGen(lambda_,P, I, b,onevec,T):
    
    mat= inv(P-lambda_*I)
    
    v = lambda_ * np.dot( np.dot(np.transpose(b), mat), onevec)/ (T + lambda_ *np.dot(np.transpose(onevec), np.dot(mat, onevec)))

    c = np.dot(mat, b - v* onevec)
    return c


def execute(dim,utt):
        durationFile = "expts/utt"+str(utt)+".dur.expt"
        proc = subprocess.Popen(['/bin/bash'], stdin=subprocess.PIPE, stdout=subprocess.PIPE)
        proc.communicate('./scripts/getexpert.sh -hmmdir models/htk -labdir original/lab -stream 1 -dimension '+str(dim) +' -outdir expts  -filename utt'+str(utt))

        durationFile = "expts/utt"+str(utt)+".dur.expt"
        durations = retDur(durationFile)
        uttfile = "expts/utt"+str(utt)+".cmp.expt"
        means, var = meansAndVar(uttfile, durations)
        
        T = sum(durations)
        W = weightMate(durations,T)
        trajmeans, trajvar = traj(W, means, var)
        
        with open("trajCustom/utt"+str(utt)+"/dim"+str(dim)+"/cNoGV.txt", "w+") as f:
            np.savetxt(f, trajmeans)
        
        gmu= float(gmeans[dim-1])
        gvar = float(gsig[dim-1])
        print "gmu: ",gmu
        print "gvar: ",gvar
        
        x_init = np.zeros(len(trajmeans))
        trajvarinv = inv(trajvar)
        T = sum(durations)
        
        P = trajvarinv
        b = np.dot(P,trajmeans)
        lambda_init = np.random.random()

        I = np.identity(T)
        onevec = np.ones(T)
        
        print "x_init: ",x_init
        print "T: ", T
        
        cExp = minimize(gvExpt, x_init, args = (T,trajmeans,trajvarinv,gmu,gvar), jac = jacobian, method='L-BFGS-B')
        
        
        with open("trajCustom/utt"+str(utt)+"/dim"+str(dim)+"/cExpGV.txt", "w+") as f:
                np.savetxt(f, cExp.x)
        
        lamda_const = minimize(gvConst, lambda_init,args=(T,trajmeans,trajvarinv,gmu,gvar,P,I,b,onevec))
        
        lambda_opt = lamda_const.x[0]
        
        cConst = cGen(lambda_opt,P, I, b,onevec,T)
        
        with open("trajCustom/utt"+str(utt)+"/dim"+str(dim)+"/cConstGV.txt", "w+") as g:
            np.savetxt(g, cConst)
        print "dim: ", dim

def uttexec(utt):
       for dim in range(3,61):
            print "utt: ", utt
            execute(dim,utt)
            
n_proc = 1
job_list = range(1, 10)
pool = Pool(processes=n_proc)
start = time()
pool.map(uttexec, job_list)
    
    
        
        
