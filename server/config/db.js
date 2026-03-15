const mongoose = require('mongoose');

const connection = mongoose.createConnection(
  'mongodb://127.0.0.1:27017'
)
.on('open', () => {
  console.log("MongoDb connected");
})
.on('error', (err) => {
  console.error("MongoDb connection error:", err);
});

module.exports = connection;