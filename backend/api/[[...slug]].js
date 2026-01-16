import app from "../app.js";

export const config = {
  runtime: "nodejs"
};

// Keep the original request path so the Express routes that include "/api" stay reachable.
const handler = (req, res) => app(req, res);

export default handler;
