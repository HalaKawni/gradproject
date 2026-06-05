const express = require('express');
const app = express();

app.use(express.json({ limit: '50mb' }));
const cors = require('cors');
app.use(cors());

const userRouter      = require('./routers/user.router');
const gameRouter      = require('./routers/game.router');
const aiRouter        = require('./routers/ai.router');
const courseRouter    = require('./routers/course.router');
const classroomRouter = require('./routers/classroom.router');

app.use('/api/user',      userRouter);
app.use('/api/game',      gameRouter);
app.use('/api/ai',        aiRouter);
app.use('/api/course',    courseRouter);
app.use('/api/classroom', classroomRouter);

module.exports = app;