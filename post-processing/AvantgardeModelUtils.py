import numpy as np
import pandas as pd
import matplotlib as mpl
import matplotlib.pyplot as plt
import seaborn as sns

from matplotlib.colors import LinearSegmentedColormap

# plot affinity Nk dependence
def LoadSimulation(path, columns=['id','avantgarde', 'affinity', 'affinityGoal', 'step']):
    data = pd.read_csv(path, usecols=columns)
    return data


def Choice(data, step=-1):
    if step == -1:
        return np.array(data["affinity"])
    return np.array(data[data["step"] == step]["affinity"])


def Belief(data, step=-1):
    if step == -1:
        return np.array(data["affinityGoal"])
    return np.array(data.query("step == @step").get("affinityGoal"))


def Avantgarde(data, step=-1):
    if step == -1:
        return np.array(data["avantgarde"])
    return np.array(data.query("step == @step").get("avantgarde"))

                                                    
def Grid(data, size=100):
    return data.reshape(size, size)
                                                    

## create affinity polarization grid plot
# 
# Plot 1
# ------
# Grid plot 
# a | b
# c | d
# with a = affinity step 0, b = polarization step 0, c = affinity step final, d = polarization step final

def ShowState(data, figsize=(7, 3)):
    threshold = 0.5
    finalStep = 200

    colors = ((0.1, 0.1, 0.1), (0.96, 0.94, 0.93))
    cmap_black_white = LinearSegmentedColormap.from_list('Custom', colors, len(colors))
    cmap_blue_red =  mpl.colormaps['coolwarm']

    fig, axes = plt.subplots(1, 2, sharex=True, sharey=True, figsize=figsize)
    sns.heatmap(ax=axes.flatten()[0], data=Grid(data),  
                vmin=0., vmax=1.0, cmap=cmap_blue_red, square=True, cbar_kws={"shrink": .8})
    sns.heatmap(ax=axes.flatten()[1], data=Grid(data) > threshold, 
                vmin=0., vmax=1.0, cmap=cmap_black_white, square=True, cbar_kws={"shrink": .8})

    for ax in axes.flatten():
        ax.tick_params(left=False, bottom=False, top=False)
        ax.set(xticklabels=[], yticklabels=[])

    for ax in (axes.flatten()[1],):
        colorbar = ax.collections[0].colorbar
        colorbar.set_ticks([0.25,0.75])
        colorbar.set_ticklabels(['0', '1'])

    axes.flatten()[0].set_xlabel(r"Choice parameter $c$")
    axes.flatten()[1].set_xlabel(r"Decision $d$")

    plt.gcf().set_dpi(147)
    plt.subplots_adjust(wspace=0.1, hspace=0.1)

    
def DFS(i, j, data, visited, value=0, corner_neighbours=True):
    
    nodes_to_visit = [[i, j]]
    size = 0
    
    if visited[i, j] or data[i, j] != value:
        return size
    
    if corner_neighbours:
        rowNeighbours = [-1, -1, -1, 0, 0, 1, 1, 1] # [-1, 0, 0, 1] #
        columnNeighbours = [-1, 0, 1, -1, 1, -1, 0, 1] # [0, -1, 1, 0] #
    else:
        rowNeighbours = [-1, 0, 0, 1] #
        columnNeighbours = [0, -1, 1, 0] #
    
    while len(nodes_to_visit) > 0:
        i, j = nodes_to_visit[0]
        
        if not visited[i, j] and data[i, j] == value:
            for r, c in zip(rowNeighbours, columnNeighbours):
                iNew = (i+r) % data.shape[0]
                jNew = (j+c) % data.shape[1]
                nodes_to_visit.append([iNew, jNew])
                
            size += 1
            
        visited[i, j] = 1
        nodes_to_visit.pop(0)
    
    return size

def CountSizes(data, skip_size=0, corner_neighbours=False):
    counts = {key: [] for key in np.unique(data.flatten())}
    dwarfs = []
    for c in counts.keys():
        visited = np.zeros(data.shape)
        for i in range(data.shape[0]):
            for j in range(data.shape[1]):
                size = DFS(i, j, data, visited, value=c, corner_neighbours=corner_neighbours)
                if size > skip_size:
                    counts[data[i, j]].append(size)
                elif size > 0:
                    dwarfs.append(size)
    return counts, dwarfs

def RowIndex(i, n_columns): 
    return i % n_columns

def ColIndex(i, n_rows): 
    return i % n_rows

def CheckBlock(r, c, i, j, data, to_visit):
    Ni = data.shape[0]
    Nj = data.shape[1]
    v = data[i, j]
    ij_others = np.array([[RowIndex(i+r, Ni), ColIndex(j+c, Nj)],
                 [RowIndex(i+r, Ni), j],
                 [i, ColIndex(j+c, Nj)]])
    v_others = np.array([data[_i, _j] for _i, _j in ij_others])
    ij_good = ij_others[v_others == v]
    if ij_good.shape[0] > 2:
        to_visit.extend(ij_good.tolist())

def DFS_strong(i, j, data, visited, value=0, corner_neighbours=True):
    
    nodes_to_visit = [[i, j]]
    size = 0
    
    if visited[i, j] or data[i, j] != value:
        return size
    
    if corner_neighbours:
        rowNeighbours = [-1, -1, -1, 0, 0, 1, 1, 1] # [-1, 0, 0, 1] #
        columnNeighbours = [-1, 0, 1, -1, 1, -1, 0, 1] # [0, -1, 1, 0] #
    else:
        rowNeighbours = [-1, 0, 0, 1] #
        columnNeighbours = [0, -1, 1, 0] #
    
    while len(nodes_to_visit) > 0:
        i, j = nodes_to_visit[0]
        
        if not visited[i, j] and data[i, j] == value:
            
            CheckBlock(-1, -1, i, j, data, nodes_to_visit)
            CheckBlock(-1, 1, i, j, data, nodes_to_visit)
            CheckBlock(1, -1, i, j, data, nodes_to_visit)
            CheckBlock(1, 1, i, j, data, nodes_to_visit)
                
            size += 1
            
        visited[i, j] = 1
        nodes_to_visit.pop(0)
    
    return size

def CountSizesStrong(data, skip_size=0, corner_neighbours=False):
    counts = {key: [] for key in np.unique(data.flatten())}
    dwarfs = []
    for c in counts.keys():
        visited = np.zeros(data.shape)
        for i in range(data.shape[0]):
            for j in range(data.shape[1]):
                size = DFS_strong(i, j, data, visited, value=c, corner_neighbours=corner_neighbours)
                if size > skip_size:
                    counts[data[i, j]].append(size)
                elif size > 0:
                    dwarfs.append(size)
    return counts, dwarfs


