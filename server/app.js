const express = require('express');
const body_parser = require('body-parser');
const userRouter = require('./routers/user.router');
const cors = require('cors');
const builderRoutes = require('./routers/builderRoutes');
const adminRouter = require('./routers/admin.router');
const gameRouter = require('./routers/game.router');


const app = express();

app.use(body_parser.json());

app.use(cors());
app.use(express.json());





app.use('/',userRouter)
app.use('/api/builder', builderRoutes);
app.use('/api/admin', adminRouter)

app.use('/api/user', userRouter);
app.use('/api/game', gameRouter);

module.exports = app;
