param nameseed string = 'costdemo'
param location string =  resourceGroup().location


@allowed(['Manifest', 'Helm'])
@description('Helm allows a more configurable installatrion, Manifest uses all the default values from the OpenCost repo')
param openCostInstallMethod string = 'Helm'

@allowed(['InCluster', 'AzureMonitor', 'ExternalEndpoint'])
param prometheusType string = 'InCluster'

@description('For the Helm chart, enable Ingress')
param openCostIngressEnabled bool = true

var ingressClassName='nginx'
var prometheusNamespace = 'prometheus'
var opencostHelmVersion = '1.14.0'

//---------Kubernetes Construction---------
module aksconst 'aks-construction/bicep/main.bicep' = {
  name: 'aksconstruction'
  params: {
    location : location
    resourceName: nameseed
    enable_aad: true
    enableAzureRBAC : true
    registries_sku: ''
    omsagent: true
    retentionInDays: 30
    agentCount: 2
    JustUseSystemPool: false
  }
}

//RBAC for deployment-scripts
var contributor='b24988ac-6180-42a0-ab88-20f7382dd24c'
var rbacClusterAdmin='b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b'
//var rbacWriter='a7ffa36f-339b-4b5c-8bdf-e2c188b2c0eb'

module prometheus 'prometheus.bicep' = {
  name: '${deployment().name}-prometheusmod'
  params: {
    aksName: aksconst.outputs.aksClusterName
    location: location
    prometheusType: prometheusType
    namespace: prometheusType == 'InCluster' ? prometheusNamespace  : ''
  }
}

@description('Installs the quick-start OpenCost manifest from the OpenCost repo')
module opencost 'br/public:deployment-scripts/aks-run-command:2.0.1' = if (openCostInstallMethod == 'Manifest') {
  name: '${deployment().name}-opencost'
  params: {
    aksName: aksconst.outputs.aksClusterName
    location: location
    managedIdentityName: 'id-AksRunCommandProxy-Admin'
    rbacRolesNeeded:[
      contributor
      rbacClusterAdmin
    ]
    commands: [
      'kubectl apply --namespace opencost -f https://raw.githubusercontent.com/opencost/opencost/develop/kubernetes/opencost.yaml'
    ]
  }
  dependsOn: [prometheus]
}

var opencostHelmCommand = 'helm upgrade --install opencost https://github.com/opencost/opencost-helm-chart/releases/download/${opencostHelmVersion}-helm/opencost-${opencostHelmVersion}.tgz --set opencost.ui.ingress.enabled=${toLower(string(openCostIngressEnabled))} --set opencost.ui.ingress.ingressClassName="${ingressClassName}" --set opencost.ui.ingress.hosts[0].host=null --set opencost.ui.ingress.hosts[0].paths[0]="/" --set opencost.prometheus.internal.namespaceName=${prometheusNamespace} --set opencost.prometheus.internal.serviceName=my-prometheus-server --set opencost.exporter.image.tag=latest --set opencost.ui.image.tag=latest --set opencost.exporter.livenessProbe.enabled=false --set opencost.exporter.readinessProbe.enabled=false --set opencost.prometheus.internal.port=80 --set serviceAccount.automountServiceAccountToken=false --set serviceAccount.create=false  --namespace opencost --create-namespace'
    
module opencostHelm 'br/public:deployment-scripts/aks-run-command:2.0.1' = if (openCostInstallMethod == 'Helm') {
  name: '${deployment().name}-opencostHelm'
  params: {
    aksName: aksconst.outputs.aksClusterName
    location: location
    managedIdentityName: 'id-AksRunCommandProxy-Admin'
    rbacRolesNeeded:[
      contributor
      rbacClusterAdmin
    ]
    commands: [opencostHelmCommand]
  }
  dependsOn: [prometheus]
}

module workloads 'workloads.bicep' = {
  name: '${deployment().name}-workloads'
  params: {
    aksName: aksconst.outputs.aksClusterName
    location: location
  }
}

module ingress 'ingress.bicep' = if(openCostIngressEnabled) {
  name: '${deployment().name}-ingress'
  params: {
    aksName: aksconst.outputs.aksClusterName
    location: location
  }
}

output OpenCostHelmCommand string = opencostHelmCommand
