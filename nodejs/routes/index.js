const tblname = process.env.COL_NAME || 'testcol'

module.exports = function(app, dbs) {
  app.get('/healthz', (req, res) => {
    res.send('200OK')
  })
 
  app.get('/', (req, res) => {
    dbs.db.collection(tblname).find({}).sort({_id:1}).limit(1).project({_id:0, str:1}).toArray((err, docs) => {
      if (err) {
        console.log(err)
        res.error(err)
      } else {
	console.log(docs[0].str)
	res.send(docs[0].str)
      }
    })
  })
 
  return app
}
