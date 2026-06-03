require('dotenv').config();

const express = require('express');
const body_parser = require('body-parser');
const userRouter = require('./routers/user.router');
const builderRoutes = require('./routers/builderRoutes');
const adminRouter = require('./routers/admin.router');
const gameRouter = require('./routers/game.router');
const coursesRouter = require('./routers/courses.router');
const courseRouter = require('./routers/course.router');

const aiRouter = require('./routers/ai.router');

const app = express();
app.use(express.json({ limit: '50mb' }));
const cors = require('cors');
app.use(cors());

app.use('/', userRouter)d
app.use('/api/builder', builderRoutes);
app.use('/api/admin', adminRouter)
app.use('/api/courses', coursesRouter);
app.use('/api/user', userRouter);
app.use('/api/game', gameRouter);
app.use('/api/ai', aiRouter);
app.use('/api/course', courseRouter);

module.exports = app;
