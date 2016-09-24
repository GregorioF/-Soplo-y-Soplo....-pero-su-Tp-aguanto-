import csv

data_csv = "rotar.csv"

ts = [ [] for i in range(128)]

with open(data_csv) as csvfile:
  reader = csv.DictReader(csvfile)
  for row in reader:
    rot = int(row['rotar'])
    
    ts[100].append(rot)

data2_csv = "rotarC.csv"

ts2 = [ [] for i in range(128)]

with open(data2_csv) as csvfile:
  reader = csv.DictReader(csvfile)
  for row in reader:
    rot1 = int(row['rotar'])
    
    ts2[30].append(rot1)

data3_csv = "rotarCO2.csv"
ts3 = [ [] for i in range(128)]

    
with open(data3_csv) as csvfile:
  reader = csv.DictReader(csvfile)
  for row in reader:
    rot2 = int(row['rotar'])
    
    ts3[30].append(rot2)

data4_csv = "rotarCO5.csv"
ts4 = [ [] for i in range(128)]

    
with open(data4_csv) as csvfile:
  reader = csv.DictReader(csvfile)
  for row in reader:
    rot5 = int(row['rotar'])
    
    ts4[30].append(rot5)


import matplotlib.pyplot as plt
import numpy as np


rotar = 1000000
for i in range(128):
	for t in ts[i]:
		rotar = min(rotar, t)

rotar2 = 1000000
for i in range(128):
	for t in ts2[i]:
		rotar2 = min(rotar2, t)

rotar3 = 1000000
for i in range(128):
	for t in ts3[i]:
		rotar3 = min(rotar3, t)

rotar4 = 1000000
for i in range(128):
  for t in ts4[i]:
    rotar4 = min(rotar4, t)


y = []
y.append(rotar)
y.append(rotar2)
y.append(rotar3)
y.append(rotar4)


ind = np.arange(4) 
width = .75     

fig, ax = plt.subplots()
rects1 = ax.bar(ind, y, width, color='r')

ax.set_ylabel('Ciclos')
ax.set_title('Diferencias de Rotar ASM llenando de basura la cache')
ax.set_xticks(ind + 0.4)
ax.set_xticklabels(('C','', 'C O2', 'C O5'))
plt.ticklabel_format(style='sci', axis='y', scilimits=(0,0))
rects1[0].set_color('b')
rects1[1].set_color('g')
rects1[2].set_color('r')
rects1[3].set_color('y')
plt.ylim(990000,1000200)

plt.show()

