# !/usr/bin/python
"""
args: <file> : csv file with data
"""

import sys
import numpy as np
# import matplotlib.pyplot as plt
import pandas as pd


# begin main
# -----------------------------------------------------------------
# load data
fname = sys.argv[1] # "data/avantgarde/avantgarde_ensemble_2022-03-28T13:09:29.107.csv"
print(fname)
columns = ['step', 'id', 'affinity', 'state']
data = pd.read_csv(fname, usecols=columns)

affinity = lambda step: np.array(data[data['step'] == step]['affinity'])
state = lambda step: np.array(data[data['step'] == step]['state'])
density = lambda state: np.sum(state) * 1. / state.size

# density evolution
threshold = 0.5

nSteps = np.amax(data['step'])
for k in range(nSteps):
    avg_affinity = np.mean(affinity(k))
    rho = density(state(k))
    print(f'after step {k} -> density = {rho:.2f} and avg affinity = {avg_affinity:.2f}')
    if abs(rho - 1.) < 1e-7:
        break

# -----------------------------------------------------------------
# end
