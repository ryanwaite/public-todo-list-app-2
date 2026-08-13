extension radius

param environment string

@secure()
param mysqlPassword string

resource publicTodoListApp 'Radius.Core/applications@2025-08-01-preview' = {
  name: 'public-todo-list-app-2'
  properties: {
    environment: environment
  }
}

resource mysqlDb 'Radius.Data/mySqlDatabases@2025-08-01-preview' = {
  name: 'mysql'
  properties: {
    environment: environment
    application: publicTodoListApp.id
    codeReference: 'src/persistence/mysql.js#L31'
    username: 'myadmin'
    password: mysqlPassword
    database: 'todos'
    version: '8.0'
  }
}

resource publicTodoListImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'public-todo-list-app-2-image'
  properties: {
    environment: environment
    application: publicTodoListApp.id
    codeReference: 'Dockerfile#L1'
    build: {
      source: 'git::https://github.com/ryanwaite/public-todo-list-app-2.git?ref=5a6fbf5caf982f1d928fe6c1c32aa74f1e95e063'
      platforms: [
        'linux/amd64'
      ]
    }
  }
}

resource publicTodoListContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'public-todo-list-app-2'
  properties: {
    environment: environment
    application: publicTodoListApp.id
    codeReference: 'Dockerfile#L7'
    containers: {
      publicTodoListApp: {
        image: publicTodoListImage.properties.imageReference
        ports: {
          web: {
            containerPort: 3000
          }
        }
        env: {
          MYSQL_HOST: {
            value: mysqlDb.properties.host
          }
          MYSQL_USER: {
            value: 'myadmin'
          }
          MYSQL_PASSWORD: {
            value: mysqlPassword
          }
          MYSQL_DB: {
            value: 'todos'
          }
        }
      }
    }
  }
}
