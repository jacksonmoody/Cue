var express = require("express");
var crypto = require("crypto");

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
    var gear2WithIds = gear2Preferences.map(function (pref) {
      return {
        id: pref.id || crypto.randomUUID(),
        text: pref.text,
        icon: pref.icon,
      };
    });

    var preferences = db.collection("preferences");
    var updateDoc = {
      $set: {
        gear2: gear2WithIds,
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
      gear2: gear2WithIds,
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
    var gear3WithIds = gear3Preferences.map(function (pref) {
      return {
        id: pref.id || crypto.randomUUID(),
        text: pref.text,
        icon: pref.icon,
      };
    });

    var preferences = db.collection("preferences");
    var updateDoc = {
      $set: {
        gear3: gear3WithIds,
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
      gear3: gear3WithIds,
    });
  } catch (err) {
    console.error("Error recording preferences", err);
    res.status(500).json({ error: "Failed to record preferences" });
  }
});

function getDefaultGear2Preferences() {
  return [
    {
      id: crypto.randomUUID(),
      text: "Heart Racing",
      icon: "heart",
    },
    {
      id: crypto.randomUUID(),
      text: "Muscle Tensing",
      icon: "dumbbell",
    },
    {
      id: crypto.randomUUID(),
      text: "Rapid Breathing",
      icon: "lungs",
    },
    {
      id: crypto.randomUUID(),
      text: "Feeling Heavy",
      icon: "scalemass",
    },
    {
      id: crypto.randomUUID(),
      text: "Other",
      icon: "questionmark",
    },
    {
      id: crypto.randomUUID(),
      text: "No Change",
      icon: "circle.slash",
    },
  ];
}

function getDefaultGear3Preferences() {
  return [
    {
      id: crypto.randomUUID(),
      text: "Mindful Breaths",
      icon: "apple.meditate",
    },
    {
      id: crypto.randomUUID(),
      text: "Cross Body Taps",
      icon: "hand.tap",
    },
    {
      id: crypto.randomUUID(),
      text: "Visualization",
      icon: "photo",
    },
    {
      id: crypto.randomUUID(),
      text: "Exercise",
      icon: "figure.run.treadmill",
    },
    {
      id: crypto.randomUUID(),
      text: "Time in Nature",
      icon: "tree",
    },
    {
      id: crypto.randomUUID(),
      text: "Talk with Friend(s)",
      icon: "figure.2.arms.open",
    },
  ];
}

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
        gear2: getDefaultGear2Preferences(),
        gear3: getDefaultGear3Preferences(),
      });
    }
    
    var response = {
      userId: userPreferences.userId,
      gear2: userPreferences.gear2,
      gear3: userPreferences.gear3,
    };
    res.json(response);
  } catch (err) {
    console.error("Error fetching preferences", err);
    res.status(500).json({ error: "Failed to fetch preferences" });
  }
});

module.exports = router;