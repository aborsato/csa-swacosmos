// Parameters
// -------------------------------------------------------------------------------

// General parameters
@description('Cosmos DB account name')
param namePrefix string = toLower(uniqueString(resourceGroup().id))

@description('Location is taken from Resource Group.')
param location string = resourceGroup().location

@description('The resource name of the main KeyVault.')
param keyVaultName string

// CosmosDB parameters
@description('The main CosmosDB location.')
param cosmosLocation string = 'westus3'

@description('Specifies the MongoDB server version to use.')
@allowed([
  '3.2'
  '3.6'
  '4.0'
])
param serverVersion string = '4.0'

@description('The name for the Mongo DB database')
param databaseName string = 'main'

// Static Web App parameters
@secure()
@description('The Personal Access Token created in GitHub.')
param repositoryToken string

@description('The GitHub repositoru URL.')
param repositoryUrl string

@description('The deployment Git branch.')
param branch string = 'main'

@description('App location.')
param appLocation string = '/public'

@description('API location.')
param apiLocation string = 'api'


// Variables
// -------------------------------------------------------------------------------

var accountName = '${namePrefix}-cosmosdb'
var staticSiteName = '${namePrefix}-swa'
var locations = [
  {
    locationName: cosmosLocation
    failoverPriority: 0
    isZoneRedundant: false
  }
]


// Resources
// -------------------------------------------------------------------------------

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2021-10-15' = {
  name: accountName
  location: cosmosLocation
  kind: 'MongoDB'
  properties: {
    locations: locations
    databaseAccountOfferType: 'Standard'
    apiProperties: {
      serverVersion: serverVersion
    }
    capabilities: [
      {
        name: 'EnableMongo'
      }
      {
        name: 'DisableRateLimitingResponses'
      }
      {
        name: 'EnableServerless'
      }
    ]
  }
}

resource cosmosAccountDatabase 'Microsoft.DocumentDB/databaseAccounts/mongodbDatabases@2021-10-15' = {
  name: databaseName
  parent: cosmosAccount
  properties: {
    resource: {
      id: databaseName
    }
  }
}

resource mainKeyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  scope: resourceGroup() // the KeyVault is in the same Resource Group
  name: keyVaultName
}

module swa 'swa.bicep' = {
  name: 'swa'
  params: {
    location: location
    staticSiteName: staticSiteName
    repositoryToken: repositoryToken
    repositoryUrl: repositoryUrl
    apiLocation: apiLocation
    appLocation: appLocation
    branch: branch
    azureClientId: mainKeyVault.getSecret('azureClientId')
    azureClientSecret: mainKeyVault.getSecret('azureClientSecret')
    cosmosConnectionString: first(cosmosAccount.listConnectionStrings().connectionStrings).connectionString
  }
}
