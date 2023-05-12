param aksName string
param location string = resourceGroup().location
param managedIdentityName string = 'id-AksRunCommandProxy-Admin'

@allowed(['InCluster', 'AzureMonitor', 'ExternalEndpoint'])
param prometheusType string = 'InCluster'

param namespace string = 'my-prometheus'

var contributor='b24988ac-6180-42a0-ab88-20f7382dd24c'
var rbacClusterAdmin='b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b'

module prometheus 'br/public:deployment-scripts/aks-run-command:2.0.1' = if(prometheusType == 'InCluster') {
  name: 'prometheus'
  params: {
    aksName: aksName
    location: location
    managedIdentityName: managedIdentityName
    rbacRolesNeeded:[
      contributor
      rbacClusterAdmin
    ]
    commands: [
      'helm install my-prometheus --repo https://prometheus-community.github.io/helm-charts prometheus --namespace ${namespace} --create-namespace --set pushgateway.enabled=false --set alertmanager.enabled=false -f https://raw.githubusercontent.com/opencost/opencost/develop/kubernetes/prometheus/extraScrapeConfigs.yaml'
    ]
  }
}

