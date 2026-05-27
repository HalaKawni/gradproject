const express = require('express');
const app = express();

app.use(express.json());
const cors = require('cors');
app.use(cors());

const userRouter = require('./routers/user.router');
const gameRouter = require('./routers/game.router');
const aiRouter   = require('./routers/ai.router');

app.use('/api/user', userRouter);
app.use('/api/game', gameRouter);
app.use('/api/ai',   aiRouter);

module.exports = app;