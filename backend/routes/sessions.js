var express = require("express");

var router = express.Router();

var { tryAdvancePhase, EIGHT_HOURS_IN_SECONDS } = require("../utils/advancePhase");

router.post("/", async function (req, res) {
  var db = req.db;
  var userId = req.body && req.body.userId;
  var duration = req.body && req.body.duration;
  var timestamp = req.body && req.body.timestamp;
  var variant = req.body && req.body.variant;

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
      variant: variant || null,
      timestamp: timestamp ? new Date(timestamp) : new Date(),
      createdAt: new Date(),
    };

    await sessions.insertOne(sessionDoc);

    var responseData = {
      userId: trimmedUserId,
      duration: duration,
      timestamp: sessionDoc.timestamp,
      createdAt: sessionDoc.createdAt,
      variantSwitched: false,
    };

    if (variant) {
      var advanceResult = await tryAdvancePhase(db, trimmedUserId, variant);
      responseData.secondsLogged = advanceResult.secondsLogged;
      responseData.variantSwitched = advanceResult.variantSwitched;
      responseData.newVariant = advanceResult.newVariant;
      responseData.newPhase = advanceResult.newPhase;
      responseData.experimentComplete = advanceResult.experimentComplete;
    }

    res.status(201).json(responseData);
  } catch (err) {
    console.error("Error recording session", err);
    res.status(500).json({ error: "Failed to record session" });
  }
});

router.get("/:userId/count", async function (req, res) {
  var db = req.db;
  var userId = req.params.userId;
  if (!userId) {
    return res.status(400).json({ error: "userId is required" });
  }

  try {
    var sessions = db.collection("sessions");
    var assignments = db.collection("assignments");
    var reflections = db.collection("reflections");

    var assignment = await assignments.findOne({ userId: userId });

    if (!assignment) {
      var totalReflections = await reflections.countDocuments({
        userId: userId,
        "reflection.endDate": { $exists: true, $ne: null },
      });
      return res.json({
        currentPhase: 0,
        secondsLogged: 0,
        hoursRequired: EIGHT_HOURS_IN_SECONDS,
        experimentComplete: false,
        reflectionCount: totalReflections,
      });
    }

    var currentPhase = assignment.currentPhase || 0;
    var order = assignment.order || [assignment.variant];
    var currentVariant = order[currentPhase] || assignment.variant;

    var [totalResult, perVariantReflections] = await Promise.all([
      sessions
        .aggregate([
          { $match: { userId: userId, variant: currentVariant } },
          { $group: { _id: null, total: { $sum: "$duration" } } },
        ])
        .toArray(),
      reflections
        .aggregate([
          {
            $match: {
              userId: userId,
              "reflection.endDate": { $exists: true, $ne: null },
              variant: { $in: order },
            },
          },
          { $group: { _id: "$variant", count: { $sum: 1 } } },
        ])
        .toArray(),
    ]);

    var secondsLogged = totalResult.length > 0 ? totalResult[0].total : 0;

    var variantsWithReflections = new Set(
      perVariantReflections.map(function (doc) {
        return doc._id;
      }),
    );
    var reflectionsComplete = order.every(function (v) {
      return variantsWithReflections.has(v);
    });

    var currentVariantReflections = perVariantReflections.find(function (doc) {
      return doc._id === currentVariant;
    });
    var reflectionCount = currentVariantReflections
      ? currentVariantReflections.count
      : 0;

    var experimentComplete = false;
    if (
      currentPhase === 2 &&
      secondsLogged >= EIGHT_HOURS_IN_SECONDS &&
      reflectionsComplete
    ) {
      experimentComplete = true;
    }

    res.json({
      currentPhase: currentPhase,
      secondsLogged: secondsLogged,
      hoursRequired: EIGHT_HOURS_IN_SECONDS,
      experimentComplete: experimentComplete,
      reflectionCount: reflectionCount,
    });
  } catch (err) {
    console.error("Error counting sessions", err);
    res.status(500).json({ error: "Failed to count sessions" });
  }
});

router.get("/:userId", async function (req, res) {
  var db = req.db;
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
