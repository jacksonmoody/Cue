var express = require("express");

var router = express.Router();

function getDb(req) {
  return req.db || (req.app && req.app.locals && req.app.locals.db);
}

function missingDb(res) {
  return res.status(503).json({ error: "Database not available" });
}

router.post("/", async function (req, res) {
  var db = getDb(req);
  if (!db) {
    return missingDb(res);
  }

  var userId = req.body && req.body.userId;
  var duration = req.body && req.body.duration;
  var timestamp = req.body && req.body.timestamp;

  if (!userId || typeof userId !== "string" || !userId.trim()) {
    return res.status(400).json({ error: "userId (string) is required" });
  }

  if (
    duration === undefined ||
    duration === null ||
    typeof duration !== "number" ||
    duration < 0
  ) {
    return res
      .status(400)
      .json({ error: "duration (number >= 0) is required" });
  }

  var trimmedUserId = userId.trim();

  try {
    var sessions = db.collection("sessions");
    var sessionDoc = {
      userId: trimmedUserId,
      duration: duration,
      timestamp: timestamp ? new Date(timestamp) : new Date(),
      createdAt: new Date(),
    };

    await sessions.insertOne(sessionDoc);

    res.status(201).json({
      userId: trimmedUserId,
      duration: duration,
      timestamp: sessionDoc.timestamp,
      createdAt: sessionDoc.createdAt,
    });
  } catch (err) {
    console.error("Error recording session", err);
    res.status(500).json({ error: "Failed to record session" });
  }
});

router.get("/:userId/count", async function (req, res) {
  var db = getDb(req);
  if (!db) {
    return missingDb(res);
  }

  var userId = req.params.userId;
  if (!userId) {
    return res.status(400).json({ error: "userId is required" });
  }

  try {
    var sessions = db.collection("sessions");
    // 5 hours = 5 * 60 * 60 = 18000 seconds
    var fiveHoursInSeconds = 18000;
    var count = await sessions.countDocuments({
      userId: userId,
      duration: { $gte: fiveHoursInSeconds },
    });

    res.json({ count: count });
  } catch (err) {
    console.error("Error counting sessions", err);
    res.status(500).json({ error: "Failed to count sessions" });
  }
});

router.get("/:userId", async function (req, res) {
  var db = getDb(req);
  if (!db) {
    return missingDb(res);
  }

  var userId = req.params.userId;
  if (!userId) {
    return res.status(400).json({ error: "userId is required" });
  }

  try {
    var sessions = db.collection("sessions");
    var userSessions = await sessions
      .find({ userId: userId })
      .sort({ timestamp: -1 })
      .toArray();

    res.json(userSessions);
  } catch (err) {
    console.error("Error fetching sessions", err);
    res.status(500).json({ error: "Failed to fetch sessions" });
  }
});

module.exports = router;
