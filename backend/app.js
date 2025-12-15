var createError = require("http-errors");
var express = require("express");
var path = require("path");
var cookieParser = require("cookie-parser");
var logger = require("morgan");
var MongoClient = require("mongodb").MongoClient;
var variantsRouter = require("./routes/variants");
require("dotenv").config();

var app = express();

// MongoDB connection (shared across routes)
var mongoUri = process.env.MONGODB_URI;
var mongoClient;
var mongoDb;

async function connectMongo() {
  if (!mongoUri) {
    console.warn(
      "MONGODB_URI is not set; API routes depending on MongoDB will be unavailable."
    );
    return;
  }

  mongoClient = new MongoClient(mongoUri);
  await mongoClient.connect();
  mongoDb = mongoClient.db();
  app.locals.db = mongoDb;
  console.log("Connected to MongoDB");
}

connectMongo().catch(function (err) {
  console.error("Failed to connect to MongoDB", err);
});

app.use(logger("dev"));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, "public")));

// Attach db to request (if connected)
app.use(function (req, res, next) {
  req.db = mongoDb;
  next();
});

app.use("/api/variant", variantsRouter);

// catch 404 and forward to error handler
app.use(function (req, res, next) {
  next(createError(404));
});

// error handler
app.use(function (err, req, res, next) {
  res.locals.message = err.message;
  res.locals.error = req.app.get("env") === "development" ? err : {};
  res.status(err.status || 500);
  res.render("error");
});

module.exports = app;
