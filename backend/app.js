import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import bcrypt from "bcryptjs";
import { MongoClient, ObjectId } from "mongodb";

dotenv.config();

const app = express();
const uri = process.env.MONGODB_URI;
const DEFAULT_ADMIN_USERNAME = process.env.DEFAULT_ADMIN_USERNAME ?? "Abel";
const DEFAULT_ADMIN_PASSWORD = process.env.DEFAULT_ADMIN_PASSWORD ?? "123";
const ADMIN_SALT_ROUNDS =
  Number.parseInt(process.env.ADMIN_SALT_ROUNDS ?? "10", 10) || 10;
const corsOptions = {
  origin: (origin, callback) => callback(null, true),
  credentials: true,
  optionsSuccessStatus: 200
};

if (!uri) {
  throw new Error("MONGODB_URI is required.");
}

const client = new MongoClient(uri);
let postsCollection;
let notificationsCollection;
let categoriesCollection;
let subcategoriesCollection;
let adminsCollection;
let initPromise;
let collectionsInitialized = false;
let defaultAdminEnsured = false;

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
      adminsCollection = db.collection(
        process.env.ADMINS_COLLECTION || "admins"
      );
      collectionsInitialized = true;
    })();
  }

  await initPromise;
  await ensureDefaultAdmin();
};

const ensureDefaultAdmin = async () => {
  if (defaultAdminEnsured) return;
  if (!adminsCollection) {
    throw new Error("Admins collection is not initialized.");
  }
  const passwordHash = await bcrypt.hash(
    DEFAULT_ADMIN_PASSWORD,
    ADMIN_SALT_ROUNDS
  );
  await adminsCollection.updateOne(
    { username: DEFAULT_ADMIN_USERNAME },
    {
      $setOnInsert: {
        username: DEFAULT_ADMIN_USERNAME,
        passwordHash,
        createdAt: new Date()
      }
    },
    { upsert: true }
  );
  defaultAdminEnsured = true;
};

app.use(cors(corsOptions));
app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*");
  res.header(
    "Access-Control-Allow-Headers",
    "Origin, X-Requested-With, Content-Type, Accept"
  );
  res.header("Access-Control-Allow-Methods", "GET,POST,PUT,DELETE,OPTIONS");
  if (req.method === "OPTIONS") {
    return res.sendStatus(204);
  }
  next();
});
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

async function attemptDeletePostById(id) {
  if (!ObjectId.isValid(id)) {
    return { status: 400, error: "Invalid post id." };
  }
  const result = await postsCollection.deleteOne({
    _id: new ObjectId(id)
  });
  if (result.deletedCount === 0) {
    return { status: 404, error: "Not found." };
  }
  return { status: 200 };
}

async function deletePost(req, res) {
  try {
    await ensureCollections();
    const { status, error } = await attemptDeletePostById(req.params.id);
    if (status !== 200) {
      return res.status(status).json({ error });
    }
    res.json({ ok: true });
  } catch (err) {
    res.status(400).json({ error: "Failed to delete post." });
  }
}

async function deletePostFromQuery(req, res) {
  try {
    await ensureCollections();
    const queryId = Array.isArray(req.query.id) ? req.query.id[0] : req.query.id;
    const candidateId = queryId ?? req.body?.id;
    const id = candidateId?.toString();
    if (!id) {
      return res.status(400).json({ error: "Post id is required." });
    }
    const { status, error } = await attemptDeletePostById(id);
    if (status !== 200) {
      return res.status(status).json({ error });
    }
    res.json({ ok: true });
  } catch (err) {
    res.status(400).json({ error: "Failed to delete post." });
  }
}

async function createAdmin(req, res) {
  try {
    await ensureCollections();
    const { username, password } = req.body || {};
    if (!username || !password) {
      return res
        .status(400)
        .json({ error: "Username and password are required." });
    }
    const normalizedUsername = username.toString().trim();
    if (!normalizedUsername) {
      return res.status(400).json({ error: "Invalid username." });
    }
    const existing = await adminsCollection.findOne({
      username: normalizedUsername
    });
    if (existing) {
      return res.status(409).json({ error: "Admin already exists." });
    }
    const passwordHash = await bcrypt.hash(password.toString(), ADMIN_SALT_ROUNDS);
    const admin = {
      username: normalizedUsername,
      passwordHash,
      createdAt: new Date()
    };
    const result = await adminsCollection.insertOne(admin);
    res.status(201).json({ username: normalizedUsername, _id: result.insertedId });
  } catch (err) {
    console.error("createAdmin error", err);
    res.status(500).json({ error: "Failed to create admin." });
  }
}

async function loginAdmin(req, res) {
  try {
    await ensureCollections();
    const { username, password } = req.body || {};
    if (!username || !password) {
      return res
        .status(400)
        .json({ error: "Username and password are required." });
    }
    const normalizedUsername = username.toString().trim();
    const admin = await adminsCollection.findOne({
      username: normalizedUsername
    });
    if (!admin) {
      return res.status(401).json({ error: "Invalid username or password." });
    }
    const passwordHash = admin.passwordHash || "";
    const match = await bcrypt.compare(password.toString(), passwordHash);
    if (!match) {
      return res.status(401).json({ error: "Invalid username or password." });
    }
    res.json({ username: admin.username });
  } catch (err) {
    console.error("loginAdmin error", err);
    res.status(500).json({ error: "Failed to authenticate admin." });
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
app.delete("/api/posts", deletePostFromQuery);
app.delete("/api/posts/:id", deletePost);
app.get("/api/posts/pack", exportPostsPack);

app.get("/api/lyrics", listPosts);
app.get("/api/lyrics/:id", getPost);
app.post("/api/lyrics", createPost);
app.put("/api/lyrics/:id", updatePost);
app.delete("/api/lyrics", deletePostFromQuery);
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

app.post("/api/admins", createAdmin);
app.post("/api/admins/login", loginAdmin);

export { ensureCollections };
export default app;
