extension radius

param environment string

@description('Password for the MySQL administrator and application connection.')
@secure()
param mysqlPassword string

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

resource mysqlDb 'Radius.Data/mySqlDatabases@2025-08-01-preview' = {
  name: 'mysql'
  properties: {
    environment: environment
    application: todoListApp.id
    codeReference: 'src/persistence/mysql.js#L31'
    database: 'todos'
    version: '8.0'
    username: 'myadmin'
    password: mysqlPassword
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
          MYSQL_DB: {
            value: 'todos'
          }
          MYSQL_HOST: {
            value: mysqlDb.properties.host
          }
          MYSQL_PASSWORD: {
            value: mysqlPassword
          }
          MYSQL_USER: {
            value: 'myadmin'
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
      mysqldb: {
        source: mysqlDb.id
      }
    }
  }
}
