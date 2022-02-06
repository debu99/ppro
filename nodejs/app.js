
require('dotenv-defaults').config()

const express = require('express')
const app = express()

const host = process.env.HOST || '0.0.0.0';
const port = process.env.PORT || 3000
 
const initializeDatabases = require('./dbs')
const routes = require('./routes')

initializeDatabases().then(dbs => {
  routes(app, dbs).listen(port, host, () => console.log(`Listening on ${host}:${port}`))
}).catch(err => {
  console.error('Failed to make database connections!')
  console.error(err)
  process.exit(1)
})




