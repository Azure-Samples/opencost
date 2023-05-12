param aksName string
param location string = resourceGroup().location
param managedIdentityName string = 'id-AksRunCommandProxy-Admin'

var contributor='b24988ac-6180-42a0-ab88-20f7382dd24c'
var rbacClusterAdmin='b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b'

module workload1 'br/public:deployment-scripts/aks-run-command:2.0.1' = {
  name: 'InstallIngress'
  params: {
    aksName: aksName
    location: location
    managedIdentityName: managedIdentityName
    rbacRolesNeeded:[
      contributor
      rbacClusterAdmin
    ]
    commands: [
      'helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx; helm upgrade --install nginx-ingress ingress-nginx/ingress-nginx --set controller.publishService.enabled=true --set controller.metrics.enabled=true --namespace ingress-basic --create-namespace'
    ]
  }
}
