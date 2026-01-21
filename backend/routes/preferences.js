var express = require("express");

var router = express.Router();

router.post("/gear2", async function (req, res) {
  var db = req.db;
  var userId = req.body && req.body.userId;
  var gear2Preferences = req.body && req.body.gear2Preferences;

  if (!userId || typeof userId !== "string" || !userId.trim()) {
    return res.status(400).json({ error: "userId (string) is required" });
  }

  if (!gear2Preferences || !Array.isArray(gear2Preferences) || gear2Preferences.length === 0) {
    return res.status(400).json({ error: "gear2Preferences (array) is required" });
  }

  var trimmedUserId = userId.trim();

  try {
    var preferences = db.collection("preferences");
    var updateDoc = {
      $set: {
        gear2: gear2Preferences,
      },
      $setOnInsert: {
        userId: trimmedUserId,
        createdAt: new Date(),
      },
    };
    await preferences.updateOne(
      { userId: trimmedUserId },
      updateDoc,
      { upsert: true }
    );

    res.status(200).json({
      userId: trimmedUserId,
      gear2: gear2Preferences,
    });
  } catch (err) {
    console.error("Error recording preferences", err);
    res.status(500).json({ error: "Failed to record preferences" });
  }
});

router.post("/gear3", async function (req, res) {
  var db = req.db;
  var userId = req.body && req.body.userId;
  var gear3Preferences = req.body && req.body.gear3Preferences;

  if (!userId || typeof userId !== "string" || !userId.trim()) {
    return res.status(400).json({ error: "userId (string) is required" });
  }

  if (!gear3Preferences || !Array.isArray(gear3Preferences) || gear3Preferences.length === 0) {
    return res.status(400).json({ error: "gear3Preferences (array) is required" });
  }

  var trimmedUserId = userId.trim();

  try {
    var preferences = db.collection("preferences");
    var updateDoc = {
      $set: {
        gear3: gear3Preferences,
      },
      $setOnInsert: {
        userId: trimmedUserId,
        createdAt: new Date(),
      },
    };
    await preferences.updateOne(
      { userId: trimmedUserId },
      updateDoc,
      { upsert: true }
    );

    res.status(200).json({
      userId: trimmedUserId,
      gear3: gear3Preferences,
    });
  } catch (err) {
    console.error("Error recording preferences", err);
    res.status(500).json({ error: "Failed to record preferences" });
  }
});

const defaultGear2Preferences = [
  {
    text: "Heart Racing",
    icon: "heart",
  },
  {
    text: "Muscle Tensing",
    icon: "dumbbell",
  },
  {
    text: "Rapid Breathing",
    icon: "lungs",
  },
  {
    text: "Feeling Heavy",
    icon: "scalemass",
  },
  {
    text: "Other",
    icon: "questionmark",
  },
  {
    text: "No Change",
    icon: "circle.slash",
  },
];

const defaultGear3Preferences = [
  {
    text: "Mindful Breaths",
    icon: "apple.meditate",
  },
  {
    text: "Cross Body Taps",
    icon: "hand.tap",
  },
  {
    text: "Visualization",
    icon: "photo",
  },
  {
    text: "Exercise",
    icon: "figure.run.treadmill",
  },
  {
    text: "Time in Nature",
    icon: "tree",
  },
  {
    text: "Talk with Friend(s)",
    icon: "figure.2.arms.open",
  },
];

router.get("/:userId", async function (req, res) {
  var db = req.db;
  var userId = req.params.userId;

  if (!userId || typeof userId !== "string" || !userId.trim()) {
    return res.status(400).json({ error: "userId (string) is required" });
  }

  var trimmedUserId = userId.trim();

  try {
    var preferences = db.collection("preferences");
    var userPreferences = await preferences.findOne({ userId: trimmedUserId });

    if (!userPreferences) {
      return res.json({
        userId: trimmedUserId,
        gear2: defaultGear2Preferences,
        gear3: defaultGear3Preferences,
      });
    }
    var response = {
      userId: userPreferences.userId,
      gear2: userPreferences.gear2 || defaultGear2Preferences,
      gear3: userPreferences.gear3 || defaultGear3Preferences,
    };
    res.json(response);
  } catch (err) {
    console.error("Error fetching preferences", err);
    res.status(500).json({ error: "Failed to fetch preferences" });
  }
});

module.exports = router;