import pandas
import os
import numpy
import sys
import matplotlib.pyplot as plt
from sklearn.cluster import DBSCAN
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
from scipy.stats import shapiro
from scipy.stats import ks_2samp
from scipy.stats import mannwhitneyu
from scipy.stats import ttest_ind

port=sys.argv[1]
test=sys.argv[2]
print('port is:', port)
print('test is:', test)
#Test 1 is comparing two distributions (ks 2 sample test)
#Test 2 is finding outliers (dbscan)
#Test 3 is checking if normally distributed (shapiro wilkens test)
#Test 4 is clustering (kmeans)
#Test 5 is comparing two means (mann whitney u test)

path = os.getcwd()
df = pandas.read_csv(path + "/newresults" + port + ".csv", engine='python')
df_times = pandas.read_csv(path+"/program_info.csv", engine='python')
df_outlier = pandas.read_csv(path + "/graphs" + port + "/outlier/port" + port + ".outliers.csv", engine='python')

if port == "2":
    count = 22
else:
    count = 27#to make it stop searching if have found all
problems = {"Binarytrees":"0", "Fannkuchredux":"1", "Fasta":"2",
    "Mandelbrot":"3", "Nbody":"4", "Revcomp":"5",
        "Spectralnorm":"6"}

total = []
totalnames = []
allnames = []
for i, row in df_times.iterrows():
    rows = []
    filename = row['Language'].lower() + "-" + str(row['ID']) + ".problem" + problems[row['Problem']]
    for i2, row2 in df.iterrows():
        if filename in row2['Name']:
            rows.append(row2)
            if len(rows) == count:
                break

    data = []
    names = []
    for r in rows:
        data.append([r['time(ms)'], float('%.3g' % r['Joule(surface)'])])
        names.append(r['Name'])
    total.append(data)
    totalnames.append(filename)
    allnames.append(names)

if test == '3':
    notNormalE = 0
    notNormalT = 0
    for d in total:
        dataE = []
        dataT = []
        for point in range(len(d)):
            if allnames[total.index(d)][point] not in df_outlier.Name.values:
                dataE.append(d[point][1])
                dataT.append(d[point][0])

        dataE.sort()
        dataT.sort()
        statE, pE = shapiro(dataE)
        statT, pT = shapiro(dataT)
        if pE < 0.01:
            #print(pE, statE)
            notNormalE += 1
        if pT < 0.01:
            notNormalT += 1
            #print(filename, stat, p)

    print("notNormal energy:", notNormalE)
    print("notNormal time:", notNormalT)
    print("Total:", len(total))
