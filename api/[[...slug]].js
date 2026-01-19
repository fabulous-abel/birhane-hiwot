import app from "../backend/app.js";

export const config = {
  runtime: "nodejs"
};

const handler = (req, res) => app(req, res);

export default handler;
