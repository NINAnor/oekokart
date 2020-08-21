#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Aug 19 08:50:19 2020

@author: -
"""

import os
import sys
#import pickle

from statistics import mean

import numpy as np
import matplotlib

import pandas as pd
import matplotlib as plt
import seaborn as sns

# Import data description from repo of this script
repo_path = "/mnt/ecofunc-data/code/oekokart/predictors"
sys.path.append(repo_path)

def get_metadata():
    import importlib
    import data_description
    importlib.reload(data_description)
    data_dict = data_description.data_dict

    meta_df = pd.DataFrame(columns=["factor_type", "Group", "Variable name", "mapname", "mapsetname", "Description"])

    for dkey1 in data_dict:
        for dkey2 in data_dict[dkey1]:
                for dkey3 in data_dict[dkey1][dkey2]:
                    meta_df.loc[len(meta_df), :] = [dkey1, dkey2, dkey3, *data_dict[dkey1][dkey2][dkey3].values()]
                    #meta_tmp = pd.DataFrame.from_dict()

    return data_dict, meta_df

data_dict, meta_df = get_metadata()

"""
For model comparison and model selection:
    test effect of:
      - sample size (training_n): how much does the model change with the amount of training data in terms of:
          a) model performance
          b) features in the best models
          c) feature importance
      - model type ("rf", "gbrt"): how much does the chosen model type influence the results
      - filtering human influence ("grazing"): how much does the chosen model type influence the results
      - weighting up forest occurrence, cause we know that training a forest line model on the empirical
        forest line will include false positive mountain points in the training data
   - check for correlation of features in group
   - test if features are interchangeable (performance drop among modles with and without the feature)

Y-values:
0 = Open areas above local forest hight
1 = Forest

Confusion of 0 with 1 is more acceptable than the other way around, cause we
know empirical forest line is influenced dowbwards by human activity (e.g. grazing).

Fit a model with grazed areas filtered out and predict climate effects and compare it to a 
model where grazing is not filtered out.
"""

def load_model_run(model_dir="/mnt/ecofunc-data/forest_line_model/", sample_n="0.10"):
    from pathlib import Path
    model_dir = Path(model_dir)
    model_runs = [x for x in model_dir.iterdir() if x.is_dir() and "run_" in x.name]
    model_runs.sort()
    
    for path in model_runs[-1].rglob("*.hdf"):
        print(path.name)
    mod_comp = pd.read_hdf(model_runs[-1].joinpath("logs").joinpath("mod_comb{}.hdf".format(sample_n)))
    return mod_comp

mod_comp = load_model_run(model_dir="/mnt/ecofunc-data/forest_line_model/", sample_n="0.10")

accuracy = "Accuracy_F1_average"
#mod_comp = mod_comp.sort_values(by="R2", ascending=False)
mod_comp = mod_comp.sort_values(by=accuracy, ascending=False)

mod_comp[mod_comp[accuracy] > mean(mod_comp[accuracy])].sort_values(by="confusion_1_0", ascending=True)

mod_comp[:100]["features"]

mod_comp[:2]
mod_comp[:2]["features"]
mod_comp[:2][accuracy]
mod_comp[:2]["confusion_1_0"]
mod_comp[:2]["confusion_0_1"]


mod_freq = []
filter_freq = []
weight_freq = []
feat_freq = []
feat_imp = []
for index, row in mod_comp[:100].iterrows():
    #print(row["features"], row["feature_importance"])
    mod_freq.append(row["model_type"])
    filter_freq.append(row["filter"])
    weight_freq.append(row["filter"])
    feat_freq += list(row["features"])
    feat_imp += list(row["feature_importance"])


# Plot frequency of features in the 100 best models
fig, ax = plt.subplots()
plt.hist(filter_freq)
plt.xticks(rotation=90)
fig.autofmt_xdate()

# Plot frequency of features in the 100 best models
fig, ax = plt.subplots()
plt.hist(feat_freq)
plt.xticks(rotation=90)
fig.autofmt_xdate()

# Plot frequency of features in the 100 best models
fig, ax = plt.subplots()
plt.hist(mod_freq)
plt.xticks(rotation=90)
fig.autofmt_xdate()

df_feat = pd.DataFrame(columns=["features", "feature_importance"])
df_feat["features"] = feat_freq
df_feat["feature_importance"] = feat_imp

df_feat.groupby("features").mean().sort_values(by="feature_importance", ascending=False)
df_feat.groupby("features").max().sort_values(by="feature_importance", ascending=False)
df_feat.groupby("features").min().sort_values(by="feature_importance", ascending=False)

# Plot feature importance for the features in the 100 best models
fig, ax = plt.subplots()
sns.boxplot(x=df_feat["features"], y=df_feat["feature_importance"])
fig.autofmt_xdate()

# Plot feature importance for the features in the 100 best models
for param in ["training_n", "model_type", "filter", "weight", "autocorr"]:
    fig, ax = plt.subplots(nrows=1, ncols=2, constrained_layout=False)
    for idx, score in enumerate([accuracy, "confusion_1_0"]):
        bplot = sns.boxplot(x=mod_comp[param], y=mod_comp[score], ax=ax[idx])
        bplot.set(xlabel=None)

    sns.boxplot(x=mod_comp["filter"], y=mod_comp[accuracy], ax=ax[2, idx])
    sns.boxplot(x=mod_comp["weight"], y=mod_comp[accuracy], ax=ax[3, idx])
    sns.boxplot(x=mod_comp["autocorr"], y=mod_comp[accuracy], ax=ax[4, idx])
    #fig.autofmt_xdate()

# Plot feature importance for the features in the 100 best models
fig, ax = plt.subplots()
sns.boxplot(x=mod_comp["model_type"], y=mod_comp[accuracy])
fig.autofmt_xdate()

# Plot feature importance for the features in the 100 best models
fig, ax = plt.subplots()
sns.boxplot(x=mod_comp["training_n"], y=mod_comp["mse"])
fig.autofmt_xdate()

# Plot feature importance for the features in the 100 best models
fig, ax = plt.subplots()
sns.boxplot(x=mod_comp["model_type"], y=mod_comp["confusion_1_0"])
fig.autofmt_xdate()

fig.set_xticklabels(fig.get_xticklabels(), rotation=90)
plt.show()
plt.close()

mod_comp["training_n_class"] = mod_comp["training_n"].astype("category")
mod_comp[["training_n","R2"]].groupby("training_n").mean()

mod_comp["R2"].astype("numeric")

# Jack-knife analysis
def jacknife(df, feature_set):
    if feature_set.__class__ == set:
        jack_knife = pd.DataFrame(columns=["feature", "accuracy_with", "accuracy_without", "accuracy_max_with", "accuracy_max_without"])
        for feature in feature_set:
            accuracy_with = []
            accuracy_without = []
            
            for index, row in df[["features", accuracy]].iterrows():
                #print(row["features"], row["feature_importance"])
                if feature in row["features"]:
                    accuracy_with.append( row[accuracy])
                else:
                    accuracy_without.append( row[accuracy])
            if len(accuracy_with) < 1:
                accuracy_with = None
            else:
                accuracy_max_with = max(accuracy_with)
                accuracy_with = mean(accuracy_with)
            if len(accuracy_without) < 1:
                accuracy_without = None
                accuracy_max_without = None
            else:
                accuracy_max_without = max(accuracy_without)
                accuracy_without = mean(accuracy_without)
            jack_knife.loc[len(jack_knife), :] = [feature, accuracy_with, accuracy_without, accuracy_max_with, accuracy_max_without]
    
        jack_knife["accuracy_diff"] = jack_knife["accuracy_with"] - jack_knife["accuracy_without"]
        jack_knife["accuracy_max_diff"] = jack_knife["accuracy_max_with"] - jack_knife["accuracy_max_without"]
        jack_knife = jack_knife.sort_values("accuracy_diff", ascending=False)
        return jack_knife
    else:
        return None

jack_knife = jacknife(mod_comp[mod_comp["filter"] == "filtered"], set(df_feat["features"]))
jack_knife

jack_knife_filtered = jacknife(mod_comp[mod_comp["filter"] == "filtered"], set(df_feat["features"]))
jack_knife_filtered

jack_knife_unfiltered = jacknife(mod_comp[mod_comp["filter"] == "unfiltered"], set(df_feat["features"]))
jack_knife_unfiltered

jack_knife_rf = jacknife(mod_comp[mod_comp["model_type"] == "rf"], set(df_feat["features"]))
jack_knife_rf

jack_knife_gbrt = jacknife(mod_comp[mod_comp["model_type"] == "gbrt"], set(df_feat["features"]))
jack_knife_gbrt

jack_knife.sort_values("R2_max_diff", ascending=False)

jacknife(mod_comp[:100], set(df_feat["features"]))
        feat_imp += list(row["feature_importance"])
set(mod_comp[:200].columns).issubset(set(df_feat["features"]))
