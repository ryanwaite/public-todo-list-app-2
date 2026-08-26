extension radius

param environment string

@secure()
param postgresPassword string

@secure()
param registryPassword string

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
    tag: '19d9b892fe098e0839aeb5ffee5ab8ad'
    build: {
      source: 'git::https://github.com/ryanwaite/public-todo-list-app-2.git?ref=19d9b892fe098e0839aeb5ffee5ab8ad98d3019d'
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
    codeReference: 'Dockerfile#L8'
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
  }
}
