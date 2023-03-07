import numpy as np

class BlockNNClustering:
    """Block clustering class.
    
    Provides an interface for clustering a 2-dim. array.
    
    Parameters:
    -----------
        min_cluster_size: int, default=0
            Additional threshold on minimum cluster size. If smaller 
            than the block size (2*2=4) this has no effects on the clustering.
    """
    def __init__(self, min_cluster_size=0):
        self.min_cluster_size = min_cluster_size
        self.noise_label = -1
        self.alien_label = -2
        
    """Get block clusters.
    
    Returns 2d array of labels indicating different clusters
    for each value in X. The following labels are used:
        -2 : Xi has different value
        -1 : Xi is not part of any cluster (noise)
      0..n : cluster numbering
      
    Parameters:
    -----------
        X: np.ndarray(int), 2-dim
            Data array.
    """
    def fit(self, X):
        all_labels = []
        X = np.int32(X)
        values = np.unique(X.flatten())
        values.sort()
        for val in values:
            labels = self.__label_clusters(X, val)
            all_labels.append(labels)
            
        return values, all_labels

    """Iterate the not visted array and identify clusters."""
    def __label_clusters(self, X, val):
        Ni, Nj = X.shape
        visited = np.zeros(X.shape)
        labels = np.ones(X.shape) * self.alien_label
        
        current_label = 0
        for i in range(Ni):
            for j in range(Nj):
                if not visited[i, j] and X[i, j] == val:
                    is_noise = self.__flood_fill_blocks(X, i, j, visited, labels, current_label)
                    if not is_noise:
                        current_label += 1
        return labels

    """Flood fill algorithm requiring unified blocks for cluster expansion."""
    def __flood_fill_blocks(self, X, i, j, visited, labels, current_label):
        x = X[i, j]
        Ni, Nj = X.shape

        stack = [[i, j]]
        cluster_indices = []

        while len(stack) > 0:
            i, j = stack.pop(0)
            
            if not visited[i, j]:
                visited[i, j] = 1
                cluster_indices.append([i, j])

                # add blocks
                self.check_add_block(-1, -1, i, j, X, stack, visited)
                self.check_add_block(-1, 1, i, j, X, stack, visited)
                self.check_add_block(1, -1, i, j, X, stack, visited)
                self.check_add_block(1, 1, i, j, X, stack, visited)
        
        # label cluster
        if len(cluster_indices) <= self.min_cluster_size:
            current_label = self.noise_label
            is_noise = True
        else:
            is_noise = False
            
        for l, m in cluster_indices:
            labels[l, m] = current_label
            
        return is_noise

    @staticmethod
    def check_add_block(di, dj, i, j, X, stack, visited):
        Ni, Nj = X.shape
        ii, jj = (i+di) % Ni, (j+dj) % Nj
        x = X[i, j]
        block_indices = [[ii, jj], [ii, j], [i, jj]]
        accepted = []
        for l, m in block_indices:
            if X[l, m] == x:
                accepted.append([l, m])
            else:
                return
            
        if len(accepted) == 3:
            for i, j in accepted:
                if not visited[i, j]:
                    stack.append([i, j])