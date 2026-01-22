var express = require("express");

var router = express.Router();

router.post("/", async function (req, res) {
    var db = req.db;
    var userId = req.body && req.body.userId;
    var reflection = req.body && req.body.reflection;

    if (!userId || typeof userId !== "string" || !userId.trim()) {
        return res.status(400).json({ error: "userId (string) is required" });
    }

    if (!reflection) {
        return res.status(400).json({ error: "reflection (object) is required" });
    }

    var trimmedUserId = userId.trim();

    try {
        var reflections = db.collection("reflections");
        var reflectionDoc = {
            userId: trimmedUserId,
            reflection: reflection,
        };
        await reflections.insertOne(reflectionDoc);
        res.status(200).json({
            reflection: reflectionDoc,
        });
    }
    catch (err) {
        console.error("Error recording reflection", err);
        res.status(500).json({ error: "Failed to record reflection" });
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
        var reflections = db.collection("reflections");
        var userReflections = await reflections
            .find({ userId: trimmedUserId })
            .toArray();
        var reflectionData = userReflections.map(function(doc) {
            return doc.reflection;
        });
        res.json(reflectionData);
    } catch (err) {
        console.error("Error fetching reflections", err);
        res.status(500).json({ error: "Failed to fetch reflections" });
    }
});

module.exports = router;