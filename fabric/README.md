# FABRIC
For the deployment of DYNAMOS we use FABRIC: https://portal.fabric-testbed.net/

Useful article: https://learn.fabric-testbed.net/knowledge-base/things-to-know-when-using-fabric-for-the-first-time/

Each notebook and file contains documentation that can be used to understand and evolve the code/system.

## FABRIC Notebooks
FABRIC recommends using Jupyter Notebook for interacting with FABRIC, which is where this folder comes into play. This folder contains the notebooks that can be used for DYNAMOS in FABRIC specifically. Managing these notebooks in version control allows for easy management and version histories, and the notebooks can be edited in an editor such as VSC with the corresponding Jupyter extension (https://marketplace.visualstudio.com/items?itemName=ms-toolsai.jupyter). These notebooks can be added in the Jupyter Hub in FABRIC: https://learn.fabric-testbed.net/article-categories/jupyter-hub/.

### Sequence of notebooks
The following steps explain the sequence of execution for the notebooks:
1. Configure and validate the FABRIC environment and project to be used: [configure_and_validate.ipynb](./configure_and_validate.ipynb)
2. Create a slice and configure the network with the nodes to be used: [create_slice.ipynb](./create_slice.ipynb)
3. Confiure and prepare kubernetes cluster: [Configure Kubernetes](./k8s/cluster-setup/k8s_setup.ipynb)
4. DYNAMOS setup in Kubernetes: [Configure DYNAMOS for Kubernetes Specifically](./k8s/dynamos/DYNAMOS_k8s_setup.ipynb)
5. Execute energy experiments in FABRIC with the created setup: [Execute Experiments](./experiments/experiments.ipynb)
TODO: is this all?


## Additional explanation
### Uploading multiple folders to FABRIC Jupyter Hub
Unfortunately, you cannot manually add folders to Jupyter Hub. So, to upload the folder to FABRIC Jupyter Hub, you need to follow these steps:
1. On your local file system, create a zip of only the folder.
2. Upload that zip to Jupyter Hub as a file (and avoid adding that to GitHub, so move it to local Downloads for example).
3. Unzip it by opening a terminal in Jupyter Hub and running: 
```sh
# Unzip the kubespray.zip file to the current destination (-d .), such as:
unzip kubespray.zip -d .
```
4. Delete the zip afterwards from Jupyter Hub.
5. Now you can use this file, and in future updates, you can for example only upload the changed files, such as changing a single file, etc.