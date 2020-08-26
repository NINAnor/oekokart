#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Aug 19 08:50:19 2020

@author: -


For model comparison and model selection:
    test effect of:
      - sample size (training_n): how much does the model change with the amount of training data in terms of:
          a) model performance
          b) features in the best models
          c) feature importance (esp. for locally relevant features)
      - model type ("rf", "gbrt"): how much does the chosen model type influence the results
        # GBRT is known to outperform RF with imbalanced data
      - filtering human influence ("grazing"): how much does the chosen model type influence the results
        Hypothesis: filtering improves the recall score (= fewer false positives (here positives (1) = forest))
      - weighting up forest occurrence, cause we know that training a forest line model on the empirical
        forest line will include false negative (mountain like (open) areas below forest line) points in
        the training data, while false positive (forest above forest line is unlikely to occure (apart from
        normal imprecision in the data))
      - does filtering and weighting impact feature importance?
        Hypothesis: importance of the spatial term decreases, importance of broader climate features increases
   - check for correlation of features in group (are the best models affected by colinearity)
   - test if features are interchangeable (performance drop among modles with and without the feature)

Y-values:
0 = Open areas above local forest hight
1 = Forest

Confusion of 0 with 1 is more acceptable than the other way around, cause we
know empirical forest line is influenced downwards by human activity (e.g. grazing).

Use recall score for model selection
compare (plot) filtered vs. unfiltered; weighted vs. unweighted; spatial vs. non-spatial

refit the best models with increased training n (maybe in an intermediate step compare more local variables with more training n)
fit a Bayesian model for comparison

Fit a model with grazed areas filtered out and predict climate effects and compare it to an identical
model where grazing is not filtered out.
Visualize the difference.

"""

# import os
import sys

# import pickle

from statistics import mean

# import numpy as np
import pandas as pd
from matplotlib import pyplot as plt
import seaborn as sns


def get_metadata(repo_path="/mnt/ecofunc-data/code/oekokart/predictors"):
    """Load metadata for input data in model runs"""
    # Import data description from repo of this script
    sys.path.append(repo_path)
    import importlib
    import data_description

    importlib.reload(data_description)
    meta_data_dict = data_description.data_dict

    meta_data_df = pd.DataFrame(
        columns=[
            "factor_type",
            "Group",
            "Variable name",
            "mapname",
            "mapsetname",
            "Description",
        ]
    )

    for dkey1 in meta_data_dict:
        for dkey2 in meta_data_dict[dkey1]:
            for dkey3 in meta_data_dict[dkey1][dkey2]:
                meta_data_df.loc[len(meta_data_df), :] = [
                    dkey1,
                    dkey2,
                    dkey3,
                    *meta_data_dict[dkey1][dkey2][dkey3].values(),
                ]
                # meta_tmp = pd.DataFrame.from_dict()

    return meta_data_dict, meta_data_df


def load_model_run(model_dir="/mnt/ecofunc-data/forest_line_model/", sample_n=None):
    """Load results from model screening"""
    from pathlib import Path

    model_dir = Path(model_dir)
    model_runs = [x for x in model_dir.iterdir() if x.is_dir() and "run_" in x.name]
    model_runs.sort(reverse=True)
    # print(model_runs)
    mod_comp_list = []
    # for path in model_runs[0].rglob("*.hdf"):
    #    print(path, path.name)
    for n_sample in sample_n:
        # print([model_runs[0].rglob("*mod_comb{}.hdf".format(sample_n)))
        mod_comp_list.append(
            pd.read_hdf(
                model_runs[0]
                .joinpath("logs")
                .joinpath("mod_comb_{}.hdf".format(n_sample))
            )
        )
    mod_comp_df = pd.concat(mod_comp_list)
    return mod_comp_df


def get_feature_importance(data_frame):
    """Extract feature importances fromlist"""
    feat_freq = []
    feat_imp = []
    for df_row in data_frame.itertuples():
        # print(row["features"], row["feature_importance"])
        feat_freq += list(df_row.features)
        feat_imp += list(df_row.feature_importance)

    df_feat = pd.DataFrame(columns=["features", "feature_importance"])
    df_feat["features"] = feat_freq
    df_feat["feature_importance"] = feat_imp

    return df_feat


# Jack-knife analysis
def jacknife(mod_comp_df, feature_set, score):
    """Compare model performance with and wthout feature"""
    jack_knife_df = None
    if feature_set.__class__ == set:
        jack_knife_df = pd.DataFrame(
            columns=[
                "feature",
                "accuracy_with",
                "accuracy_without",
                "accuracy_max_with",
                "accuracy_max_without",
            ]
        )
        for feature in feature_set:
            accuracy_with = []
            accuracy_without = []

            for df_row in mod_comp_df[["features", score]].itertuples():
                # print(row["features"], row["feature_importance"])
                if feature in df_row.features:
                    accuracy_with.append(df_row[2])
                else:
                    accuracy_without.append(df_row[2])
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
            jack_knife_df.loc[len(jack_knife_df), :] = [
                feature,
                accuracy_with,
                accuracy_without,
                accuracy_max_with,
                accuracy_max_without,
            ]

        jack_knife_df["accuracy_diff"] = (
            jack_knife_df["accuracy_with"] - jack_knife_df["accuracy_without"]
        )
        jack_knife_df["accuracy_max_diff"] = (
            jack_knife_df["accuracy_max_with"] - jack_knife_df["accuracy_max_without"]
        )
        jack_knife_df = jack_knife_df.sort_values("accuracy_diff", ascending=False)
    return jack_knife_df


def main():
    """Do the real work"""

    meta_df = get_metadata()[1]

    mod_comp = load_model_run(
        model_dir="/mnt/ecofunc-data/forest_line_model/", sample_n=[10000, 20000]
    )

    accuracy = "Accuracy_F1"
    recall = "Accuracy_Recall"

    # mod_comp = mod_comp.sort_values(by="R2", ascending=False)
    mod_comp = mod_comp.sort_values(by=recall, ascending=False)

    mod_comp = mod_comp.sort_values(by="confusion_0_1", ascending=True)

    print(
        mod_comp[mod_comp["filter"].astype("string") == "filtered"]["confusion_0_1"]
        .astype("float")
        .describe(percentiles=[0.01, 0.1])
    )
    print(
        mod_comp[mod_comp["filter"].astype("string") == "unfiltered"]["confusion_0_1"]
        .astype("float")
        .describe(percentiles=[0.01, 0.1])
    )

    print(mod_comp[:100]["features"])

    print(
        mod_comp[mod_comp["filter"].astype("string") == "filtered"][
            "confusion_0_1"
        ].mean()
    )
    print(
        mod_comp[mod_comp["filter"].astype("string") == "filtered"][
            "confusion_1_0"
        ].mean()
    )
    print(
        mod_comp[mod_comp["filter"].astype("string") == "unfiltered"][
            "confusion_0_1"
        ].mean()
    )
    print(
        mod_comp[mod_comp["filter"].astype("string") == "unfiltered"][
            "confusion_1_0"
        ].mean()
    )

    print(
        mod_comp[mod_comp["filter"].astype("string") == "filtered"][
            "confusion_0_1"
        ].min()
    )
    print(
        mod_comp[mod_comp["filter"].astype("string") == "filtered"][
            "confusion_1_0"
        ].min()
    )
    print(
        mod_comp[mod_comp["filter"].astype("string") == "unfiltered"][
            "confusion_0_1"
        ].min()
    )
    print(
        mod_comp[mod_comp["filter"].astype("string") == "unfiltered"][
            "confusion_1_0"
        ].min()
    )

    # Plot frequency of features in the 100 best models
    fig, axis = plt.subplots()
    plt.hist(
        mod_comp[
            (mod_comp["filter"].astype("string") == "filtered")
            & (mod_comp["spatial_term"].astype("string") != "spatial")
        ]["confusion_0_1"],
        histtype="step",
        label="filtered",
        bins=100,
    )
    plt.hist(
        mod_comp[
            (mod_comp["filter"].astype("string") == "unfiltered")
            & (mod_comp["spatial_term"].astype("string") != "spatial")
        ]["confusion_0_1"],
        histtype="step",
        label="unfiltered",
        bins=100,
    )
    # plt.hist(filter_freq)
    plt.xticks(rotation=90)
    plt.legend()
    fig.autofmt_xdate()

    print(mod_comp[:2]["features"])
    print(mod_comp[:2][accuracy])
    print(mod_comp[:2]["confusion_1_0"])
    print(mod_comp[:2]["confusion_0_1"])

    df_feat_test = get_feature_importance(mod_comp[:5])

    df_feat_test.groupby("features").mean().sort_values(
        by="feature_importance", ascending=False
    )
    df_feat_test.groupby("features").max().sort_values(
        by="feature_importance", ascending=False
    )
    df_feat_test.groupby("features").min().sort_values(
        by="feature_importance", ascending=False
    )

    # Plot frequency of features in the 100 best models
    # fig, axis = plt.subplots()
    # plt.hist(filter_freq)
    # plt.xticks(rotation=90)
    # fig.autofmt_xdate()

    df_feat_test.features.value_counts().sort_values(ascending=False).plot.bar()

    # Plot frequency of features in the 100 best models
    fig, axis = plt.subplots()
    plt.hist(df_feat_test.features)
    plt.xticks(rotation=90)
    fig.autofmt_xdate()

    # Plot frequency of features in the 100 best models
    # fig, axis = plt.subplots()
    # plt.hist(mod_freq)
    # plt.xticks(rotation=90)
    # fig.autofmt_xdate()

    # Plot feature importance for the features in the 100 best models
    fig, axis = plt.subplots()
    sns.boxplot(x=df_feat_test["features"], y=df_feat_test["feature_importance"])
    fig.autofmt_xdate()

    # Plot feature importance for the features in the 100 best models
    for param in ["model_type", "filter", "weight", "spatial_term"]:
        fig, axis = plt.subplots(nrows=1, ncols=2, constrained_layout=False)
        for idx, score in enumerate([accuracy, "confusion_0_1"]):
            bplot = sns.boxplot(
                x=mod_comp[param],
                y=mod_comp[score],
                ax=axis[idx],
                hue=mod_comp["training_n"],
            )
            bplot.set(xlabel=None)

    # Plot feature importance for the features in the 100 best models
    for param in ["model_type", "filter", "weight", "spatial_term"]:
        in_data = mod_comp[:100]
        fig, axis = plt.subplots(nrows=1, ncols=2, constrained_layout=False)
        for idx, score in enumerate([accuracy, "confusion_1_0"]):
            bplot = sns.boxplot(
                x=in_data[param],
                y=in_data[score],
                ax=axis[idx],
                hue=in_data["training_n"],
            )
            bplot.set(xlabel=None)

        # sns.boxplot(x=mod_comp["filter"], y=mod_comp[accuracy], ax=axis[2, idx])
        # sns.boxplot(x=mod_comp["weight"], y=mod_comp[accuracy], ax=axis[3, idx])
        # sns.boxplot(x=mod_comp["autocorr"], y=mod_comp[accuracy], ax=axis[4, idx])
        # fig.autofmt_xdate()

    ## Plot feature importance for the features in the 100 best models
    # fig, axis = plt.subplots()
    # sns.boxplot(x=mod_comp["model_type"], y=mod_comp[accuracy])
    # fig.autofmt_xdate()
    #
    ## Plot feature importance for the features in the 100 best models
    # fig, axis = plt.subplots()
    # sns.boxplot(x=mod_comp["training_n"], y=mod_comp["mse"])
    # fig.autofmt_xdate()
    #
    ## Plot feature importance for the features in the 100 best models
    # fig, axis = plt.subplots()
    # sns.boxplot(x=mod_comp["model_type"], y=mod_comp["confusion_1_0"])
    # fig.autofmt_xdate()

    fig.set_xticklabels(fig.get_xticklabels(), rotation=90)
    plt.show()
    plt.close()

    # mod_comp["training_n_class"] = mod_comp["training_n"].astype("category")
    # mod_comp[["training_n", "R2"]].groupby("training_n").mean()

    # mod_comp["R2"].astype("numeric")

    feature_set = set(
        list(meta_df[meta_df["factor_type"] == "predictor"]["Variable name"])
        + ["v_y", "v_x"]
    )

    jack_knife = jacknife(
        mod_comp[:10000], feature_set, recall
    )  # [mod_comp["filter"] == "filtered"]
    print(jack_knife)

    jack_knife_accuracy = jacknife(
        mod_comp[:10000], feature_set, accuracy
    )  # [mod_comp["filter"] == "filtered"]
    print(jack_knife_accuracy)

    jack_knife_filtered = jacknife(
        mod_comp[mod_comp["filter"] == "filtered"][:10000], feature_set, recall
    )
    print(jack_knife_filtered)

    jack_knife_unweighted = jacknife(
        mod_comp[mod_comp["weight"] == "unweighted"][:10000], feature_set, recall
    )
    print(jack_knife_unweighted)

    jack_knife_weighted = jacknife(
        mod_comp[mod_comp["weight"] == "weighted"][:10000], feature_set, recall
    )
    print(jack_knife_weighted)

    jack_knife_unfiltered = jacknife(
        mod_comp[mod_comp["filter"] == "unfiltered"][:10000], feature_set, recall
    )
    print(jack_knife_unfiltered)

    jack_knife_rf = jacknife(
        mod_comp[mod_comp["model_type"] == "rf"][:10000], feature_set, recall
    )
    print(jack_knife_rf)

    jack_knife_gbrt = jacknife(
        mod_comp[mod_comp["model_type"] == "gbrt"][:10000], feature_set, recall
    )
    print(jack_knife_gbrt)

    jack_knife_10 = jacknife(
        mod_comp[mod_comp["training_n"].astype("int") == 10000][:10000],
        feature_set,
        accuracy,
    )
    print(jack_knife_10)

    jack_knife_20 = jacknife(
        mod_comp[mod_comp["training_n"].astype("int") == 20000][:10000],
        feature_set,
        accuracy,
    )
    print(jack_knife_20)
    jack_knife_20.sort_values("accuracy_with", ascending=False)

    # feat_imp += list(row["feature_importance"])

    # set(mod_comp[:200].columns).issubset(set(df_feat["features"]))


if __name__ == "__main__":
    main()
