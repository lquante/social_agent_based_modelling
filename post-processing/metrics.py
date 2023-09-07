import numpy as np
import pandas as pd

#################
# helpers
def index_to_crds(index, Nx):
    coords = np.zeros(2, dtype='int32')
    coords[1] = int(index % Nx)
    coords[0] = int(index / Nx)
    return coords

def crds_to_index(coords, Nx):
    return int(coords[0] * Nx + coords[1])

def get_neighbour_crds(i, j, Nx, Ny, r=1):
    """
    Returns the list of neighboring indices for a cell at position (i, j)
    in a 2D grid with periodic boundary conditions and dimensions Nx x Ny.
    """
    di_values = list(range(-r, r+1))
    dj_values = list(range(-r, r+1))
    neighbours = [((i+di) % Nx, (j+dj) % Ny)
                 for di in di_values
                 for dj in dj_values
                 if di != 0 or dj != 0]
    return neighbours

def map_index_to_neighbours(idx, N, r=1):
    return [crds_to_index(crd, N) for crd in get_neighbour_crds(*index_to_crds(idx, N), N, N, r=r)]

def create_index_mapping(N, r=1):
    return np.array([map_index_to_neighbours(k, N, r) for k in range(N*N)])

def map_ids(ids, index_to_ids_mapping):
    # to index
    mapped = index_to_ids_mapping[ids - 1]
    return mapped

###############################
# metrics definitions
#############################
def attitude_deviation(dataframe):
    attitudes = dataframe.get("attitude").values
    fixed_attitudes = dataframe.get("fixed_attitude").values
    return np.abs(fixed_attitudes - attitudes)


def decision_alignment(dataframe):
    threshold = 0.5
    decisions = dataframe.get("attitude").values >= threshold
    intrinsic_decisions = dataframe.get("fixed_attitude").values >= threshold
    return decisions == intrinsic_decisions


def density_of_interfaces(array, index_mapping):
    return np.logical_xor(array[index_mapping] >= 0.5, np.tile(array >= 0.5, (8,1)).transpose()).sum() / (8 * array.size)
    

def magnetisation(array):
    return (np.sum(array >= 0.5) - np.sum(array < 0.5)) / array.size

def satisfaction(dataframe, mapping, weights=None):
    df = dataframe.copy()
    df.loc[:, 'relevant_ids'] = map_ids(df['id'].values, mapping).tolist()
    df_attitude = df[['id', 'attitude', 'step', 'seed']].copy()
    df_exploded = df.explode('relevant_ids')
    df_merged = df_exploded.merge(df_attitude, left_on='relevant_ids', right_on='id', suffixes=('', '_match'))
    # keep only with same seed, step
    df_merged = df_merged[(df_merged["seed"] == df_merged["seed_match"]) & (df_merged["step"] == df_merged["step_match"])]
    attitudes = df_merged.groupby(["step", "id", "seed"]).mean(numeric_only=True).get("attitude_match")
    final = pd.concat([df.set_index(["step", 'id', 'seed']), attitudes], axis=1).reset_index()
    attitudes = final["attitude"]
    neighbours_attitudes = final["attitude_match"]
    fixed_attitudes = final["fixed_attitude"]
    self_reliances = final["self_reliance"]
    if weights is None:
        x1 = (1-np.abs(fixed_attitudes - attitudes))
        a = -(7/16)
        b = 23/16
        w1 = a * x1 + b
        w2 = 1
    else:
        w1, w2 = weights
    return (w1 * self_reliances * (1-np.abs(fixed_attitudes - attitudes)) +
            w2 * (1-self_reliances) * (1-np.abs(neighbours_attitudes - attitudes)))


def friends_count(dataframe, index_mapping):
    df = dataframe.copy()
    df.loc[:, 'relevant_ids'] = index_mapping[df['id'].values-1].tolist()
    df_attitude = df[['id', 'attitude', 'step', 'seed']].copy()
    df_exploded = df.explode('relevant_ids')
    df_merged = df_exploded.merge(df_attitude, left_on='relevant_ids', right_on='id', suffixes=('', '_match'))
    df_merged.loc[:, "decision_match"] = df_merged["attitude_match"] >= 0.5
    # keep only with same seed, step
    df_merged = df_merged[(df_merged["seed"] == df_merged["seed_match"]) & (df_merged["step"] == df_merged["step_match"])]
    attitudes = df_merged.groupby(["step", "id", "seed"]).sum().get("decision_match")
    final = pd.concat([df.set_index(["step", 'id', 'seed']), attitudes], axis=1).reset_index()
    decision = final["attitude"] >= 0.5
    n_neighbours = index_mapping[np.array([0])-1][0].size
    friend_count = decision * final["decision_match"] + ~decision * (n_neighbours-final["decision_match"])
    return friend_count.values

def attitude_percentile (dataframe,threshold):
    return np.percentile(["attitude"],threshold)

