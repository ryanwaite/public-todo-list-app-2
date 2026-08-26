extension radius

param environment string

@description('Password for the PostgreSQL administrator and application connection.')
@secure()
param postgresPassword string

@description('Password or token for the OCI registry the container image recipe pushes to.')
@secure()
param registryPassword string

@description('Username for the OCI registry the container image recipe pushes to.')
@secure()
param registryUsername string

resource todoListApp 'Radius.Core/applications@2025-08-01-preview' = {
  name: 'public-todo-list-app-2'
  properties: {
    environment: environment
  }
}

resource postgresDb 'Radius.Data/postgreSqlDatabases@2025-08-01-preview' = {
  name: 'postgres'
  properties: {
    environment: environment
    application: todoListApp.id
    codeReference: 'src/persistence/postgres.js#L35'
    database: 'todos'
    username: 'postgres'
    password: postgresPassword
  }
}

resource registryCreds 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'radius-ghcr-registry-creds'
  properties: {
    environment: environment
    application: todoListApp.id
    data: {
      password: {
        value: registryPassword
      }
      username: {
        value: registryUsername
      }
    }
  }
}

resource todoListImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'public-todo-list-app-2-image'
  properties: {
    environment: environment
    application: todoListApp.id
    codeReference: 'Dockerfile#L3'
    tag: '7fd83b8d18c611e1325223d9c7c75dfa33cf79b7'
    build: {
      source: 'git::https://github.com/ryanwaite/public-todo-list-app-2.git?ref=7fd83b8d18c611e1325223d9c7c75dfa33cf79b7'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource todoListContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'public-todo-list-app-2'
  properties: {
    environment: environment
    application: todoListApp.id
    codeReference: 'Dockerfile#L7'
    containers: {
      todoList: {
        image: todoListImage.properties.imageReference
        env: {
          POSTGRES_DB: {
            value: 'todos'
          }
          POSTGRES_HOST: {
            value: postgresDb.properties.host
          }
          POSTGRES_PASSWORD: {
            value: postgresPassword
          }
          POSTGRES_USER: {
            value: 'postgres'
          }
        }
        ports: {
          web: {
            containerPort: 3000
          }
        }
      }
    }
    connections: {
      postgresdb: {
        source: postgresDb.id
      }
    }
  }
}
