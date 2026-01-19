# Backend API

Express API that connects to MongoDB Atlas and exports an offline posts pack.

## Setup

1. Copy `.env.example` to `.env` and fill in `MONGODB_URI`.
2. Install dependencies and run:
   - `npm install`
   - `npm run dev`

# Vercel deployment

The Express app is also mounted through `api/[[...slug]].js`, so a Vercel deployment can serve every `/api/*` route without an extra server process. When running locally, continue to use `npm run dev` (the Express server is still served by `server.js`).

## Endpoints

- `GET /health`
- `GET /api/posts`
- `GET /api/posts/:id`
- `POST /api/posts`
- `PUT /api/posts/:id`
- `DELETE /api/posts/:id`
- `GET /api/posts/pack`

Legacy aliases (same behavior):
- `/api/lyrics`
- `/api/lyrics/:id`
- `/api/lyrics/pack`
