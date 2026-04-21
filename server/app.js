const express = require('express');
const app = express();

app.use(express.json());

const userRouter = require('./router/user.router');
const gameRouter = require('./router/game.router');

app.use('/api/user', userRouter);
app.use('/api/game', gameRouter);

module.exports = app;