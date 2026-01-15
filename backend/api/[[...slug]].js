import app from "../app.js";

export const config = {
  runtime: "nodejs20.x"
};

const handler = (req, res) => {
  const originalUrl = req.url || "";
  req.url = originalUrl.replace(/^\/api/, "") || "/";
  return app(req, res);
};

export default handler;
