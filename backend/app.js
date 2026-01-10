var createError = require("http-errors");
var express = require("express");
var path = require("path");
var cookieParser = require("cookie-parser");
var logger = require("morgan");
var MongoClient = require("mongodb").MongoClient;
var variantsRouter = require("./routes/variants");
var sessionsRouter = require("./routes/sessions");
var usersRouter = require("./routes/users");
var gear1Router = require("./routes/gear1");

require("dotenv").config();

var app = express();

var mongoUri = process.env.MONGODB_URI;
var mongoClient;
var mongoDb;
var connectionPromise;

async function connectMongo() {
  if (!mongoUri) {
    console.warn(
      "MONGODB_URI is not set; API routes depending on MongoDB will be unavailable."
    );
    return null;
  }

  if (mongoDb) {
    return mongoDb;
  }

  if (connectionPromise) {
    return connectionPromise;
  }

  connectionPromise = (async function () {
    try {
      mongoClient = new MongoClient(mongoUri);
      await mongoClient.connect();
      mongoDb = mongoClient.db();
      app.locals.db = mongoDb;
      return mongoDb;
    } catch (err) {
      console.error("Failed to connect to MongoDB", err);
      connectionPromise = null;
      throw err;
    }
  })();

  return connectionPromise;
}

connectMongo().catch(function (err) {
  console.error("Initial MongoDB connection attempt failed", err);
});

app.use(logger("dev"));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, "public")));

app.use(async function (req, res, next) {
  try {
    req.db = await connectMongo();
  } catch (err) {
    req.db = null;
  }
  next();
});

app.use("/variant", variantsRouter);
app.use("/sessions", sessionsRouter);
app.use("/users", usersRouter);
app.use("/gear1", gear1Router);

app.use(function (req, res, next) {
  next(createError(404));
});

app.use(function (err, req, res, next) {
  res.locals.message = err.message;
  res.locals.error = req.app.get("env") === "development" ? err : {};
  res.status(err.status || 500);
  res.render("error");
});

module.exports = app;
