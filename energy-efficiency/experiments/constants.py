# Prometheus 
PROMETHEUS_URL = "http://localhost:9090"
PROM_CONTAINERS = "{container_name=~\"system_processes|uva|vu|surf|sql.*|policy.*|orchestrator|sidecar|rabbitmq|api-gateway\"}"
PROM_KEPLER_ENERGY_METRIC = "kepler_container_joules_total"
PROM_KEPLER_CONTAINER_LABEL = "container_name"
PROM_ENERGY_QUERY_TOTAL = f"sum({PROM_KEPLER_ENERGY_METRIC}{PROM_CONTAINERS}) by ({PROM_KEPLER_CONTAINER_LABEL})"
PROM_ENERGY_QUERY_RANGE = f"sum(increase({PROM_KEPLER_ENERGY_METRIC}{PROM_CONTAINERS}[2m])) by ({PROM_KEPLER_CONTAINER_LABEL})"

# Experiment configurations
NUM_EXP_ACTIONS = 7  # Number of actions per experiment
IDLE_PERIOD = 120  # Idle period in seconds
ACTIVE_PERIOD = 120  # Active period in seconds

# DYNAMOS requests
REQUEST_URLS = {
    "uva": "http://uva.uva.svc.cluster.local:80/agent/v1/sqlDataRequest/uva",
    "surf": "http://surf.surf.svc.cluster.local:80/agent/v1/sqlDataRequest/surf"
}
HEADERS = {
    "Content-Type": "application/json",
    # Access token required for data requests in DYNAMOS
    "Authorization": "bearer 1234"
}
INITIAL_REQUEST_BODY = {
    "type": "sqlDataRequest",
    "query": "SELECT DISTINCT p.Unieknr, p.Geslacht, p.Gebdat, s.Aanst_22, s.Functcat, s.Salschal as Salary FROM Personen p JOIN Aanstellingen s ON p.Unieknr = s.Unieknr LIMIT 30000",
    "algorithm": "",
    "options": {"graph": False, "aggregate": False},
    "user": {"id": "12324", "userName": "jorrit.stutterheim@cloudnation.nl"},
    "requestMetadata": {"jobId": "-82dd3244"}
}
JOB_ID_PREFIX = "jorrit-stutterheim-"
