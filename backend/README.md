# Backend API

Express API that connects to MongoDB Atlas and exports an offline posts pack.

## Setup

1. Copy `.env.example` to `.env` and fill in `MONGODB_URI`.
2. Install dependencies and run:
   - `npm install`
   - `npm run dev`

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
