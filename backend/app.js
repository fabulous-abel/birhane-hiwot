import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import { MongoClient, ObjectId } from "mongodb";

dotenv.config();

const app = express();
const uri = process.env.MONGODB_URI;

if (!uri) {
  throw new Error("MONGODB_URI is required.");
}

const client = new MongoClient(uri);
let postsCollection;
let notificationsCollection;
let categoriesCollection;
let subcategoriesCollection;
let initPromise;
let collectionsInitialized = false;

const ensureCollections = async () => {
  if (collectionsInitialized) {
    return;
  }

  if (!initPromise) {
    initPromise = (async () => {
      await client.connect();
      const dbFromUri = new URL(uri).pathname?.replace("/", "");
      const dbName = process.env.DB_NAME || dbFromUri || "lyrics";
      const db = client.db(dbName);
      postsCollection = db.collection(
        process.env.COLLECTION_NAME || "lyrics"
      );
      notificationsCollection = db.collection(
        process.env.NOTIFICATIONS_COLLECTION || "notifications"
      );
      categoriesCollection = db.collection(
        process.env.CATEGORIES_COLLECTION || "categories"
      );
      subcategoriesCollection = db.collection(
        process.env.SUBCATEGORIES_COLLECTION || "subcategories"
      );
      collectionsInitialized = true;
    })();
  }

  await initPromise;
};

app.use(cors());
app.use(express.json({ limit: "2mb" }));

// Enhanced health check endpoint
app.get("/health", async (req, res) => {
  try {
    await ensureCollections();
    await client.db().admin().ping();

    res.status(200).json({
      status: "healthy",
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      database: "connected",
      version: process.env.npm_package_version || "1.0.0"
    });
  } catch (error) {
    res.status(503).json({
      status: "unhealthy",
      timestamp: new Date().toISOString(),
      error: "Database connection failed",
      message: error.message
    });
  }
});

// Detailed health check endpoint
app.get("/health-details", async (req, res) => {
  try {
    await ensureCollections();
    const dbPing = await client.db().admin().ping();
    const dbStats = await client.db().stats();
    const collections = await client.db().collections();

    res.status(200).json({
      status: "healthy",
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      database: {
        status: "connected",
        name: process.env.DB_NAME || "lyrics",
        collections: collections.length,
        dataSize: dbStats.dataSize,
        storageSize: dbStats.storageSize,
        indexes: dbStats.indexes,
        indexSize: dbStats.indexSize
      },
      server: {
        host: req.get("host"),
        ip: req.ip,
        protocol: req.protocol,
        secure: req.secure
      },
      version: process.env.npm_package_version || "1.0.0",
      environment: process.env.NODE_ENV || "development"
    });
  } catch (error) {
    res.status(503).json({
      status: "unhealthy",
      timestamp: new Date().toISOString(),
      database: {
        status: "disconnected",
        error: error.message
      },
      version: process.env.npm_package_version || "1.0.0"
    });
  }
});

async function listPosts(_req, res) {
  try {
    await ensureCollections();
    const posts = await postsCollection
      .find()
      .sort({ updatedAt: -1 })
      .toArray();
    res.json(posts);
  } catch (err) {
    res.status(500).json({ error: "Failed to load posts." });
  }
}

async function getPost(req, res) {
  try {
    await ensureCollections();
    if (!ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ error: "Invalid post id." });
    }
    const post = await postsCollection.findOne({
      _id: new ObjectId(req.params.id)
    });
    if (!post) return res.status(404).json({ error: "Not found." });
    res.json(post);
  } catch (err) {
    res.status(400).json({ error: "Invalid post id." });
  }
}

async function createPost(req, res) {
  try {
    await ensureCollections();
    const { title, teacher, category, subCategory, body, language, tags } =
      req.body || {};
    if (!title || !body) {
      return res.status(400).json({ error: "Title and body are required." });
    }
    const now = new Date();
    const post = {
      title,
      teacher: teacher || "",
      category: category || "",
      subCategory: subCategory || "",

      body,
      language: language || "",
      tags: Array.isArray(tags) ? tags : [],
      createdAt: now,
      updatedAt: now
    };
    const result = await postsCollection.insertOne(post);
    try {
      const totalPosts = await postsCollection.countDocuments();
      await notificationsCollection.insertOne({
        message: `New post published – total posts: ${totalPosts}.`,
        createdAt: new Date()
      });
    } catch (notificationError) {
      console.error(
        "Failed to create post notification:",
        notificationError
      );
    }
    res.status(201).json({ ...post, _id: result.insertedId });
  } catch (err) {
    res.status(500).json({ error: "Failed to create post." });
  }
}

async function updatePost(req, res) {
  try {
    await ensureCollections();
    if (!ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ error: "Invalid post id." });
    }
    const { title, teacher, category, subCategory, body, language, tags } =
      req.body || {};
    const update = {};
    if (title !== undefined) update.title = title;
    if (teacher !== undefined) update.teacher = teacher;
    if (category !== undefined) update.category = category;
    if (subCategory !== undefined) update.subCategory = subCategory;

    if (body !== undefined) update.body = body;
    if (language !== undefined) update.language = language;
    if (tags !== undefined) update.tags = Array.isArray(tags) ? tags : [];
    update.updatedAt = new Date();

    const result = await postsCollection.findOneAndUpdate(
      { _id: new ObjectId(req.params.id) },
      { $set: update },
      { returnDocument: "after" }
    );

    if (!result.value) return res.status(404).json({ error: "Not found." });
    res.json(result.value);
  } catch (err) {
    res.status(400).json({ error: "Failed to update post." });
  }
}

async function deletePost(req, res) {
  try {
    await ensureCollections();
    if (!ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ error: "Invalid post id." });
    }
    const result = await postsCollection.deleteOne({
      _id: new ObjectId(req.params.id)
    });
    if (result.deletedCount === 0) {
      return res.status(404).json({ error: "Not found." });
    }
    res.json({ ok: true });
  } catch (err) {
    res.status(400).json({ error: "Failed to delete post." });
  }
}

async function exportPostsPack(_req, res) {
  try {
    await ensureCollections();
    const posts = await postsCollection
      .find()
      .sort({ updatedAt: -1 })
      .toArray();
    const items = posts.map((post) => ({
      id: post._id.toString(),
      title: post.title,
      teacher: post.teacher || "",
      category: post.category || "",
      subCategory: post.subCategory || "",

      body: post.body,
      language: post.language || "",
      tags: Array.isArray(post.tags) ? post.tags : [],
      updatedAt: post.updatedAt ? post.updatedAt.toISOString() : ""
    }));
    res.json({
      version: process.env.PACK_VERSION || "1.0.0",
      generatedAt: new Date().toISOString(),
      items
    });
  } catch (err) {
    res.status(500).json({ error: "Failed to export pack." });
  }
}

app.get("/api/posts", listPosts);
app.get("/api/posts/:id", getPost);
app.post("/api/posts", createPost);
app.put("/api/posts/:id", updatePost);
app.delete("/api/posts/:id", deletePost);
app.get("/api/posts/pack", exportPostsPack);

app.get("/api/lyrics", listPosts);
app.get("/api/lyrics/:id", getPost);
app.post("/api/lyrics", createPost);
app.put("/api/lyrics/:id", updatePost);
app.delete("/api/lyrics/:id", deletePost);
app.get("/api/lyrics/pack", exportPostsPack);

app.get("/api/notifications", async (_req, res) => {
  try {
    await ensureCollections();
    const notifications = await notificationsCollection
      .find()
      .sort({ createdAt: -1 })
      .toArray();
    res.json(notifications);
  } catch (err) {
    res.status(500).json({ error: "Failed to load notifications." });
  }
});

app.post("/api/notifications", async (req, res) => {
  try {
    await ensureCollections();
    const { message } = req.body || {};
    if (!message) {
      return res.status(400).json({ error: "Message is required." });
    }
    const notification = {
      message,
      createdAt: new Date()
    };
    const result = await notificationsCollection.insertOne(notification);
    res.status(201).json({ ...notification, _id: result.insertedId });
  } catch (err) {
    res.status(500).json({ error: "Failed to create notification." });
  }
});

app.get("/api/categories", async (_req, res) => {
  try {
    await ensureCollections();
    const categories = await categoriesCollection
      .find()
      .sort({ name: 1 })
      .toArray();
    res.json(categories);
  } catch (err) {
    res.status(500).json({ error: "Failed to load categories." });
  }
});

app.post("/api/categories", async (req, res) => {
  try {
    await ensureCollections();
    const { name } = req.body || {};
    if (!name) {
      return res.status(400).json({ error: "Name is required." });
    }
    const category = {
      name,
      createdAt: new Date()
    };
    const result = await categoriesCollection.insertOne(category);
    res.status(201).json({ ...category, _id: result.insertedId });
  } catch (err) {
    res.status(500).json({ error: "Failed to create category." });
  }
});

app.delete("/api/categories/:id", async (req, res) => {
  try {
    await ensureCollections();
    if (!ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ error: "Invalid category id." });
    }
    const result = await categoriesCollection.deleteOne({
      _id: new ObjectId(req.params.id)
    });
    if (result.deletedCount === 0) {
      return res.status(404).json({ error: "Not found." });
    }
    res.json({ ok: true });
  } catch (err) {
    res.status(400).json({ error: "Failed to delete category." });
  }
});

app.put("/api/categories/:id", async (req, res) => {
  try {
    await ensureCollections();
    if (!ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ error: "Invalid category id." });
    }
    const { name } = req.body || {};
    if (!name) {
      return res.status(400).json({ error: "Name is required." });
    }
    const result = await categoriesCollection.findOneAndUpdate(
      { _id: new ObjectId(req.params.id) },
      { $set: { name } },
      { returnDocument: "after" }
    );
    if (!result.value) {
      return res.status(404).json({ error: "Not found." });
    }
    res.json(result.value);
  } catch (err) {
    res.status(400).json({ error: "Failed to update category." });
  }
});

app.get("/api/subcategories", async (req, res) => {
  try {
    await ensureCollections();
    const filter = {};
    if (req.query.categoryId && ObjectId.isValid(req.query.categoryId)) {
      filter.categoryId = new ObjectId(req.query.categoryId);
    }
    const subcategories = await subcategoriesCollection
      .find(filter)
      .sort({ name: 1 })
      .toArray();
    res.json(subcategories);
  } catch (err) {
    res.status(500).json({ error: "Failed to load subcategories." });
  }
});

app.post("/api/subcategories", async (req, res) => {
  try {
    await ensureCollections();
    const { name, categoryId } = req.body || {};
    if (!name || !categoryId || !ObjectId.isValid(categoryId)) {
      return res
        .status(400)
        .json({ error: "Name and categoryId are required." });
    }
    const subcategory = {
      name,
      categoryId: new ObjectId(categoryId),
      createdAt: new Date()
    };
    const result = await subcategoriesCollection.insertOne(subcategory);
    res.status(201).json({ ...subcategory, _id: result.insertedId });
  } catch (err) {
    res.status(500).json({ error: "Failed to create subcategory." });
  }
});

app.put("/api/subcategories/:id", async (req, res) => {
  try {
    await ensureCollections();
    if (!ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ error: "Invalid subcategory id." });
    }
    const { name, categoryId } = req.body || {};
    if (!name) {
      return res.status(400).json({ error: "Name is required." });
    }
    const update = { name };
    if (categoryId && ObjectId.isValid(categoryId)) {
      update.categoryId = new ObjectId(categoryId);
    }
    const result = await subcategoriesCollection.findOneAndUpdate(
      { _id: new ObjectId(req.params.id) },
      { $set: update },
      { returnDocument: "after" }
    );
    if (!result.value) {
      return res.status(404).json({ error: "Not found." });
    }
    res.json(result.value);
  } catch (err) {
    res.status(400).json({ error: "Failed to update subcategory." });
  }
});

app.delete("/api/subcategories/:id", async (req, res) => {
  try {
    await ensureCollections();
    if (!ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ error: "Invalid subcategory id." });
    }
    const result = await subcategoriesCollection.deleteOne({
      _id: new ObjectId(req.params.id)
    });
    if (result.deletedCount === 0) {
      return res.status(404).json({ error: "Not found." });
    }
    res.json({ ok: true });
  } catch (err) {
    res.status(400).json({ error: "Failed to delete subcategory." });
  }
});

export { ensureCollections };
export default app;
