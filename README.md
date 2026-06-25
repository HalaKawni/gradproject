# Codey — Kids Coding Education Platform

Codey is a full-stack educational platform designed to teach children (ages 6–17) programming and digital literacy through interactive games, structured courses, and a visual game builder. It was built as a graduation project and supports both Arabic and English, with real-time classroom features, an AI teaching assistant, and a parent dashboard.

---

## What It Does

### For Kids (Students)
Children progress through coding courses delivered as playable game levels. Inside each course, learners move through slide-based lessons followed by mini-games that reinforce what they've just read — word searches, fill-in-the-blank, matching games, swipe-to-classify challenges, and multiple-choice quizzes. All of this is generated automatically by an AI from the lesson content, so every course has fresh interactive exercises without manual authoring.

Beyond consuming courses, students can **build their own games** using three different game builders built on top of the Flame game engine:

- **Scratch Builder** — drag-and-drop block coding (inspired by Scratch), where students snap together logic blocks to write programs
- **Front View Builder** — a side-scrolling platformer editor where students design levels and code the character's behavior
- **Top View Builder** — a top-down grid game builder for writing path-finding solutions

Students earn stars and scores on every level, and can see how they rank in their classroom leaderboard.

### For Teachers / Course Authors
Teachers can create and publish their own courses. The lesson editor supports rich text slides with an integrated AI writing assistant (powered by Groq's `llama-3.1-8b-instant` model) that helps write age-appropriate content. Once slides are written, the platform can auto-generate interactive exercises for each lesson with a single API call.

Created games and courses can be submitted for admin verification before appearing in the public catalog.

### For Parents
Parents register separately and can link to their child's account using a unique link code. The parent dashboard shows the child's progress, active course enrollment, and activity history.

### For Admins
A built-in admin panel provides full platform oversight: user management (with the ability to suspend accounts), course and level moderation (approve/reject submissions), and an analytics dashboard showing user counts by role, level publication status, total courses, and top-played courses ranked by engagement.

---

## Goals

The project set out to answer a single question: **can a young learner go from zero knowledge of programming to actually building and publishing a playable game, without leaving a single app?**

The key design goals were:

1. Make coding feel like playing, not studying — every concept is delivered through a game mechanic rather than a text explanation alone.
2. Support Arabic natively alongside English, with full RTL layout switching, so Palestinian and Arab children can learn in their first language.
3. Let teachers generate interactive content with minimal effort using AI, reducing the barrier to creating quality courses.
4. Give parents visibility into what their children are doing without requiring technical knowledge.
5. Provide classrooms with a competitive but safe social layer (leaderboards, weekly challenges) that motivates continued engagement.

---

## Technical Architecture

The project is split into two halves that communicate over a REST API.

### Backend — Node.js / Express / MongoDB

The server is a layered Express 5 application. Routes delegate to controllers, which call service functions that contain all business logic, keeping each layer independently testable. MongoDB is the primary database, accessed via Mongoose.

**Key API domains:**

| Route prefix       | What it handles                                                             |
|--------------------|-----------------------------------------------------------------------------|
| `/api/user`        | Auth (local + Google OAuth), email verification, password reset, profiles  |
| `/api/courses`     | Public course catalog, enrollment, ratings, comments, recommendations      |
| `/api/course`      | Course creation/editing by teachers, lesson management                      |
| `/api/builder`     | Save, load, and publish games created in the visual builder                 |
| `/api/game`        | Per-user game progress: levels, stars, scores                               |
| `/api/classroom`   | Classroom join/leave, leaderboards, activity feeds, weekly challenges       |
| `/api/ai`          | AI-powered generation of quiz questions, word searches, fill-in-blanks, etc.|
| `/api/admin`       | Admin-only CRUD for users, courses, levels, and statistics                  |

Authentication is JWT-based. All protected routes pass through an `auth.middleware.js` that verifies the token; admin-only routes additionally pass through `requireAdmin.js`.

Passwords are hashed with bcrypt before storage. Email verification and password reset use time-limited SHA-256 hashed tokens sent via Nodemailer (Gmail SMTP).

User-generated game levels are validated server-side before being saved, ensuring the level is solvable and meets structural requirements.

### Frontend — Flutter / Dart

The client is a Flutter application targeting Android and iOS (with HTML/web assets used for the embedded game). It is structured by feature:

```
lib/
├── app/               # Entry point, routing (GoRouter)
├── core/              # Models, services, localization, API config
├── features/
│   ├── auth/          # Login, register, email verification, Google Sign-In
│   ├── home/          # Dashboard, course map, world map, level selection
│   ├── builder/       # Scratch, front view, top view, and code game builders
│   ├── classroom/     # Classroom view, leaderboard, setup
│   ├── admin/         # Admin dashboard, user/course/level management
│   └── profile/       # User profile page
├── datagame/          # Data science course mini-games
├── aicourse/          # AI/digital literacy course screens
├── mycourses/         # Teacher course creation and lesson editor
└── parent/            # Parent dashboard and account management
```

The game levels are rendered using the **Flame** game engine, which runs game loops and sprite animations directly in Flutter. The Scratch Builder uses a custom-built block drag-and-drop system with a `CustomPainter`-drawn grid. The code-based game builder uses a forked version of `flutter_code_editor` (bundled under `third_party/`) to provide syntax highlighting and autocomplete for the custom game scripting language.

Localization supports English and Arabic. JSON translation files live under `assets/i18n/`, and the app switches locale and text direction at runtime without restarting.

Google Translate API is used server-side to auto-translate course content when a teacher publishes a new course, so Arabic and English users always see their language.

---

## Tech Stack at a Glance

| Concern               | Technology                                           |
|-----------------------|------------------------------------------------------|
| Mobile client         | Flutter 3, Dart                                      |
| Game engine           | Flame                                                |
| Backend               | Node.js, Express 5                                   |
| Database              | MongoDB, Mongoose                                    |
| Authentication        | JWT, bcryptjs, Google OAuth (via google-auth-library)|
| Email                 | Nodemailer (Gmail SMTP)                              |
| AI features           | Groq API (llama-3.1-8b-instant)                     |
| Translation           | Google Cloud Translation API                         |
| Localization          | English + Arabic, RTL support                        |
| Code editor widget    | Forked flutter_code_editor                           |

---

## What Was Achieved

By the end of the project the platform delivers:

- A complete end-to-end learning flow: a child can enroll in a course, work through AI-enhanced lessons, earn stars on game levels, and see their rank on a classroom leaderboard — all in one app.
- Three distinct visual game builder modes, each targeting a different age group and concept complexity, from drag-and-drop blocks up to writing code in a custom scripting language.
- A teacher authoring tool with an AI writing assistant that generates all interactive exercises automatically from slide text, cutting lesson-creation time dramatically.
- Full bilingual support (Arabic/English) throughout the app, server, and auto-generated content, making the platform usable in Arabic-speaking classrooms.
- A parent-child linking system that gives parents a clear window into their child's activity.
- An admin control panel covering the full moderation and analytics lifecycle of a live platform.

---

