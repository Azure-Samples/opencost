param aksName string
param location string = resourceGroup().location
param managedIdentityName string = 'id-AksRunCommandProxy-Admin'

var contributor='b24988ac-6180-42a0-ab88-20f7382dd24c'
var rbacClusterAdmin='b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b'

module workload1 'br/public:deployment-scripts/aks-run-command:2.0.1' = {
  name: 'InstallWorkload1'
  params: {
    aksName: aksName
    location: location
    managedIdentityName: managedIdentityName
    rbacRolesNeeded:[
      contributor
      rbacClusterAdmin
    ]
    commands: [
      'kubectl apply --namespace default -f https://raw.githubusercontent.com/Gordonby/Snippets/master/AKS/Azure-Vote-Labelled-ILB-NetPolicy.yaml'
    ]
  }
}
