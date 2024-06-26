# Powershell script file. Run this file to deploy DYNAMOS components

# Define path to the core charts directory
$chartsPath = "C:\Users\cpoet\IdeaProjects\EnergyEfficiency_DYNAMOS\charts"

# Deploy orchestrator layer
$orchestratorPath = "$chartsPath\orchestrator"
$orchestratorValues = "$orchestratorPath\values.yaml"
helm upgrade -i -f "$orchestratorValues" orchestrator $orchestratorPath

# Deploy agents layer
$agentsPath = "$chartsPath\agents"
$agentsValues = "$agentsPath\values.yaml"
helm upgrade -i -f "$agentsValues" agents $agentsPath

# Deploy third-party layer
$thirdPartyPath = "$chartsPath\thirdparty"
$thirdPartyValues = "$thirdPartyPath\values.yaml"
helm upgrade -i -f "$thirdPartyValues" thirdparty $thirdPartyPath
