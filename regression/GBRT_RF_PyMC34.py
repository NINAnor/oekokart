#!/bin/env/python3

# Import build-in libraries
import os
import sys
from io import BytesIO

# from subprocess import PIPE
# from collections import OrderedDict
from time import time
import warnings

import pickle

from itertools import product

# Import libraries for matrix operations
import numpy as np
import numpy.lib.recfunctions as rf
import pandas as pd

# Import visualisation libraries
# matplotlib.use('pdf') # Must be before importing matplotlib.pyplot or pylab!
import matplotlib.pyplot as plt
# from matplotlib.ticker import PercentFormatter
import seaborn as sns

# Import machine learning libraries
# matplotlib.use('WXAgg') # Must be before importing matplotlib.pyplot or pylab!
# %matplotlib inline
from sklearn import ensemble
from sklearn.model_selection import cross_val_score
from sklearn.utils import shuffle
from sklearn.metrics import mean_squared_error
from sklearn.metrics import r2_score
from sklearn.metrics import f1_score
from sklearn.ensemble.partial_dependence import plot_partial_dependence
from sklearn.model_selection import GridSearchCV  # , cross_validate

# import theano as thno
# import theano.tensor as T

# from scipy.optimize import fmin_powell
# from scipy import integrate


# Import libraries for bayesian statistics
import pymc3 as pm

# import pymc4 as pm4
# from pymc3 import Model

# from pymc4 import Model
import arviz as az

az.style.use("arviz-darkgrid")


warnings.filterwarnings("ignore")

# import pymc4 as pm4


# Import data description from repo of this script
repo_path = "/mnt/ecofunc-data/code/oekokart/"
sys.path.append(repo_path)

def get_metadata():
    import importlib
    import predictors
    importlib.reload(predictors)
    data_dict = predictors.data_description.data_dict

    meta_df = pd.DataFrame(columns=["factor_type", "Group", "Variable name", "mapname", "mapsetname", "Description"])

    for dkey1 in data_dict:
        for dkey2 in data_dict[dkey1]:
                for dkey3 in data_dict[dkey1][dkey2]:
                    meta_df.loc[len(meta_df), :] = [dkey1, dkey2, dkey3, *data_dict[dkey1][dkey2][dkey3].values()]
                    #meta_tmp = pd.DataFrame.from_dict()

    return data_dict, meta_df

data_dict, meta_df = get_metadata()

data_dict

def update_attributes(vmap, layer=1, meta_dict=data_dict, varname=None):
    col_types = {"CELL": "int",
                 "FCELL": "real",
                 "DCELL": "real"}
    for ddict in data_dict.items():
        for vardict in ddict[1].values():
            if varname in vardict:
                rmap = vardict[varname]["mapname"] + "@" + vardict[varname]["mapset"]
                if not varname in gs.vector.vector_columns(vmap, layer=layer):
                    rinfo = gs.raster.raster_info(rmap)
                    gs.run_command("v.db.addcolumn", map=vmap, layer=layer, columns="{} {}".format(varname, col_types[rinfo["datatype"]]))

                gs.use_temp_region()
                gs.run_command("g.region", align=rmap, vector=vmap)
                gs.run_command("v.what.rast", map=vmap, layer=layer, raster=rmap, column=varname)
                gs.del_temp_region()


# save trained model
def save_model(directory, name, trace, model):
    with open(os.path.join(directory, "{}.pkl".format(name)), "wb") as buff:
        pickle.dump({"model": model, "trace": trace}, buff)
    return None


# reload trained model
def load_model(directory, name):
    with open(os.path.join(directory, "{}.pkl".format(name)), "rb") as buff:
        data = pickle.load(buff)
    # network, trace = data[ 'model' ], data[ 'trace' ]
    return data


start = time()
print("Libraries loaded")

OUTPUT_PREFIX = "GBRT_2e6_output_single_3rd_run"


def setParamDict():
    params = {}
    for p in [
        "min_samples_leaf",
        "max_depth",
        "learning_rate",
        "n_estimators",
        "loss",
        "subsample",
        "random_state",
    ]:
        if p in ["max_depth", "min_samples_leaf", "n_estimators", "random_state"]:
            params[p] = list(map(int, options[p].split(",")))
        elif p in [
            "learning_rate",
            "subsample",
            "alpha",
            "max_features",
            "min_samples_split",
        ]:
            params[p] = list(map(float, options[p].split(",")))
        else:
            params[p] = options[p].split(",")
    return params


def writeMap(name, x, y, z):
    result = BytesIO()
    np.savetxt(result, np.column_stack((x, y, z)))
    result.seek(0)
    gs.write_command(
        "r.in.xyz",
        stdin=result.getvalue(),
        input="-",
        output=name,
        method="mean",
        separator=" ",
        overwrite=True,
        quiet=True,
    )


# !!! Check that computation region is set as required

#############################################################################
# Initial settings for automatized model selection
# #############################################################################
options = {
    "min_samples_leaf": "3, 5, 7, 9",  # based on intuition - low value, higher ovefitting 3,5,7
    "max_depth": "13, 15, 17, 19",  # test2 5,7,9
    "max_features": "0.7, 0.4, 0.1",  # proportion of features 0.7,0.5,0.3
    "learning_rate": "0.10, 0.05, 0.01",  # 0.05-0.2, lower later 0.05,0.01,0.005
    "n_estimators": "650, 1000, 1500",  # number of steps
    "subsample": "0.8",  # not change
    "loss": "huber",  # not change
    "random_state": "0",  # to obtain identical results
    "data": "random_points_v_200000",  # input data
    "cores": "44",  # number of cores to use
    "spatial_term": None,
    "output": OUTPUT_PREFIX,  # prefix for output maps
    "crossval": "0.5",  # % test data, rest for training
    "deviance": "/mnt/ecofunc-data/ensemble_model/regression_deviance_{}.pdf".format(
        OUTPUT_PREFIX
    ),
    "featureimportance": "/mnt/ecofunc-data/ensemble_model/regression_featureimportance_{}.pdf".format(
        OUTPUT_PREFIX
    ),
    "partialdependence": "/mnt/ecofunc-data/ensemble_model/regression_partial_dependence_{}.pdf".format(
        OUTPUT_PREFIX
    ),
    "model_pickle": "/mnt/ecofunc-data/ensemble_model/GBRT_model_{}.pickle".format(
        OUTPUT_PREFIX
    ),
}

cores = int(options["cores"])
spatial_term = options["spatial_term"]
output = options["output"]
crossval = float(options["crossval"])
deviance = options["deviance"]
featureimportance = options["featureimportance"]
partialdependence = options["partialdependence"]
model_pickle = options["model_pickle"]
params = setParamDict()

# #############################################################################
# Load data - both y and x maps
# #############################################################################
start_2 = time()

maps = options["data"]
layer = 1

from grass_session import Session

gisdb = "/mnt/ecofunc-data/grass"
location = "ETRS_33N"
mapset = "reg_test"



with Session(gisdb=gisdb, location=location, mapset=mapset):
    import grass.script as gs
    rel_mapsets = []
    vcols = []
    rmaps = []
    for dtype in data_dict["predictor"].values():
        for dkey, ddict in dtype.items():
            vcols.append(dkey)
            rmaps.append(ddict["mapname"] + "@" + ddict["mapset"])
            rel_mapsets.append(ddict["mapset"])
    gs.run_command("g.mapsets", operation="add", mapset=list(set(rel_mapsets)))

    
    for idx, col in enumerate(vcols):
        print(col)
        if not col in gs.vector.vector_columns(maps, layer=layer):
            print("Update attributes for {}".format(rmaps[idx]))
            all_maps = gs.list_strings(type="raster")
            if rmaps[idx] not in all_maps:
                print("Error raster map <{}> not found!".format(rmaps[idx]))
            update_attributes(maps, layer=layer, meta_dict=data_dict, varname=col)


with Session(gisdb=gisdb, location=location, mapset=mapset, create_opts=""):
    # from grass.pygrass import raster as r
    # from grass.pygrass.utils import getenv
    import grass.script as gs

    gs.read_command("g.mapsets", operation="add", mapset="u_zofie.cimburova")
    #
    # Get coordinates and values of each pixel (skip pixels which are NULL in all maps)
    # 0       1      2      3       4
    # coor_x coor_y data_y data_x1 data_x2
    # data = np.genfromtxt(BytesIO(gs.read_command('r.stats',
    #                                             flags='1Ng',
    #                                             input=maps)), delimiter=" ")
    data = np.genfromtxt(
        BytesIO(
            gs.utils.encode(
                gs.read_command("v.db.select", separator=",", map=maps).rstrip()
            )
        ),
        delimiter=",",
        dtype=None,
        names=True,  # , skip_header=1
    )
    # Get matrix with knn to account for autocorrelation
    # gs.read_command("v.distance", flags=["p", "a"], from_=maps, to=maps, to_type="point", dmax=250, dmin=0.1, upload="cat")
    """
    knn= np.genfromtxt(
        BytesIO(
            gs.utils.encode(
                gs.read_command("v.distance", separator="space", map=maps).rstrip()
            )
        ),
        delimiter=" ",
        dtype=None,
        names=True,  # , skip_header=1
    )
    """
    
# Get which columns store which response and predictors
# x...index of columns of x's (if spatial term -> also cols 0, 1 (coordinates)),
# y...index of column of y
# c...index of coordinates
# columns: cat, y, x_1, x_2, ... , x_x, x_y
y = 1  # second column
c = range(len(data[0]) - 2, len(data[0]))  # last two columns
if spatial_term:
    x = range(2, len(data[0]))
else:
    x = range(2, len(data[0]) - 2)

y_names = data.dtype.names[y]
x_names = data.dtype.names[3:]
c_names = data.dtype.names[-2:]

# Create a mask for NoData in either x or y
mask_y = np.isnan(data[y_names])

# Nodata in any of x
for i in x_names:
    if x_names.index(i) == 0:
        mask_x = np.isnan(data[i])
    else:
        mask_x = np.logical_or((np.isnan(data[i])), mask_x)

# Idx of all points with 100% full data, random shuffle
all_y_idx = np.where(np.logical_or(mask_x, mask_y) == False)
all_y = data[all_y_idx]
all_y = shuffle(data[all_y_idx])

# from itertools import combinations
# for cor_comb in combinations(all_y.dtype.names, 2):
#    print(np.corrcoef(all_y[cor_comb[0]], all_y[cor_comb[1]])[0][1])

df = pd.DataFrame(all_y, copy=True)
plt.scatter(df["v_x"], df["v_y"], c=df["value"])

df_corr = df.corr()
sns.heatmap(df_corr, xticklabels=df_corr.columns, yticklabels=df_corr.columns)

df_mean = df.groupby("value").mean()
df_min = df.groupby("value").min()
df_max = df.groupby("value").max()

# Training data - x, y, coordinates - first offset points
# Test data     - x, y, coordinates - remaining points
offset = int(all_y.shape[0] * (1 - crossval))
X_train, y_train, coor_train = (
    all_y[list(x_names)][:offset,].copy(),
    all_y[y_names][:offset,].copy(),
    all_y[list(c_names)][:offset,].copy(),
)
X_test, y_test, coor_test = (
    all_y[list(x_names)][offset:,].copy(),
    all_y[y_names][offset:,].copy(),
    all_y[list(c_names)][offset:,].copy(),
)

print("# training points: {}".format(len(X_train)))
print("# test points: {}".format(len(X_test)))

end_2 = time()
print("Part 2 - loading data - finished in {} seconds.".format((end_2 - start_2)))

# #############################################################################
# Run model selection process if requested
# #############################################################################
start_3 = time()

model_selection = False
model = "RF"
for k in params:
    if len(list(params[k])) > 1:
        model_selection = True
if model_selection:
    gs.message("Running model selection ...")
    if model == "RF":
        clf = ensemble.RandomForestRegressor()
    else:
        clf = ensemble.GradientBoostingRegressor()

    # model selection is performed by Grid Search Crossvalidation
    # scoring function is R2
    X_in = rf.structured_to_unstructured(X_train)
    Y_in = y_train
    gs_cv = GridSearchCV(clf, params, n_jobs=cores).fit(X_in, Y_in)

    # best hyperparameter setting
    best_params = gs_cv.best_params_
    print("Best hyper-parameter set is:")
    print(best_params)

else:
    best_params = {}
    for k in params.keys():
        best_params[k] = params[k][0]
    print("Best hyper-parameter set is:")
    print(best_params)

end_3 = time()
print(
    "Part 3 - model selection - finished in {} seconds.".format((end_3 - start_3))
)

# #############################################################################
# Fit regression model
# #############################################################################
start_4 = time()

# Fit model
gs.message("Fitting regression model ...")
clf = ensemble.GradientBoostingRegressor(**best_params)
X_in = X_train.copy()
X_in = X_in.view((float, len(X_in.dtype.names)))
clf.fit(X_in, Y_in)

models = []
# Identify best overarching climate predictors
for var in data.dtype.names:
    if "bio" in var:
        X_in_var = X_train[var].reshape(-1, 1)
        rf_params = {"n_estimators": 500, "max_features": "auto"}
        params = {"n_estimators": 1000}
        # clf = ensemble.RandomForestClassifier(**rf_params)
        clf = ensemble.RandomForestRegressor(**rf_params)
        # clf = ensemble.GradientBoostingRegressor(**params)
        clf.fit(X_in_var, Y_in)

        # Compute MSE and R2 from test data
        mse = mean_squared_error(y_test, clf.predict(X_test[var].reshape(-1, 1)))
        r2 = r2_score(y_test, clf.predict(X_test[var].reshape(-1, 1)))

        models.append((var, mse, r2))
        print("Var: ", var)
        print("MSE: %.4f" % mse)
        print("R2: %.4f" % r2)

# Save model
with open(model_pickle, "wb") as output_file:
    pickle.dump(clf, output_file)

# # In case we just load already computed model
# with open(r"./GBRT_regression_reports/GBRT_model_200000.pickle", "rb") as input_file:
# clf = pickle.load(input_file)
rf_params = {
    "n_estimators": [10, 100, 500, 1000],
    "max_features": ["auto", "sqrt", "log2"],
    "max_depth": [1, 4, 5, 6, 7, 8],
    "criterion": ["mse"],
}
gs_cv = GridSearchCV(clf, rf_params, n_jobs=cores).fit(X_in, Y_in)
best_params = gs_cv.best_params_
print("Best hyper-parameter set is:")
print(best_params)
clf = ensemble.RandomForestRegressor(**best_params)
clf.fit(X_in, Y_in)

# Compute MSE and R2 from test data
mse = mean_squared_error(y_test, clf.predict(rf.structured_to_unstructured(X_test)))
r2 = r2_score(y_test, clf.predict(rf.structured_to_unstructured(X_test)))

print("MSE: %.4f" % mse)
print("R2: %.4f" % r2)

end_4 = time()
print(
    "Part 4 - fitting regression model - finished in {} seconds.".format(
        (end_4 - start_4)
    )
)

# #############################################################################
# Plot training deviance
# #############################################################################
start_5 = time()

if deviance:
    test_score = np.zeros((best_params["n_estimators"],), dtype=np.float64)

    for i, y_pred in enumerate(clf.staged_predict(X_test)):
        test_score[i] = clf.loss_(y_test, y_pred)

    plt.figure(figsize=(12, 6))
    plt.rcParams.update({"figure.autolayout": True})
    plt.title("Deviance")
    plt.plot(
        np.arange(best_params["n_estimators"]) + 1,
        clf.train_score_,
        "b-",
        label="Training Set Deviance",
    )
    plt.plot(
        np.arange(best_params["n_estimators"]) + 1,
        test_score,
        "r-",
        label="Test Set Deviance",
    )
    plt.legend(loc="upper right")
    plt.xlabel("Boosting Iterations")
    plt.ylabel("Deviance")
    plt.savefig(deviance)

end_5 = time()
print("Part 5: {}".format((end_5 - start_5)))

# #############################################################################
# Plot feature importance
# #############################################################################
start_6 = time()

if featureimportance and model == "GBRT":
    fig = plt.figure(figsize=(12, 12))
    plt.rcParams.update({"figure.autolayout": True})
    feature_importance = clf.feature_importances_

    # make importances relative to max importance
    feature_importance = 100.0 * (feature_importance / feature_importance.max())
    sorted_idx = np.argsort(feature_importance)
    pos = np.arange(sorted_idx.shape[0]) + 0.5
    plt.barh(pos, feature_importance[sorted_idx], align="center")
    plt.yticks(pos, np.array(x_names)[sorted_idx])
    plt.xlabel("Relative Importance")
    plt.title("Variable Importance")
    plt.savefig(featureimportance)

end_6 = time()
print("Part 6: {}".format((end_6 - start_6)))

from sklearn import metrics

ax = plt.gca()
fpr, tpr, thresholds = metrics.roc_curve(
    y_test, clf.predict(rf.structured_to_unstructured(X_test))
)
roc_auc = metrics.auc(fpr, tpr)

    fig, (ax1, ax2, ax3) = plt.subplots(3, sharex=True, sharey=True)

    from matplotlib.backends.backend_pdf import PdfPages

    pp = PdfPages("/mnt/ecofunc-data/hist_plots.pdf")
    for var in X_train.dtype.names:
        fig, ax = plt.subplots()
        plt.hist(
            all_y[var],
            label="all",
            bins=100,
            color="grey",
            range=(np.min(all_y[var]), np.max(all_y[var])),
            histtype="step",
            weights=np.ones(len(all_y[var])) / len(all_y[var]),
        )
        plt.hist(
            all_y[var][all_y["value"] == 1],
            label="lowland",
            bins=100,
            color="red",
            range=(np.min(all_y[var]), np.max(all_y[var])),
            histtype="step",
            weights=np.ones(len(all_y[var][all_y["value"] == 1]))
            / len(all_y[var][all_y["value"] == 1]),
        )
        plt.hist(
            all_y[var][all_y["value"] == 0],
            label="mountain",
            bins=100,
            color="green",
            range=(np.min(all_y[var]), np.max(all_y[var])),
            histtype="step",
            weights=np.ones(len(all_y[var][all_y["value"] == 0]))
            / len(all_y[var][all_y["value"] == 0]),
        )
        ax.set_xlabel(var)
        ax.set_ylabel("Relative pixel count")
        leg = ax.legend(frameon=False, loc="upper center", ncol=3)
        pp.savefig(fig)
    pp.close()

    # plt.gca().yaxis.set_major_formatter(PercentFormatter(1))
    # plt.show()

    plt.plot(fpr, tpr)

    plt.hist(all_y["v_bio10"] * 1 / len(all_y["v_bio10"]))
    plt.hist(all_y["v_bio10"][all_y["value"] == 1])
    plt.hist(all_y["v_bio10"][all_y["value"] == 0])
    plt.hist(all_y["v_bio10"])

    plt.hist2d(all_y["v_bio10"], all_y["value"], (100, 2), cmap=plt.cm.jet)
    plt.hist2d(all_y["v_bio11"], all_y["value"], (100, 2), cmap=plt.cm.jet)
    plt.hist2d(all_y["v_bio18"], all_y["value"], (100, 2), cmap=plt.cm.jet)
    plt.hist2d(all_y["v_srad_sp"], all_y["value"], (100, 2), cmap=plt.cm.jet)
    plt.hist2d(all_y["v_srad_4"], all_y["value"], (100, 2), cmap=plt.cm.jet)
    plt.hist2d(all_y["v_topex_e"], all_y["value"], (100, 2), cmap=plt.cm.jet)
    plt.hist2d(
        X_test[np.array(X_test.dtype.names)[sorted_idx][-1]],
        y_test - clf.predict(rf.structured_to_unstructured(X_test)),
        (100, 100),
        cmap=plt.cm.jet,
    )
    plt.hist2d(
        X_test[np.array(X_test.dtype.names)[sorted_idx][-2]],
        y_test - clf.predict(rf.structured_to_unstructured(X_test)),
        (100, 100),
        cmap=plt.cm.jet,
    )
    plt.hist2d(
        X_test[np.array(X_test.dtype.names)[sorted_idx][-3]],
        y_test - clf.predict(rf.structured_to_unstructured(X_test)),
        (100, 100),
        cmap=plt.cm.jet,
    )
    plt.hist2d(
        X_test[np.array(X_test.dtype.names)[sorted_idx][-4]],
        y_test - clf.predict(rf.structured_to_unstructured(X_test)),
        (100, 100),
        cmap=plt.cm.jet,
    )


# MU = 8
# SIG = 2.2
#
# data = np.random.normal(loc=0, scale=SIG, size=200)
#
#
# @pm4.model
# def pm4_model(data):
#    mu = yield pm4.Normal(loc=0, scale=10, name="mu")
#    sig = yield pm4.Exponential(rate=0.1, name="sig")
#    like = yield pm4.Normal(loc=mu, scale=sig, observed=data, name="like")
#    return like
#
# estimation_model = pm4_model(data)
# trace = pm4.sample(pm4_model(data), num_samples=800)
#
# draws_prior = pm4.sample_prior_predictive(estimation_model)
# draws_posterior = pm4.sample_posterior_predictive(estimation_model, trace, inplace=False)
# combined_trace = trace + draws_posterior + draws_prior
#
# az.plot_ppc(combined_trace)


# Try (hirarchical) model with spatial autocorrelation
# Try adding grazing as weights
df["v_srad_sp_sqrt"] = np.sqrt(df["v_srad_sp"] / 1000.0)
df["v_srad_sp_log"] = np.log(df["v_srad_sp"] / 1000.0)
df["v_sea_open_sqrt"] = np.sqrt(df["v_sea_open"])
df["v_sea_open_log"] = np.log(df["v_sea_open"])

df["weight"] = 1
#df["weight"][df["v_grazing"] != 0] = 1.0 / df["v_grazing"][df["v_grazing"] != 0]
df["weight"][df["value"] != 0] = 0.5

# Generate a small trainingand larger test sample 5% / 95%
# Generate a small trainingand larger test sample 5% / 95%
msk = np.random.rand(len(df)) < 0.5
df_train = df[msk]
df_test = df[~msk]

models_train_pct = {}

msk = np.random.rand(len(df_train)) < 0.1
df_in = df_train[msk]

# Consider weighting up forest pixels as we know that there are false open pixels in the training data???
# Minimize false mountain classification

data_dict, meta_df = get_metadata()

feature_combinations = list(product(*[dkey.keys() for dkey in data_dict["predictor"].values()]))
comb_n = len(feature_combinations)
savepoints = list(range(0, comb_n, 1000))

from datetime import datetime
run_start = datetime.now().strftime("%Y%m%d%H%M%S")
run_dir = "/mnt/ecofunc-data/forest_line_model/run_{}".format(run_start)
plot_dir = os.path.join(run_dir, "plots")
log_dir = os.path.join(run_dir, "logs")

for rdir in [run_dir, plot_dir, log_dir]:
    if not os.path.exists(rdir):
        os.makedirs(rdir)
from sklearn.metrics import f1_score

for pct in [0.1, 0.2, 0.3]: #0.10, 0.25, 0.5, 0.75, 1.0
    mod_comp = pd.DataFrame(columns=[
                        "model_type",
                        "training_n",
                        "autocorr",
                        "weight",
                        "filter",
                        "features",
                        "feature_importance",
                        "Accuracy_F1_average",
                        "Accuracy_F1_stddev",
                        "confusion_0_0",
                        "confusion_0_1",
                        "confusion_1_0",
                        "confusion_1_1",
                        "confusion_error",
                        "confusion_correct",
                        ])

    pct_string = f"{pct:.2f}"
    msk = np.random.rand(len(df_train)) < pct
    df_in = df_train[msk]

    for idx, features in enumerate(feature_combinations):
        features = list(features)
        for autocorr in ["non-spatial", "spatial"]:
            if autocorr == "non-spatial":
                pass
            else:
                features = list(features) + ["v_x", "v_y"]

            for mod_type in ["rf", "gbrt"]:
                if mod_type == "rf":
                    clf = ensemble.RandomForestClassifier(n_jobs=cores)
                else:
                    clf = ensemble.GradientBoostingClassifier()
                for train in ["unfiltered", "filtered"]: #["value", "weight"]]:
                    if train == "unfiltered":
                        df_use = df_in
                    else:
                        df_use = df_in[df_in["v_grazing"]>0]

                    for y_values in ["weighted", "unweighted"]: #["value", "weight"]]:
                        if y_values == "unweighted":
                            fit_params = {"sample_weight": None}
                            score_params = {"sample_weight": None}
                            
                        else:
                            fit_params = {"sample_weight": df_use["weight"]}
                            score_params = {"sample_weight": df_test["weight"]}

                        mod_name = "prediction_{}_{}_{}_{}_{}".format(mod_type, pct_string, train, y_values, "_".join(features))

                        clf.fit(df_use[features], df_use["value"], **fit_params)

                        #cv_scores_f1 = cross_val_score(clf, df_use[features], y=df_use["value"], n_jobs=cores, cv=cores, verbose=0, fit_params=fit_params, scoring="f1")

                        predictions = clf.predict(df_test[features])
                        cv_scores_f1 = f1_score(df_test["value"], predictions, **score_params)
            
                        # Compute MSE and R2 from test data
                        #mse = mean_squared_error(
                        #    np.array(df_test["value"]).reshape(-1, 1), predictions
                        #)
                        #r2 = r2_score(np.array(df_test["value"]).reshape(-1, 1), predictions)
                        #df_test[mod_name] = predictions
                        #df_test["predictions"] = predictions

                        cross_tab = pd.crosstab(df_test["value"], predictions)

                        """models_train_pct[mod_name] = {
                            "R2": r2,
                            "mse": mse,
                            "confustion": pd.crosstab(df_test["value"], df_test[mod_name]), #round(cross_tab[0][1]/sum(cross_tab[0])*100, 2)
                            "feature_importance": clf.feature_importances_,
                            "summary": None,
                        }"""
                        mod_comp.loc[len(mod_comp), :] = [
                            mod_type,
                            pct,
                            autocorr,
                            y_values,
                            train,
                            features,
                            clf.feature_importances_,
                            cv_scores_f1.mean(),
                            cv_scores_f1.std() * 2,
                            #cv_scores.mean(),
                            #cv_scores.std() * 2,
                            round(cross_tab[0][0]/sum(cross_tab[0] + cross_tab[1])*100, 2),
                            round(cross_tab[0][1]/sum(cross_tab[0] + cross_tab[1])*100, 2),
                            round(cross_tab[1][0]/sum(cross_tab[0] + cross_tab[1])*100, 2),
                            round(cross_tab[1][1]/sum(cross_tab[0] + cross_tab[1])*100, 2),
                            round((cross_tab[1][0]+cross_tab[0][1])/sum(cross_tab[0] + cross_tab[1])*100, 2),
                            round((cross_tab[0][0]+cross_tab[1][1])/sum(cross_tab[0] + cross_tab[1])*100, 2),
                            ]
                        print(idx)
                        print("Current model: {}, {}, {}, {}, {}".format(mod_type, pct, train, y_values, "|".join(features)))
                        print("Accuracy: {} (+/- {})".format(cv_scores_f1.mean(), cv_scores_f1.std() * 2))
        
                if idx in savepoints:
                    mod_comp.to_hdf(os.path.join(log_dir, "mod_comb{}.hdf".format(pct_string.replace("-","_"))), key="mod_comp", mode="w")



    
                if mod_type == "gbrt":
                    fig = plt.figure()
                    fig, axs = plot_partial_dependence(
                        clf,
                        df_in[features],
                        features,
                        n_jobs=cores,
                        n_cols=2,
                        feature_names=features,
                        figsize=(len(features), len(features) * 2),
                    )
                    fig.savefig(
                        os.path.join(plot_dir, "partial_dependence_{}.png".format(mod_name))
                    )
    
                fig = plt.figure()
                plt.scatter(df_test["v_x"], df_test["v_y"], c=df_test[mod_name], s=0.01)
                fig.savefig(os.path.join(plot_dir, "predictions_{}.png".format(mod_name)))
    
                fig = plt.figure()
                plt.scatter(
                    df_test["v_x"],
                    df_test["v_y"],
                    c=df_test["value"] - df_test[mod_name],
                    s=0.01,
                )
                fig.savefig(os.path.join(plot_dir, "residuals_{}.png".format(mod_name)))






fig = plt.figure()
plt.scatter(df_test["v_x"][df_test["value"] == 1], df_test["v_y"][df_test["value"] == 1], c=df_test["value"][df_test["value"] == 1], s=0.01)
fig.savefig(os.path.join(plot_dir, "predictions_{}.png".format(mod_name)))










# from matplotlib.backends.backend_pdf import PdfPages

# pp = PdfPages("/mnt/ecofunc-data/hist_plots.pdf")
plot_dir = "/mnt/ecofunc-data/plots"

if not os.path.exists(plot_dir):
    os.makedirs(plot_dir)


def model_factory(df_in):
    with pm.Model() as logistic_model:
        pm.glm.GLM.from_formula(
            "value ~ {} * {} + {}".format("v_bio10", "v_srad_sp_log", "v_bio18"),
            df_in,
            family=pm.glm.families.Binomial(),
        )
        return logistic_model


with model_factory(df_in):
    trace = pm.sample(1000, tune=1000, init="adapt_diag")  # ,
    # return_inferencedata=True) #

with model_factory(df_test):
    ppc = pm.sample_posterior_predictive(trace)  # or whatever

pred_mean = np.apply_along_axis(np.mean, 0, ppc["y"])
pred_median = np.apply_along_axis(np.median, 0, ppc["y"])

df_test["prediction"] = pred_median

fig = plt.figure()
plt.scatter(df_test["v_x"], df_test["v_y"], c=pred_mean, s=0.01)
fig.savefig(os.path.join(plot_dir, "prediction_bayes_mean.png"))

fig = plt.figure()
plt.scatter(df_test["v_x"], df_test["v_y"], c=pred_median, s=0.01)
fig.savefig(os.path.join(plot_dir, "prediction_bayes_median.png"))

fig = plt.figure()
plt.scatter(df_test["v_x"], df_test["v_y"], c=df_test["value"] - pred_median, s=0.01)
fig.savefig(os.path.join(plot_dir, "residuals_bayes.png"))

models_train_pct["bayes_simple"] = {
    "R2": 0,
    "mse": 0,
    "confustion": pd.crosstab(df_test["value"], df_test["prediction"]),
    "feature_importance": [0, 0, 0],
    "summary": pm.summary(trace),
}


def model_factory_simple(df_in):
    with pm.Model() as logistic_model_simple:
        pm.glm.GLM.from_formula(
            "value ~ {}".format(features[0]), df_in, family=pm.glm.families.Binomial()
        )
        return logistic_model_simple


with model_factory_simple(df_in):
    trace_simple = pm.sample(1000, tune=1000, init="adapt_diag")  # ,
    # return_inferencedata=True) #

with model_factory_simple(df_test):
    ppc_simple = pm.sample_posterior_predictive(trace_simple)  # or whatever

pred_mean_simple = np.apply_along_axis(np.mean, 0, ppc_simple["y"])
pred_median_simple = np.apply_along_axis(np.median, 0, ppc_simple["y"])

df_test["prediction_simple"] = pred_median_simple

fig = plt.figure()
plt.scatter(df_test["v_x"], df_test["v_y"], c=pred_mean_simple, s=0.01)
fig.savefig(os.path.join(plot_dir, "prediction_bayes_simple_mean.png"))

fig = plt.figure()
plt.scatter(df_test["v_x"], df_test["v_y"], c=pred_median_simple, s=0.01)
fig.savefig(os.path.join(plot_dir, "prediction_bayes_simple_median.png"))

fig = plt.figure()
plt.scatter(
    df_test["v_x"], df_test["v_y"], c=df_test["value"] - pred_median_simple, s=0.01
)
fig.savefig(os.path.join(plot_dir, "residuals_bayes_simple.png"))


models_train_pct["bayes_simple"] = {
    "R2": 0,
    "mse": 0,
    "confustion": pd.crosstab(df_test["value"], df_test["prediction_simple"]),
    "feature_importance": [0, 0, 0],
    "summary": pm.summary(trace_simple),
}






#######################################################
#
# clf_gbrt = ensemble.GradientBoostingClassifier()
#
# clf_gbrt.fit(
#    df_in[["v_bio10", "v_srad_sp_log", "v_bio18"]],
#    np.array(df_in["value"]).reshape(-1, 1),
# )
#
# gbrt_predictions = clf_gbrt.predict(df_test[["v_bio10", "v_srad_sp_log", "v_bio18"]])
#
## Compute MSE and R2 from test data
# mse = mean_squared_error(np.array(df_test["value"]).reshape(-1, 1), rf_predictions)
# r2 = r2_score(np.array(df_test["value"]).reshape(-1, 1), rf_predictions)
#
# df_test["prediction_gbrt"] = gbrt_predictions
#
# pd.crosstab(df_test["value"], df_test["prediction_gbrt"])
#
# ppc_simple = pm.sample_posterior_predictive(
#    trace_simple, model=logistic_model_simple, keep_size=True
# )
# ppc = pm.sample_posterior_predictive(trace, model=logistic_model_simple, keep_size=True)
# ppc_simple = pm.sample_posterior_predictive(
#    trace_simple, model=logistic_model_simple, keep_size=True
# )
#
# az.compare({"complex": trace, "simple": trace_simple})
#
# az.concat(trace_simple, az.from_dict(posterior_predictive=ppc_simple), inplace=True)
# az.plot_ppc(trace_simple)
# az.plot_trace(trace_simple)
# az.plot_posterior(trace_simple, "v_bio10")
# az.plot_joint(trace_simple)
#
# az.plot_joint(trace, var_names=["v_bio10", "v_bio18"])
# az.plot_joint(trace, var_names=["v_bio10", "v_srad_sp_sqrt"])
# az.plot_joint(trace, var_names=["v_bio10", "v_bio10:v_srad_sp_sqrt"])
#
# pm.compare(trace, trace_simple)
#
#
# save_model("/mnt/ecofunc-data/", "mod_test_simple", trace, logistic_model_simple)
#
#
# pm.summary(trace)
# pm.traceplot(mod_data["trace"][200:])
#
# save_model("/mnt/ecofunc-data/", "mod_test", trace, logistic_model)
# mod_data = load_model("/mnt/ecofunc-data/", "mod_test")
# pm.summary(mod_data["trace"])
# ppc = pm.sample_posterior_predictive(
#    mod_data["trace"], model=mod_data["model"], keep_size=True
# )
#
# import arviz as az
#
# az_inference = az.convert_to_inference_data(mod_data["trace"])
# az.concat(az_inference, az.from_dict(posterior_predictive=ppc), inplace=True)
# az.plot_ppc(az_inference)
#
# pm.summary(trace)
#
# pm.traceplot(mod_data["trace"][200:])
# pm.summary(trace)
#
#
# from sklearn.linear_model import LogisticRegression
# from sklearn.preprocessing import StandardScaler
#
## Standarize features
# scaler = StandardScaler()
## X_std = scaler.fit_transform(rf.structured_to_unstructured(X_train['v_bio10']))
# X_in = rf.structured_to_unstructured(X_train["v_bio10"])
# X_in = X_train["v_bio10"].reshape(-1, 1)
## X_in["v_srad_sp"] = X_in["v_srad_sp"] / 1000.0
#
# X_std = scaler.fit_transform(X_in)
#
## Create logistic regression object using sag solver
# clf = LogisticRegression(random_state=0, solver="sag")
#
## Train model
# clf = clf.fit(X_std, y_train)
#
# from scipy.special import expit
#
# X = X_std
# y = y_train
## and plot the result
# plt.figure(1, figsize=(4, 3))
# plt.clf()
# plt.scatter(X.ravel(), y, color="black", zorder=20)
# X_test = X_std
#
# loss = expit(X_test * clf.coef_ + clf.intercept_).ravel()
# plt.plot(X_test, loss, color="red", linewidth=3)
