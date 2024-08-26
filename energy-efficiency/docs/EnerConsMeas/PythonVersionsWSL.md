In WSL you can switch python versions using these steps
```sh
sudo apt-get update

# The Deadsnakes PPA (Personal Package Archive) is a commonly used repository that contains more recent Python versions that are not available in the default Ubuntu repositories.
sudo add-apt-repository ppa:deadsnakes/ppa

# Check if you can use Python
apt list | grep python<version>
# e.g.: app list | grep python3.9

# Install Python version
sudo apt install python<version>

# Update version alternatives for Python 3 (this will set the version to priority 1)
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python<version> 1
# e.g.: sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1
# You can add more priorities to this list by giving it a different number

# Update the configuration to set the python version
sudo update-alternatives --config python3
# This might show a selection, here you can select the correct version

# Confirm installation
python3 --version

# It should now automatically select the correct pip version, since it is bound to the python version. You can verify this by running the following command:
pip --version
# For 3.10 it should output something like:
poetoec@LAPTOP-IA1OBTR5:/mnt/c/Users/cpoet/IdeaProjects/EnergyEfficiency_DYNAMOS/energy-efficiency$ pip --version
pip 22.0.2 from /usr/lib/python3/dist-packages/pip (python 3.10)




# In Python 3.9 and lower an error with pip might occur
poetoec@LAPTOP-IA1OBTR5:/mnt/c/Users/cpoet/IdeaProjects/EnergyEfficiency_DYNAMOS/energy-efficiency$ pip list
Traceback (most recent call last):
  File "/usr/bin/pip", line 5, in <module>
    from pip._internal.cli.main import main
  File "/home/poetoec/.local/lib/python3.9/site-packages/pip/_internal/cli/main.py", line 11, in <module>
    from pip._internal.cli.autocompletion import autocomplete
  File "/home/poetoec/.local/lib/python3.9/site-packages/pip/_internal/cli/autocompletion.py", line 10, in <module>
    from pip._internal.cli.main_parser import create_main_parser
  File "/home/poetoec/.local/lib/python3.9/site-packages/pip/_internal/cli/main_parser.py", line 9, in <module>
    from pip._internal.build_env import get_runnable_pip
  File "/home/poetoec/.local/lib/python3.9/site-packages/pip/_internal/build_env.py", line 18, in <module>
    from pip._internal.cli.spinners import open_spinner
  File "/home/poetoec/.local/lib/python3.9/site-packages/pip/_internal/cli/spinners.py", line 9, in <module>
    from pip._internal.utils.logging import get_indentation
  File "/home/poetoec/.local/lib/python3.9/site-packages/pip/_internal/utils/logging.py", line 29, in <module>
    from pip._internal.utils.misc import ensure_dir
  File "/home/poetoec/.local/lib/python3.9/site-packages/pip/_internal/utils/misc.py", line 41, in <module>
    from pip._internal.locations import get_major_minor_version
  File "/home/poetoec/.local/lib/python3.9/site-packages/pip/_internal/locations/__init__.py", line 66, in <module>
    from . import _distutils
  File "/home/poetoec/.local/lib/python3.9/site-packages/pip/_internal/locations/_distutils.py", line 20, in <module>
    from distutils.cmd import Command as DistutilsCommand
ModuleNotFoundError: No module named 'distutils.cmd'

# You can fix this by running the following command
sudo apt install python3.9-distutils
# Verify fix
pip list

# This is the same for other versions, but then for that version, such as python3.8-distutils
```

After adding the configuration for the alternatives, you can change python versions using this command:
```sh
sudo update-alternatives --config python3

# Example output:
poetoec@LAPTOP-IA1OBTR5:/mnt/c/Users/cpoet/IdeaProjects/EnergyEfficiency_DYNAMOS/energy-efficiency$ sudo update-alternatives --config python3
There are 3 choices for the alternative python3 (providing /usr/bin/python3).

  Selection    Path                 Priority   Status
------------------------------------------------------------
  0            /usr/bin/python3.8    3         auto mode
  1            /usr/bin/python3.10   2         manual mode
  2            /usr/bin/python3.8    3         manual mode
* 3            /usr/bin/python3.9    1         manual mode

Press <enter> to keep the current choice[*], or type selection number:
```
Then select the python version you want to use by its selection number.