# -*- coding: utf-8 -*-
"""
Created on Tue Nov 16 16:53:28 2021

@author: stecheme
"""

import networkx as nx
from netwulf import visualize
from networkx.algorithms import community

G = nx.petersen_graph()
nx.draw(G, with_labels=True, font_weight='bold')


G = nx.barabasi_albert_graph(100,m=1)

visualize(G)

nx.clustering(G)

communities_generator = community.girvan_newman(G)

top_level_communities = next(communities_generator)

next_level_communities = next(communities_generator)

sorted(map(sorted, next_level_communities))

from networkx.algorithms.community import greedy_modularity_communities

G = nx.karate_club_graph()

c = list(greedy_modularity_communities(G))

sorted(c[0])