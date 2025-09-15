#!/bin/bash
DYNAMOS_ROOT="${HOME}/EnergyEfficiencient_FL"
SCRIPTS="${DYNAMOS_ROOT}/energy-efficiency/scripts"

{
# Parse the agents and thirdparties from the CLI arguments
IFS=',' read -r -a agents <<< "$1"
IFS=',' read -r -a thirdparties <<< "$2"

cd ${DYNAMOS_ROOT}

echo "Adding agents..."
echo "Agents: ${agents[@]}"
for agent in "${agents[@]}"
do
    echo "- agent '$agent'"
    ${SCRIPTS}/add_agent.sh $agent > /dev/null
done

echo ""
echo "Adding third parties..."
echo "Thirdparties: ${thirdparties[@]}"
for thirdparty in "${thirdparties[@]}"
do
    echo "- third party '$thirdparty'"
    ${SCRIPTS}/add_thirdparty.sh $thirdparty > /dev/null
done
}