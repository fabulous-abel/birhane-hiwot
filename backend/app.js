import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import bcrypt from "bcryptjs";
import crypto from "crypto";
import tls from "tls";
import { MongoClient, ObjectId } from "mongodb";

// Fix TLS handshake with MongoDB Atlas on Node v24+ (OpenSSL 3.5)
tls.DEFAULT_MIN_VERSION = "TLSv1.2";
tls.DEFAULT_MAX_VERSION = "TLSv1.2";

dotenv.config();
dotenv.config({ path: "backend/.env" });

const app = express();
const uri = process.env.MONGODB_URI;
const DEFAULT_ADMIN_USERNAME = process.env.DEFAULT_ADMIN_USERNAME ?? "Abel";
const DEFAULT_ADMIN_PASSWORD = process.env.DEFAULT_ADMIN_PASSWORD ?? "abeldjfab";
const DEFAULT_ADMIN_ROLE = process.env.DEFAULT_ADMIN_ROLE ?? "super";
const ADMIN_SALT_ROUNDS =
  Number.parseInt(process.env.ADMIN_SALT_ROUNDS ?? "10", 10) || 10;
const ADMIN_TOKEN_SECRET =
  process.env.ADMIN_TOKEN_SECRET ?? "change-this-admin-token-secret";
const ADMIN_TOKEN_TTL_HOURS =
  Number.parseInt(process.env.ADMIN_TOKEN_TTL_HOURS ?? "12", 10) || 12;
const SERVER_SELECTION_TIMEOUT_MS =
  Number.parseInt(
    process.env.MONGODB_SERVER_SELECTION_TIMEOUT_MS ?? "15000",
    10
  ) || 15000;
const JSON_BODY_LIMIT = process.env.JSON_BODY_LIMIT ?? "10mb";
const corsOptions = {
  origin: (origin, callback) => callback(null, true),
  credentials: true,
  optionsSuccessStatus: 200
};

// Defer the MONGODB_URI check to the first request (ensureCollections)
// instead of throwing at module-load time, which crashes Vercel serverless functions.

let client;
let postsCollection;
let notificationsCollection;
let categoriesCollection;
let subcategoriesCollection;
let adminsCollection;
let carouselCollection;
let initPromise;
let collectionsInitialized = false;
let defaultAdminEnsured = false;

function normalizeText(value) {
  return value == null ? "" : value.toString().trim();
}

function normalizeTags(value) {
  if (Array.isArray(value)) {
    return value
      .map((item) => normalizeText(item))
      .filter(Boolean);
  }

  if (typeof value === "string") {
    return value
      .split(",")
      .map((item) => item.trim())
      .filter(Boolean);
  }

  return [];
}

function normalizePostInput(payload = {}) {
  return {
    title: normalizeText(payload.title),
    teacher: normalizeText(payload.teacher),
    category: normalizeText(payload.category),
    subCategory: normalizeText(payload.subCategory),
    link: normalizeText(payload.link),
    body: normalizeText(payload.body),
    language: normalizeText(payload.language),
    tags: normalizeTags(payload.tags)
  };
}

function validatePostInput(post) {
  if (!post.title || !post.body) {
    return "Title and body are required.";
  }

  if (!post.category) {
    return "Category is required.";
  }

  return "";
}

function buildPostUpdate(payload = {}) {
  const update = {};

  if (payload.title !== undefined) update.title = normalizeText(payload.title);
  if (payload.teacher !== undefined) {
    update.teacher = normalizeText(payload.teacher);
  }
  if (payload.category !== undefined) {
    update.category = normalizeText(payload.category);
  }
  if (payload.subCategory !== undefined) {
    update.subCategory = normalizeText(payload.subCategory);
  }
  if (payload.link !== undefined) update.link = normalizeText(payload.link);
  if (payload.body !== undefined) update.body = normalizeText(payload.body);
  if (payload.language !== undefined) {
    update.language = normalizeText(payload.language);
  }
  if (payload.tags !== undefined) update.tags = normalizeTags(payload.tags);

  return update;
}

function validatePostUpdate(update) {
  if ("title" in update && !update.title) {
    return "Title is required.";
  }

  if ("body" in update && !update.body) {
    return "Body is required.";
  }

  if ("category" in update && !update.category) {
    return "Category is required.";
  }

  return "";
}

function toBase64Url(value) {
  return Buffer.from(value)
    .toString("base64")
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
}

function fromBase64Url(value) {
  const normalized = value.replace(/-/g, "+").replace(/_/g, "/");
  const padded = normalized.padEnd(Math.ceil(normalized.length / 4) * 4, "=");
  return Buffer.from(padded, "base64").toString("utf8");
}

function signTokenSegment(value) {
  return toBase64Url(
    crypto.createHmac("sha256", ADMIN_TOKEN_SECRET).update(value).digest()
  );
}

function safeCompare(a, b) {
  const left = Buffer.from(a);
  const right = Buffer.from(b);

  if (left.length !== right.length) {
    return false;
  }

  return crypto.timingSafeEqual(left, right);
}

function sanitizeAdmin(admin) {
  return {
    username: admin.username,
    role: admin.role || DEFAULT_ADMIN_ROLE,
    isSuperAdmin: Boolean(admin.isSuperAdmin),
    createdAt: admin.createdAt ? admin.createdAt.toISOString() : null
  };
}

function createAdminSession(admin) {
  const issuedAt = Date.now();
  const expiresAt = issuedAt + ADMIN_TOKEN_TTL_HOURS * 60 * 60 * 1000;
  const payload = {
    sub: admin.username,
    role: admin.role || DEFAULT_ADMIN_ROLE,
    iat: issuedAt,
    exp: expiresAt
  };
  const encodedPayload = toBase64Url(JSON.stringify(payload));
  const signature = signTokenSegment(encodedPayload);

  return {
    token: `${encodedPayload}.${signature}`,
    expiresAt: new Date(expiresAt).toISOString(),
    admin: sanitizeAdmin(admin)
  };
}

function verifyAdminToken(token) {
  const segments = token.split(".");

  if (segments.length !== 2 || !segments[0] || !segments[1]) {
    throw new Error("Invalid auth token.");
  }

  const [payloadSegment, signature] = segments;
  const expectedSignature = signTokenSegment(payloadSegment);

  if (!safeCompare(signature, expectedSignature)) {
    throw new Error("Invalid auth token.");
  }

  let payload;

  try {
    payload = JSON.parse(fromBase64Url(payloadSegment));
  } catch {
    throw new Error("Invalid auth token.");
  }

  if (!payload?.sub || typeof payload?.exp !== "number") {
    throw new Error("Invalid auth token.");
  }

  if (Date.now() >= payload.exp) {
    throw new Error("Session expired.");
  }

  return payload;
}

function getBearerToken(req) {
  const authorization = req.get("authorization") || "";

  if (!authorization.startsWith("Bearer ")) {
    return "";
  }

  return authorization.slice("Bearer ".length).trim();
}

async function requireAdminAuth(req, res, next) {
  try {
    await ensureCollections();
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Failed to prepare admin auth.";
    return res.status(500).json({ error: message });
  }

  try {
    const token = getBearerToken(req);

    if (!token) {
      return res.status(401).json({ error: "Admin login is required." });
    }

    const payload = verifyAdminToken(token);
    const admin = await adminsCollection.findOne({ username: payload.sub });

    if (!admin) {
      return res.status(401).json({ error: "Admin account no longer exists." });
    }

    req.admin = sanitizeAdmin(admin);
    next();
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Failed to authenticate admin.";
    res.status(401).json({ error: message });
  }
}

async function createPostNotification(insertedCount) {
  try {
    const totalPosts = await postsCollection.countDocuments();
    const prefix =
      insertedCount === 1
        ? "1 new post was published"
        : `${insertedCount} new posts were published`;

    await notificationsCollection.insertOne({
      message: `${prefix} - total posts: ${totalPosts}.`,
      createdAt: new Date()
    });
  } catch (error) {
    console.error("Failed to create post notification:", error);
  }
}

const ensureCollections = async () => {
  if (collectionsInitialized) {
    return;
  }

  if (!initPromise) {
    initPromise = (async () => {
      try {
        if (!uri) {
          throw new Error(
            "MONGODB_URI is required. Set it in your Vercel environment variables."
          );
        }
        if (!client) {
          client = new MongoClient(uri, {
            serverSelectionTimeoutMS: SERVER_SELECTION_TIMEOUT_MS,
            tls: true,
            tlsAllowInvalidCertificates: false,
            minPoolSize: 0,
          });
        }
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
        carouselCollection = db.collection(
          process.env.CAROUSEL_COLLECTION || "carousel"
        );
        collectionsInitialized = true;
      } catch (error) {
        initPromise = undefined;
        collectionsInitialized = false;
        postsCollection = undefined;
        notificationsCollection = undefined;
        categoriesCollection = undefined;
        subcategoriesCollection = undefined;
        adminsCollection = undefined;
        carouselCollection = undefined;
        try {
          await client.close();
        } catch {
          // Ignore cleanup failures and surface the original connection error.
        }
        throw error;
      }
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
      $set: {
        passwordHash,
        role: DEFAULT_ADMIN_ROLE,
        isSuperAdmin: true
      },
      $setOnInsert: {
        username: DEFAULT_ADMIN_USERNAME,
        createdAt: new Date()
      }
    },
    { upsert: true }
  );
  defaultAdminEnsured = true;
};

app.options("*", cors(corsOptions), (_req, res) => res.sendStatus(204));
app.use(cors(corsOptions));
app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*");
  res.header(
    "Access-Control-Allow-Headers",
    "Origin, X-Requested-With, Content-Type, Accept, Authorization"
  );
  res.header("Access-Control-Allow-Methods", "GET,POST,PUT,DELETE,OPTIONS");
  if (req.method === "OPTIONS") {
    return res.sendStatus(204);
  }
  next();
});
app.use(express.json({ limit: JSON_BODY_LIMIT }));

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
    const { title, teacher, category, subCategory, body, language, tags, link } =
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
      link: link?.toString().trim() ?? "",

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
    const { title, teacher, category, subCategory, body, language, tags, link } =
      req.body || {};
    const update = {};
    if (title !== undefined) update.title = title;
    if (teacher !== undefined) update.teacher = teacher;
    if (category !== undefined) update.category = category;
    if (subCategory !== undefined) update.subCategory = subCategory;
    if (link !== undefined) update.link = link?.toString().trim() ?? "";

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

async function listCarouselItems(_req, res) {
  try {
    await ensureCollections();
    const items = await carouselCollection
      .find()
      .sort({ order: 1, updatedAt: -1 })
      .toArray();
    res.json(items);
  } catch (err) {
    res.status(500).json({ error: "Failed to load carousel items." });
  }
}

async function createCarouselItem(req, res) {
  try {
    await ensureCollections();
    const imageUrl = (req.body?.imageUrl ?? "").toString().trim();
    if (!imageUrl) {
      return res.status(400).json({ error: "Image URL is required." });
    }
    const description = (req.body?.description ?? "").toString().trim();
    const now = new Date();
    const orderValue = req.body?.order;
    const order =
      orderValue != null && !Number.isNaN(Number(orderValue))
        ? Number(orderValue)
        : now.getTime();
    const payload = {
      imageUrl,
      description,
      order,
      createdAt: now,
      updatedAt: now
    };
    const result = await carouselCollection.insertOne(payload);
    res.status(201).json({ ...payload, _id: result.insertedId });
  } catch (err) {
    res.status(500).json({ error: "Failed to save carousel item." });
  }
}

async function updateCarouselItem(req, res) {
  try {
    await ensureCollections();
    if (!ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ error: "Invalid carousel item id." });
    }
    const imageUrlRaw = req.body?.imageUrl;
    const descriptionRaw = req.body?.description;
    const orderRaw = req.body?.order;
    const update = {};
    if (imageUrlRaw !== undefined) {
      const trimmed = imageUrlRaw?.toString().trim() ?? "";
      if (!trimmed) {
        return res.status(400).json({ error: "Image URL is required." });
      }
      update.imageUrl = trimmed;
    }
    if (descriptionRaw !== undefined) {
      update.description = descriptionRaw?.toString().trim() ?? "";
    }
    if (orderRaw !== undefined) {
      const parsed = Number(orderRaw);
      if (!Number.isNaN(parsed)) {
        update.order = parsed;
      }
    }
    update.updatedAt = new Date();

    const result = await carouselCollection.findOneAndUpdate(
      { _id: new ObjectId(req.params.id) },
      { $set: update },
      { returnDocument: "after" }
    );

    if (!result.value) return res.status(404).json({ error: "Not found." });
    res.json(result.value);
  } catch (err) {
    res.status(400).json({ error: "Failed to update carousel item." });
  }
}

async function deleteCarouselItem(req, res) {
  try {
    await ensureCollections();
    if (!ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ error: "Invalid carousel item id." });
    }
    const result = await carouselCollection.deleteOne({
      _id: new ObjectId(req.params.id)
    });
    if (result.deletedCount === 0) {
      return res.status(404).json({ error: "Not found." });
    }
    res.json({ ok: true });
  } catch (err) {
    res.status(400).json({ error: "Failed to delete carousel item." });
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

async function listAdmins(_req, res) {
  try {
    await ensureCollections();
    const admins = await adminsCollection
      .find({}, { projection: { username: 1, createdAt: 1 } })
      .sort({ createdAt: -1 })
      .toArray();
    res.json(
      admins.map((admin) => {
        const isDefault = admin.username === DEFAULT_ADMIN_USERNAME;
        return {
          username: admin.username,
          createdAt: admin.createdAt ? admin.createdAt.toISOString() : null,
          isDefault,
          password: isDefault ? DEFAULT_ADMIN_PASSWORD : null
        };
      })
    );
  } catch (err) {
    console.error("listAdmins error", err);
    res.status(500).json({ error: "Failed to load admins." });
  }
}

async function deleteAdmin(req, res) {
  try {
    await ensureCollections();
    const username = req.params.username?.toString().trim();
    if (!username) {
      return res.status(400).json({ error: "Username is required." });
    }
    if (username === DEFAULT_ADMIN_USERNAME) {
      return res
        .status(403)
        .json({ error: "Default admin cannot be deleted." });
    }
    const result = await adminsCollection.deleteOne({ username });
    if (result.deletedCount === 0) {
      return res.status(404).json({ error: "Admin not found." });
    }
    res.json({ ok: true });
  } catch (err) {
    console.error("deleteAdmin error", err);
    res.status(500).json({ error: "Failed to delete admin." });
  }
}

async function createManagedPost(req, res) {
  try {
    await ensureCollections();

    const normalizedPost = normalizePostInput(req.body);
    const validationError = validatePostInput(normalizedPost);

    if (validationError) {
      return res.status(400).json({ error: validationError });
    }

    const now = new Date();
    const post = {
      ...normalizedPost,
      createdAt: now,
      updatedAt: now
    };
    const result = await postsCollection.insertOne(post);

    await createPostNotification(1);
    res.status(201).json({ ...post, _id: result.insertedId });
  } catch (error) {
    console.error("createManagedPost error", error);
    res.status(500).json({ error: "Failed to create post." });
  }
}

async function createBulkPosts(req, res) {
  try {
    await ensureCollections();

    const rawPosts = Array.isArray(req.body?.posts) ? req.body.posts : req.body;

    if (!Array.isArray(rawPosts) || !rawPosts.length) {
      return res
        .status(400)
        .json({ error: "A non-empty posts array is required." });
    }

    const now = new Date();
    const documents = rawPosts.map((rawPost, index) => {
      if (!rawPost || typeof rawPost !== "object" || Array.isArray(rawPost)) {
        throw new Error(`Post ${index + 1} must be an object.`);
      }

      const normalizedPost = normalizePostInput(rawPost);
      const validationError = validatePostInput(normalizedPost);

      if (validationError) {
        throw new Error(`Post ${index + 1}: ${validationError}`);
      }

      return {
        ...normalizedPost,
        createdAt: now,
        updatedAt: now
      };
    });

    const result = await postsCollection.insertMany(documents);

    await createPostNotification(documents.length);
    res.status(201).json({
      insertedCount: documents.length,
      posts: documents.map((post, index) => ({
        ...post,
        _id: result.insertedIds[index]
      }))
    });
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Failed to create posts.";

    if (message.startsWith("Post ") || message.includes("posts array")) {
      return res.status(400).json({ error: message });
    }

    console.error("createBulkPosts error", error);
    res.status(500).json({ error: "Failed to create posts." });
  }
}

async function updateManagedPost(req, res) {
  try {
    await ensureCollections();

    if (!ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ error: "Invalid post id." });
    }

    const update = buildPostUpdate(req.body);
    const validationError = validatePostUpdate(update);

    if (validationError) {
      return res.status(400).json({ error: validationError });
    }

    update.updatedAt = new Date();

    const result = await postsCollection.findOneAndUpdate(
      { _id: new ObjectId(req.params.id) },
      { $set: update },
      { returnDocument: "after" }
    );

    if (!result.value) {
      return res.status(404).json({ error: "Not found." });
    }

    res.json(result.value);
  } catch (error) {
    console.error("updateManagedPost error", error);
    res.status(400).json({ error: "Failed to update post." });
  }
}

async function createAdminAccount(req, res) {
  try {
    await ensureCollections();

    const username = normalizeText(req.body?.username);
    const password = req.body?.password?.toString() ?? "";

    if (!username || !password) {
      return res
        .status(400)
        .json({ error: "Username and password are required." });
    }

    const existing = await adminsCollection.findOne({ username });

    if (existing) {
      return res.status(409).json({ error: "Admin already exists." });
    }

    const passwordHash = await bcrypt.hash(password, ADMIN_SALT_ROUNDS);
    const admin = {
      username,
      passwordHash,
      role: DEFAULT_ADMIN_ROLE,
      isSuperAdmin: false,
      createdAt: new Date()
    };
    const result = await adminsCollection.insertOne(admin);

    res.status(201).json({ ...sanitizeAdmin(admin), _id: result.insertedId });
  } catch (error) {
    console.error("createAdminAccount error", error);
    res.status(500).json({ error: "Failed to create admin." });
  }
}

async function authenticateAdmin(req, res) {
  try {
    await ensureCollections();

    const username = normalizeText(req.body?.username);
    const password = req.body?.password?.toString() ?? "";

    if (!username || !password) {
      return res
        .status(400)
        .json({ error: "Username and password are required." });
    }

    const admin = await adminsCollection.findOne({ username });

    if (!admin) {
      return res.status(401).json({ error: "Invalid username or password." });
    }

    const passwordHash = admin.passwordHash || "";
    const match = await bcrypt.compare(password, passwordHash);

    if (!match) {
      return res.status(401).json({ error: "Invalid username or password." });
    }

    res.json(createAdminSession(admin));
  } catch (error) {
    console.error("authenticateAdmin error", error);
    res.status(500).json({ error: "Failed to authenticate admin." });
  }
}

function getCurrentAdmin(req, res) {
  res.json(req.admin);
}

async function listManagedAdmins(_req, res) {
  try {
    await ensureCollections();

    const admins = await adminsCollection
      .find({}, { projection: { username: 1, createdAt: 1, role: 1, isSuperAdmin: 1 } })
      .sort({ createdAt: -1 })
      .toArray();

    res.json(
      admins.map((admin) => {
        const isDefault = admin.username === DEFAULT_ADMIN_USERNAME;

        return {
          ...sanitizeAdmin(admin),
          isDefault,
          password: isDefault ? DEFAULT_ADMIN_PASSWORD : null
        };
      })
    );
  } catch (error) {
    console.error("listManagedAdmins error", error);
    res.status(500).json({ error: "Failed to load admins." });
  }
}

async function removeAdminAccount(req, res) {
  try {
    await ensureCollections();

    const username = normalizeText(req.params.username);

    if (!username) {
      return res.status(400).json({ error: "Username is required." });
    }

    if (username === DEFAULT_ADMIN_USERNAME) {
      return res
        .status(403)
        .json({ error: "Default admin cannot be deleted." });
    }

    const result = await adminsCollection.deleteOne({ username });

    if (result.deletedCount === 0) {
      return res.status(404).json({ error: "Admin not found." });
    }

    res.json({ ok: true });
  } catch (error) {
    console.error("removeAdminAccount error", error);
    res.status(500).json({ error: "Failed to delete admin." });
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
      link: post.link || "",

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
app.post("/api/posts", requireAdminAuth, createManagedPost);
app.post("/api/posts/bulk", requireAdminAuth, createBulkPosts);
app.put("/api/posts/:id", requireAdminAuth, updateManagedPost);
app.delete("/api/posts", requireAdminAuth, deletePostFromQuery);
app.delete("/api/posts/:id", requireAdminAuth, deletePost);
app.get("/api/posts/pack", exportPostsPack);

app.get("/api/lyrics", listPosts);
app.get("/api/lyrics/:id", getPost);
app.post("/api/lyrics", requireAdminAuth, createManagedPost);
app.post("/api/lyrics/bulk", requireAdminAuth, createBulkPosts);
app.put("/api/lyrics/:id", requireAdminAuth, updateManagedPost);
app.delete("/api/lyrics", requireAdminAuth, deletePostFromQuery);
app.delete("/api/lyrics/:id", requireAdminAuth, deletePost);
app.get("/api/lyrics/pack", exportPostsPack);

app.get("/api/notifications", async (_req, res) => {
  try {
    await ensureCollections();
    const notifications = await notificationsCollection
      .find()
      .sort({ createdAt: -1 })
      .toArray();
    res.json(
      notifications.map((notification) => ({
        _id: notification._id?.toString(),
        message: notification.message,
        createdAt: notification.createdAt
          ? notification.createdAt.toISOString()
          : null
      }))
    );
  } catch (err) {
    res.status(500).json({ error: "Failed to load notifications." });
  }
});

app.post("/api/notifications", requireAdminAuth, async (req, res) => {
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
    res.status(201).json({
      _id: result.insertedId?.toString(),
      message,
      createdAt: notification.createdAt.toISOString()
    });
  } catch (err) {
    res.status(500).json({ error: "Failed to create notification." });
  }
});

app.delete("/api/notifications/:id", requireAdminAuth, async (req, res) => {
  try {
    await ensureCollections();
    const { id } = req.params;
    if (!ObjectId.isValid(id)) {
      return res.status(400).json({ error: "Invalid notification id." });
    }
    const result = await notificationsCollection.deleteOne({
      _id: new ObjectId(id)
    });
    if (result.deletedCount === 0) {
      return res.status(404).json({ error: "Notification not found." });
    }
    res.json({ ok: true });
  } catch (err) {
    console.error("deleteNotification error", err);
    res.status(500).json({ error: "Failed to delete notification." });
  }
});

app.get("/api/carousel", listCarouselItems);
app.post("/api/carousel", requireAdminAuth, createCarouselItem);
app.put("/api/carousel/:id", requireAdminAuth, updateCarouselItem);
app.delete("/api/carousel/:id", requireAdminAuth, deleteCarouselItem);

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

app.post("/api/categories", requireAdminAuth, async (req, res) => {
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

app.delete("/api/categories/:id", requireAdminAuth, async (req, res) => {
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

app.put("/api/categories/:id", requireAdminAuth, async (req, res) => {
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

app.post("/api/subcategories", requireAdminAuth, async (req, res) => {
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

app.put("/api/subcategories/:id", requireAdminAuth, async (req, res) => {
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

app.delete("/api/subcategories/:id", requireAdminAuth, async (req, res) => {
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

app.post("/api/admins", requireAdminAuth, createAdminAccount);
app.post("/api/admins/login", authenticateAdmin);
app.get("/api/admins/me", requireAdminAuth, getCurrentAdmin);
app.get("/api/admins", requireAdminAuth, listManagedAdmins);
app.delete("/api/admins/:username", requireAdminAuth, removeAdminAccount);

export { ensureCollections };
export default app;
