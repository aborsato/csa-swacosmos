
@description('Location is taken from Resource Group.')
param location string = resourceGroup().location

@description('Static Web App name.')
param staticSiteName string

@description('The Personal Access Token created in GitHub.')
@secure()
param repositoryToken string

@description('The GitHub repositoru URL.')
param repositoryUrl string

@description('The deployment Git branch.')
param branch string = 'main'

@description('App location.')
param appLocation string = '/public'

@description('API location.')
param apiLocation string = 'api'

@description('The Azure Active Directory client id used for authentication.')
@secure()
param azureClientId string

@description('The Azure Active Directory client secret used for authentication.')
@secure()
param azureClientSecret string

@description('The CosmosDB connection string.')
@secure()
param cosmosConnectionString string


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
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    tier: 'Standard'
    name: 'Standard'
  }

  resource staticSiteSettings 'config@2021-03-01' = {
    name: 'appsettings'
    properties: {
      'CONNECTION_STRING': cosmosConnectionString
      'AZURE_CLIENT_ID': azureClientId
      'AZURE_CLIENT_SECRET': azureClientSecret
    }
  }
}
