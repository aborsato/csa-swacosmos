
@description('Cosmos DB account name')
param namePrefix string = toLower(uniqueString(resourceGroup().id))

@description('Location is taken from Resource Group.')
param location string = resourceGroup().location
param cosmosLocation string = 'westus3'

@secure()
param repositoryToken string
param repositoryUrl string
param branch string = 'main'
param appLocation string = '/public'
param apiLocation string = 'api'
@secure()
param azureClientId string
@secure()
param azureClientSecret string

@description('Specifies the MongoDB server version to use.')
@allowed([
  '3.2'
  '3.6'
  '4.0'
])
param serverVersion string = '4.0'

@description('The name for the Mongo DB database')
param databaseName string = 'main'

var accountName = '${namePrefix}-cosmosdb'
var staticSiteName = '${namePrefix}-swa'
var locations = [
  {
    locationName: cosmosLocation
    failoverPriority: 0
    isZoneRedundant: false
  }
]

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

resource staticSite 'Microsoft.Web/staticSites@2021-03-01' = {
  name: staticSiteName
  location: location
  properties: {
    repositoryUrl: repositoryUrl
    branch: branch
    repositoryToken: repositoryToken
    buildProperties: {
      appLocation: appLocation
      apiLocation: apiLocation
    }
  }
  sku: {
    tier: 'Standard'
    name: 'Standard'
  }

  resource staticSiteSettings 'config@2021-03-01' = {
    name: 'appsettings'
    properties: {
      'CONNECTION_STRING': first(cosmosAccount.listConnectionStrings().connectionStrings).connectionString
      'AZURE_CLIENT_ID': azureClientId
      'AZURE_CLIENT_SECRET': azureClientSecret
    }
  }
}
