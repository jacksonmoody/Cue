var express = require("express");

var router = express.Router();

router.post("/", async function (req, res) {
  var db = req.db;
  var userId = req.body && req.body.userId;
  var viewName = req.body && req.body.viewName;
  var duration = req.body && req.body.duration;
  var timestamp = req.body && req.body.timestamp;
  var variant = req.body && req.body.variant;

  if (!userId || typeof userId !== "string" || !userId.trim()) {
    return res.status(400).json({ error: "userId (string) is required" });
  }

  if (!viewName || typeof viewName !== "string" || !viewName.trim()) {
    return res.status(400).json({ error: "viewName (string) is required" });
  }

  if (duration == null || typeof duration !== "number") {
    return res.status(400).json({ error: "duration (number) is required" });
  }

  var trimmedUserId = userId.trim();

  try {
    var screenTime = db.collection("screenTime");
    var doc = {
      userId: trimmedUserId,
      viewName: viewName.trim(),
      duration: duration,
      timestamp: timestamp ? new Date(timestamp) : new Date(),
      variant: variant || null,
      createdAt: new Date(),
    };

    await screenTime.insertOne(doc);

    return res.status(200).json({ success: true });
  } catch (err) {
    console.error("Failed to insert screen time:", err);
    return res.status(500).json({ error: "Internal server error" });
  }
});

router.get("/:userId", async function (req, res) {
  var db = req.db;
  var userId = req.params.userId;

  if (!userId || typeof userId !== "string" || !userId.trim()) {
    return res.status(400).json({ error: "userId (string) is required" });
  }

  var trimmedUserId = userId.trim();

  try {
    var screenTime = db.collection("screenTime");
    var results = await screenTime
      .aggregate([
        { $match: { userId: trimmedUserId } },
        {
          $group: {
            _id: "$viewName",
            totalDuration: { $sum: "$duration" },
            visitCount: { $sum: 1 },
          },
        },
        { $sort: { totalDuration: -1 } },
        {
          $project: {
            _id: 0,
            viewName: "$_id",
            totalDuration: 1,
            visitCount: 1,
          },
        },
      ])
      .toArray();

    return res.status(200).json(results);
  } catch (err) {
    console.error("Failed to fetch screen time:", err);
    return res.status(500).json({ error: "Internal server error" });
  }
});

module.exports = router;
