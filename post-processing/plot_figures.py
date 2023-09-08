#!/usr/bin/env python
# coding: utf-8

import os
import string
from importlib import reload

from matplotlib.gridspec import GridSpec

import AvantgardeModelUtils

reload(AvantgardeModelUtils)
from AvantgardeModelUtils import *
import metrics

reload(metrics)
from metrics import *

# TODO: adjust paths for your environment
datadir = "/home/quante/mnt/cluster/p/projects/compacts/projects/DeMo/social_agent_based_modelling/data"

ensemble = "initial_attitude_fixed_ensembles"

figuredir = "/home/quante/PIK_Cloud/paper/genericSocialDynamics/figures"

ident = "fixed_equal_initial_attitude"

gamma_means = np.linspace(0.35, 0.95, 13)

sigma_values = np.linspace(0.05, 0.20, 4)

file_uniform = os.path.join(datadir,
                            "uniform_self_reliance_ensembles/agent_data_uniform_distributed-self_reliance_.csv")

gamma_files = {}

for sigma in sigma_values:
    for gamma in gamma_means:
        gamma_files[format(gamma, ".2f"), format(sigma, ".3f")] = os.path.join(datadir,
                                                                               ensemble,
                                                                               "agent_data_normal-self_reliance_mu-" + format(
                                                                                   gamma, ".2f") + "_sigma-" + format(
                                                                                   sigma, ".3f") + ".csv")

# plotting parameters
fontsize = 12
fontsize_label = 8
cm = 1 / 2.54

columns = ["step", "id", "attitude", "self_reliance", "fixed_attitude", "seed"]
uniform_columns = columns  # ["step", "id", "affinity", "avantgarde", "affinityGoal", "seed"]
data_uniform = LoadSimulation(file_uniform, columns=uniform_columns)
sample_uniform = data_uniform.query("seed == 100")

cmap_black_white = LinearSegmentedColormap.from_list('Custom', ((0, 0, 0), (1, 1, 1)), 2)
sns.set(style="white", color_codes=True)

fig, axs = plt.subplots(2, 2, figsize=(12 * cm, 12 * cm), sharex=True, sharey=True)

vmin = 0.0
vmax = 1.0

startStep = 0
endStep = 1000
im1 = sns.heatmap(Grid(Choice(sample_uniform, startStep)),
                  ax=axs[0, 0],
                  square=True,
                  cbar=False,
                  cmap="bwr", vmin=vmin, vmax=vmax)
axs[0, 0].set_title('Initial attitude', size=fontsize_label);
axs[0, 0].text(0.0, 1.05, "a", transform=axs[0, 0].transAxes, size=fontsize_label)

im2 = sns.heatmap(Grid(Choice(sample_uniform, endStep)),
                  ax=axs[0, 1],
                  square=True,
                  yticklabels=False,
                  cbar=False,
                  cmap="bwr", vmin=vmin, vmax=vmax)
axs[0, 1].set_title('Final attitude', size=fontsize_label);
axs[0, 1].text(0.0, 1.05, "b", transform=axs[0, 1].transAxes, size=fontsize_label)

im3 = sns.heatmap(Grid(Choice(sample_uniform, startStep)),
                  ax=axs[1, 0],
                  square=True,
                  yticklabels=False,
                  cbar=False,
                  cmap=cmap_black_white)
axs[1, 0].set_title('Initial decision', size=fontsize_label);
axs[1, 0].text(0.0, 1.05, "c", transform=axs[1, 0].transAxes, size=fontsize_label)

im4 = sns.heatmap(Grid(Choice(sample_uniform, endStep)),
                  ax=axs[1, 1],
                  square=True,
                  yticklabels=False,
                  xticklabels=False,
                  cbar=False,
                  cmap=cmap_black_white)
axs[1, 1].set_title('Final decision', size=fontsize_label);
axs[1, 1].text(0.0, 1.05, "d", transform=axs[1, 1].transAxes, size=fontsize_label)

fig.subplots_adjust(wspace=0.05, hspace=0.15)

mappable = im1.get_children()[0]
fig.colorbar(mappable, ax=axs[0, :], shrink=.8, orientation='vertical', pad=0.03)

mappable_decision = im3.get_children()[0]
colorbar = fig.colorbar(mappable_decision, ax=axs[1, :], shrink=.8, orientation='vertical', pad=0.03)
colorbar.set_ticks([0.25, 0.75])
colorbar.set_ticklabels(['0', '1'])

plt.savefig(os.path.join(figuredir, ident + "_example_initial_final.pdf"), dpi=300)

# plot results for different states
for sigma in sigma_values:
    sigma_key = format(sigma, ".3f")

    data_low_gamma = LoadSimulation(gamma_files["0.50", sigma_key], columns=columns).query("step == 1000")
    data_mid_gamma = LoadSimulation(gamma_files["0.70", sigma_key], columns=columns).query("step == 1000")
    data_high_gamma = LoadSimulation(gamma_files["0.90", sigma_key], columns=columns).query("step == 1000")

    fig = plt.figure(figsize=(16 * cm, 6 * cm))
    gs = GridSpec(nrows=1, ncols=4, width_ratios=[1, 1, 1, 0.1])

    ax = [fig.add_subplot(gs[0, i]) for i in range(3)]

    colors = ((0, 0, 0), (1, 1, 1))
    cmap_black_white = LinearSegmentedColormap.from_list('Custom', colors, len(colors))

    vmin = 0
    vmax = 1

    im2 = sns.heatmap(Grid(data_low_gamma.query("seed==100").get("attitude").values),
                      ax=ax[0],
                      square=True,
                      yticklabels=False,
                      xticklabels=False,
                      cbar=False,
                      cmap="bwr", vmin=vmin, vmax=vmax)

    im3 = sns.heatmap(Grid(data_mid_gamma.query("seed==100").get("attitude").values),
                      ax=ax[1],
                      square=True,
                      yticklabels=False,
                      xticklabels=False,
                      cbar=False,
                      cmap="bwr", vmin=vmin, vmax=vmax)

    im4 = sns.heatmap(Grid(data_high_gamma.query("seed==100").get("attitude").values),
                      ax=ax[2],
                      square=True,
                      yticklabels=False,
                      xticklabels=False,
                      cbar=False,
                      cmap="bwr", vmin=vmin, vmax=vmax)

    fig.subplots_adjust(wspace=0.05, hspace=0.1, left=0.0, right=1.)

    mappable = im4.get_children()[0]
    fig.colorbar(mappable, cax=fig.add_subplot(gs[0, 3]), shrink=.9, orientation='vertical', label="Attitude $A$")

    ax[0].set_title(r"normal $\mu(\gamma) = 0.5$", y=-0.2)
    ax[1].set_title(r"normal $\mu(\gamma) = 0.7$", y=-0.2)
    ax[2].set_title(r"normal $\mu(\gamma) = 0.9$", y=-0.2)

    for index in [0, 1, 2]:
        ax[index].text(-0.05, 1.05, string.ascii_lowercase[index], transform=ax[index].transAxes, size=fontsize)

    plt.tight_layout()
    plt.savefig(os.path.join(figuredir, ident + "_sigma_" + sigma_key + "_results_changing_distributions.pdf"), dpi=300)

cmap = plt.get_cmap('Set2')
gammacolors = [cmap(i) for i in range(6)]
data_uniform = LoadSimulation(file_uniform, columns=uniform_columns)
data_uniform_final = data_uniform.query("step == 1000")

gamma_keys = ["0.50", "0.70", "0.90"]

for sigma in sigma_values:
    sigma_key = format(sigma, ".3f")

    fig, axs = plt.subplots(4, 1, figsize=(17 * cm, 20 * cm), sharex=True)
    histogram(data_uniform_final.query("fixed_attitude < 0.5").get("attitude").values, axs[0], "tab:red")
    histogram(data_uniform_final.query("fixed_attitude >= 0.5").get("attitude").values, axs[0], "tab:blue")
    axs[0].text(-0.05, 1.05, "a" + " uniform distribution of $\gamma$", transform=axs[0].transAxes, size=fontsize)

    for i, gamma in enumerate(gamma_keys):
        index = i + 1
        gamma_data = LoadSimulation(gamma_files[gamma, sigma_key], columns=columns).query("step == 1000")

        histogram(gamma_data.query("fixed_attitude < 0.5").get("attitude").values, axs[index],
                  "tab:red", label="low $\gamma$ con", alpha=0.25, bins=500)
        histogram(gamma_data.query("fixed_attitude >= 0.5").get("attitude").values, axs[index],
                  "tab:blue", label="low $\gamma$ pro", alpha=0.25, bins=500)
        axs[index].text(-0.05, 1.05,
                        string.ascii_lowercase[index] + " normal distribution of $\gamma$ with mean " + gamma_keys[
                            index - 1], transform=axs[index].transAxes, size=fontsize)

    for ax in axs:
        ax.set_xlim(0.0, 1.0)

    plt.xlabel("Final attitude")
    plt.tight_layout()
    plt.savefig(os.path.join(figuredir, ident + "_sigma_" + sigma_key + "_inherent_decision_distribution.pdf"), dpi=300)

gamma_keys = ["0.50", "0.60", "0.70", "0.80", "0.90"]
for sigma in sigma_values:
    sigma_key = format(sigma, ".3f")

    merged_data = pd.concat(
        [LoadSimulation(gamma_files[gamma, sigma_key], columns=columns).query("step == 1000") for gamma in gamma_keys])
    fig, axs = plt.subplots(1, 1, figsize=(12 * cm, 8 * cm))

    cmap = plt.get_cmap('viridis')
    positions = [0.2, 0.5, 0.8]
    colors = [cmap(pos) for pos in positions]

    histogram(merged_data.query("self_reliance <= 1/3").get("attitude").values, axs,
              colors[0], label="$\gamma \leq 1/3$", median=False, alpha=0.5)
    histogram(merged_data.query("self_reliance > 1/3").query("self_reliance <= 2/3").get("attitude").values, axs,
              colors[1], label="$1/3 < \gamma \leq 2/3 $", median=False, alpha=0.5)
    histogram(merged_data.query("self_reliance > 2/3").get("attitude").values, axs,
              colors[2], label="$2/3 < \gamma$", median=False, alpha=0.5)

    axs.legend()
    axs.set_xlim([0, 1])
    plt.xlabel("Final attitude")
    plt.tight_layout()
    plt.savefig(os.path.join(figuredir, ident + "_sigma_" + sigma_key + "_spread_by_self_reliance_bins.pdf"), dpi=300)

percentile_thresholds = [0.075, (1 / 6), 1 / 4, 1 / 2, 3 / 4, (5 / 6), 0.925]


def process_file(file):
    print(f"Working on: {file}")
    data = LoadSimulation(file, columns=["seed", "id", "self_reliance", "attitude", "fixed_attitude", "step"])
    final_step_data = data.query("step == 1000")
    mean = final_step_data.get("self_reliance").mean()
    metrics = {}
    # get metrics
    metrics["friends_mean"] = []
    metrics["decision_mean"] = []
    metrics["attitude_percentiles"] = []

    for s, sample in final_step_data.groupby("seed"):
        # metrics["friends_mean"].append(np.mean(np.array(friends_count(sample, mapping)) / 8))
        metrics["decision_mean"].append(np.mean(decision_alignment(sample).astype(float)))
        metrics["attitude_percentiles"].append(np.quantile(sample["attitude"], percentile_thresholds))
    return mean, metrics


import warnings

warnings.filterwarnings('ignore')

dict_avantgarde_means = {}
results_by_distr_mean_avantgarde = {}

location = os.path.join(datadir, ensemble)

fkey = "agent_data_normal-self_reliance"
for sigma in sigma_values:
    sigma_key = format(sigma, ".3f")
    files = []
    dict_avantgarde_means[sigma_key] = []
    for fname in os.listdir(location):
        if f"{sigma_key}" in fname and f"{fkey}" in fname:
            files.append(os.path.join(location, fname))
    for file in files:
        avantgarde_mean, metrics_dict = process_file(file)
        results_by_distr_mean_avantgarde[sigma_key, avantgarde_mean] = metrics_dict
        dict_avantgarde_means[sigma_key].append(avantgarde_mean)


def analytical_decision_alignment(gamma):
    prob_n_positive = 4 / 8
    prob_n_negative = prob_n_positive
    prob_n_zero = 1 - prob_n_positive - prob_n_negative
    gamma_fraction = (1 - gamma) * 1 / gamma
    n_positive_uniform_prob = np.minimum(1.0, np.maximum(0.0, (0.5 - gamma_fraction) * 2))

    return 0.5 * prob_n_zero + prob_n_positive * (0.5 * n_positive_uniform_prob + 0.5) + prob_n_negative * (
            0.5 * (n_positive_uniform_prob) + 0.5)


def get_y_values_ci(x_values, datadict, sigma, key, ci):
    mean = []
    lower_ci = []
    upper_ci = []
    for x_value in x_values:
        values = datadict[sigma, x_value][key]
        mean.append(np.mean(values))
        lower_ci.append(np.percentile(values, ci[0]))
        upper_ci.append(np.percentile(values, ci[1]))
    return mean, lower_ci, upper_ci


def get_y_values_c_percentile(x_values, datadict, sigma, key, percentile, ci):
    mean = []
    lower_ci = []
    upper_ci = []
    for x_value in x_values:
        values = datadict[sigma, x_value][key]
        index = percentile_thresholds.index(percentile)
        percentile_values = [i_value[index] for i_value in values]
        mean.append(np.mean(percentile_values))
        lower_ci.append(np.percentile(percentile_values, ci[0]))
        upper_ci.append(np.percentile(percentile_values, ci[1]))
    return mean, lower_ci, upper_ci


confidence_interval_bounds = [5, 95]

for percentile in percentile_thresholds:
    percentile_label = str(round(percentile * 100, 1))
    for sigma in sigma_values:
        sigma_key = format(sigma, ".3f")
        fig, axes = plt.subplots(1, 2, figsize=(15 * cm, 10 * cm), constrained_layout=True)

        gammas = np.arange(0.5, 1.025, 0.025)

        x_values = np.sort(dict_avantgarde_means[sigma_key])

        y_values_decision_alingment = get_y_values_ci(x_values, results_by_distr_mean_avantgarde, sigma_key,
                                                      "decision_mean", confidence_interval_bounds)

        axes[0].plot(x_values, y_values_decision_alingment[0], color="tab:blue", lw=1, marker=".", ms=3)
        axes[0].fill_between(x_values, y_values_decision_alingment[1], y_values_decision_alingment[2], color="tab:blue",
                             alpha=0.25)

        axes[0].set_ylabel("Decision Alignment")
        axes[0].set_ylim([0.5, 1])

        axes[0].plot(gammas, analytical_decision_alignment(gammas), color="grey", lw=1, ls=":")

        y_values_percentile = get_y_values_c_percentile(x_values, results_by_distr_mean_avantgarde, sigma_key,
                                                        "attitude_percentiles", percentile, confidence_interval_bounds)

        axes[1].plot(x_values, (np.array(y_values_percentile[0])), color="tab:orange", lw=1, marker=".", ms=3)
        axes[1].fill_between(x_values, (np.array(y_values_percentile[1])), (np.array(y_values_percentile[2])),
                             color="tab:orange", alpha=0.25)
        axes[1].set_ylabel(percentile_label + "th percentile of attitude")

        for i, ax in enumerate(axes):
            ax.set_xlabel(r"Mean self-reliance $\langle \gamma \rangle$")
            ax.set_xlim((0.45, 0.9))
            ax.text(-0.075, 1.075, chr(ord('a') + i), transform=ax.transAxes, size=fontsize)
        plt.savefig(os.path.join(figuredir,
                                 ident + "_sigma_" + sigma_key + "_alignment_" + percentile_label + "_percentile.pdf"),
                    dpi=300)
