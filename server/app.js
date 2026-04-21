const express = require('express');
const app = express();

app.use(express.json());
const cors = require('cors');
app.use(cors());

const userRouter = require('./routers/user.router');
const gameRouter = require('./routers/game.router');

app.use('/api/user', userRouter);
app.use('/api/game', gameRouter);

module.exports = app;