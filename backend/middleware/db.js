function requireDb(req, res, next) {
  var db = req.db || (req.app && req.app.locals && req.app.locals.db);
  if (!db) {
    return res.status(503).json({ error: "Database not available" });
  }
  // Ensure req.db is set for route handlers
  req.db = db;
  next();
}

module.exports = requireDb;
