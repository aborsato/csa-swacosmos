
@description('Location is taken from Resource Group.')
param location string = resourceGroup().location

param keyVaultName string

@description('The Azure Active Directory client id used for authentication.')
@secure()
param azureClientId string

@description('The Azure Active Directory client secret used for authentication.')
@secure()
param azureClientSecret string


resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyVaultName
  location: location
  properties: {
    enabledForTemplateDeployment: true
    enableRbacAuthorization: true
    tenantId: tenant().tenantId
    accessPolicies: [
    ]
    sku: {
      name: 'standard'
      family: 'A'
    }
  }
}

resource s1 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: keyVault
  name: 'azureClientId'
  properties: {
    value: azureClientId
  }
}

resource s2 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: keyVault
  name: 'azureClientSecret'
  properties: {
    value: azureClientSecret
  }
}
