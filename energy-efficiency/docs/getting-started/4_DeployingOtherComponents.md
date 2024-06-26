# Deploying other components
Run the deploy.ps1 (powershell script) file to deploy the components:
```sh
cd <path to deploy.ps1 file>
# e.g. cd .\energy-efficiency\

# Run the file
.\deploy.ps1

# "running scripts is disabled on this system" error:
# 1. Close VSC/ 2. Run VSC as administrator / 3. Open powershell terminal / 4. Run:
Set-ExecutionPolicy RemoteSigned
# 5. Close VSC / 6. Open VSC how you normally do and rerun the script
```
