const MongoClient = require('mongodb').MongoClient

const dbuser = process.env.DB_USER || 'root'
const dbpassword = process.env.DB_PASS
const dbhost = process.env.DB_HOST || 'localhost'
const dbport = process.env.DB_PORT || 27017
const dbname = process.env.DB_NAME || 'testdb'

const DB_URI = "mongodb://" + dbuser + ":" + dbpassword + "@" + dbhost + ":" + dbport + "/" + dbname + "?authSource=admin"
//console.log('DB_URI=' + DB_URI)
function connect(url) {
  return MongoClient.connect(url, {
    connectTimeoutMS: 5000,
    serverSelectionTimeoutMS: 5000
  }).then(client => client.db())
}
 
module.exports = async function() {
  let databases = await Promise.all([connect(DB_URI)])
 
  return {
    db: databases[0]
  }
}
