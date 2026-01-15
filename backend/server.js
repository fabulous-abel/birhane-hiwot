import app, { ensureCollections } from "./app.js";

const port = process.env.PORT || 4000;

ensureCollections()
  .then(() => {
    app.listen(port, () => {
      console.log(`API listening on ${port}`);
    });
  })
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
