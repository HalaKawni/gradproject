require('dotenv').config();

const express = require('express');
const body_parser = require('body-parser');
const userRouter = require('./routers/user.router');
const cors = require('cors');
const builderRoutes = require('./routers/builderRoutes');
const adminRouter = require('./routers/admin.router');
const gameRouter = require('./routers/game.router');
const coursesRouter = require('./routers/courses.router');

const app = express();

app.use(body_parser.json({ limit: '8mb' }));

app.use(cors());
app.use(express.json({ limit: '8mb' }));





app.use('/',userRouter)
app.use('/api/builder', builderRoutes);
app.use('/api/admin', adminRouter)
app.use('/api/courses', coursesRouter);

app.use('/api/user', userRouter);
app.use('/api/game', gameRouter);

module.exports = app;
