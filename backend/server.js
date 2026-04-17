import app, { ensureCollections } from "./app.js";

const port = process.env.PORT || 4000;

const server = app.listen(port, () => {
  console.log(`API listening on ${port}`);
  ensureCollections().catch((err) => {
    console.error(
      "Initial database connection failed. The API will keep running and retry on the next request."
    );
    console.error(err);
  });
});

server.on("error", (err) => {
  console.error(err);
  process.exit(1);
});
