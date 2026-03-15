const app = require('./server/app');
const db = require('./server/config/db')
const port = 3000;
app.listen(port,()=>{
    console.log(`Server Listening on Port http://localhost:${port}`) ;
})