var Anthropic = require("@anthropic-ai/sdk");
var { zodOutputFormat } = require("@anthropic-ai/sdk/helpers/zod");
var z = require("zod");
var express = require("express");

var router = express.Router();

var { tryAdvancePhase } = require("../utils/advancePhase");

async function generateReflectionTitle(gear1Text, gear3Text) {
    var client = new Anthropic({
        apiKey: process.env.ANTHROPIC_API_KEY,
    });

    var schema = z.object({
        title: z.string(),
    });

    var response = await client.messages.parse({
        model: "claude-sonnet-4-6",
        max_tokens: 200,
        temperature: 0,
        system: "You generate succinct titles for emotional reflection sessions.",
        messages: [
            {
                role: "user",
                content: `A user just completed a short reflection session. Their stress trigger was "${gear1Text}" and their chosen reflection activity was "${gear3Text}". Generate a succinct title (5-8 words max) in title case that synthesizes both into a readable summary. Examples: "Midterm Exam Followed by Deep Breaths", "Work Deadline Eased with Meditation". Do not use quotes or special characters in your response.`,
            },
        ],
        output_config: { format: zodOutputFormat(schema) },
    });

    return response.parsed_output.title;
}

router.post("/", async function (req, res) {
    var db = req.db;
    var userId = req.body && req.body.userId;
    var reflection = req.body && req.body.reflection;
    var variant = req.body && req.body.variant;

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
            variant: variant || null,
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

router.post("/update", async function (req, res) {
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
        var result = await reflections.updateOne(
            { userId: trimmedUserId, "reflection.id": reflection.id },
            { $set: { reflection: reflection } }
        );
        
        if (result.matchedCount === 0) {
            return res.status(404).json({ error: "Reflection not found" });
        }
        
        var responseData = {
            reflection: reflection,
            variantSwitched: false,
        };

        if (reflection.endDate) {
            var doc = await reflections.findOne({
                userId: trimmedUserId,
                "reflection.id": reflection.id,
            });
            var variant = doc && doc.variant;
            if (variant) {
                var advanceResult = await tryAdvancePhase(db, trimmedUserId, variant);
                responseData.variantSwitched = advanceResult.variantSwitched;
                responseData.newVariant = advanceResult.newVariant;
                responseData.newPhase = advanceResult.newPhase;
                responseData.experimentComplete = advanceResult.experimentComplete;
            }

            var gear1Text = reflection.gear1 && reflection.gear1.text;
            var gear3Text = reflection.gear3 && reflection.gear3.text;
            if (gear1Text && gear3Text) {
                try {
                    var title = await generateReflectionTitle(gear1Text, gear3Text);
                    await reflections.updateOne(
                        { userId: trimmedUserId, "reflection.id": reflection.id },
                        { $set: { "reflection.title": title } }
                    );
                    responseData.reflection.title = title;
                } catch (titleErr) {
                    console.error("Error generating reflection title:", titleErr);
                }
            }
        }

        res.status(200).json(responseData);
    }
    catch (err) {
        console.error("Error updating reflection", err);
        res.status(500).json({ error: "Failed to update reflection" });
    }
});

router.delete("/", async function (req, res) {
    var db = req.db;
    var userId = req.body && req.body.userId;
    var reflectionId = req.body && req.body.reflectionId;

    if (!userId || typeof userId !== "string" || !userId.trim()) {
        return res.status(400).json({ error: "userId (string) is required" });
    }

    if (!reflectionId || typeof reflectionId !== "string" || !reflectionId.trim()) {
        return res.status(400).json({ error: "reflectionId (string) is required" });
    }

    var trimmedUserId = userId.trim();

    try {
        var reflections = db.collection("reflections");
        var result = await reflections.deleteOne({
            userId: trimmedUserId,
            "reflection.id": reflectionId.trim(),
        });

        if (result.deletedCount === 0) {
            return res.status(404).json({ error: "Reflection not found" });
        }
        res.status(200).json({ success: true });
    } catch (err) {
        console.error("Error deleting reflection", err);
        res.status(500).json({ error: "Failed to delete reflection" });
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