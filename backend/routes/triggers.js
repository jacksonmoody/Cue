var express = require("express");

var router = express.Router();

router.post("/", async function (req, res) {
  var db = req.db;
  var userId = req.body && req.body.userId;
  var triggeredAtTime = req.body && req.body.triggeredAtTime;
  var variant = req.body && req.body.variant;
  var heartRate = req.body && req.body.heartRate;
  var baseline = req.body && req.body.baseline;

  if (!userId || typeof userId !== "string" || !userId.trim()) {
    return res.status(400).json({ error: "userId (string) is required" });
  }

  if (!triggeredAtTime) {
    return res
      .status(400)
      .json({ error: "triggeredAtTime is required" });
  }

  var trimmedUserId = userId.trim();

  try {
    var triggers = db.collection("triggers");
    var triggerDoc = {
      userId: trimmedUserId,
      variant: variant || null,
      triggeredAtTime: new Date(triggeredAtTime),
      heartRate: heartRate || null,
      baseline: baseline || null,
      createdAt: new Date(),
    };

    await triggers.insertOne(triggerDoc);

    return res.status(200).json({ success: true });
  } catch (err) {
    console.error("Failed to insert trigger:", err);
    return res.status(500).json({ error: "Internal server error" });
  }
});

module.exports = router;
