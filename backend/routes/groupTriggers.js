var Anthropic = require("@anthropic-ai/sdk");
var { zodOutputFormat } = require("@anthropic-ai/sdk/helpers/zod");
var z = require("zod");
var express = require("express");

var router = express.Router();

router.post("/", async function (req, res) {
  try {
    var triggers = req.body && req.body.triggers;

    if (!Array.isArray(triggers) || triggers.length === 0) {
      return res.status(400).json({ error: "triggers (string[]) is required" });
    }

    var groups = await groupTriggers(triggers);
    res.json(groups);
  } catch (error) {
    console.error("Error in group-triggers route:", error);
    res.status(500).json({ error: error.message });
  }
});

async function groupTriggers(triggers) {
  const client = new Anthropic({
    apiKey: process.env.ANTHROPIC_API_KEY,
  });

  const schema = z.array(
    z.object({
      group: z.string(),
      triggers: z.array(z.string()),
    })
  );

  const triggerList = triggers.map((t) => `- ${t}`).join("\n");

  const response = await client.messages.parse({
    model: "claude-sonnet-4-6",
    max_tokens: 4096,
    temperature: 0,
    system:
      "You are a seasoned therapist skilled at categorizing sources of stress into meaningful thematic groups.",
    messages: [
      {
        role: "user",
        content: [
          {
            type: "text",
            text: `You are given a list of stress triggers that a user has identified across multiple reflection sessions. Your task is to group these triggers into at most 5 thematic categories.\n\nHere are the triggers:\n${triggerList}\n\nGroup these into at most 5 categories. Each category should have:\n1. A short group label in title case (2-4 words, e.g., "Work Stress", "Health Concerns", "Relationships")\n2. The list of original trigger strings that belong to that group\n\nEvery trigger must appear in exactly one group. Use the exact original trigger strings in your response. Choose group labels that are meaningful and descriptive of the common theme.`,
          },
        ],
      },
    ],
    output_config: { format: zodOutputFormat(schema) },
  });
  return response.parsed_output;
}

module.exports = router;
