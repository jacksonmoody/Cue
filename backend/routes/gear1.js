var Anthropic = require("@anthropic-ai/sdk");
var express = require("express");
var requireDb = require("../middleware/db");
var { getDecryptedTokens } = require("./users");
var { google } = require("googleapis");

var router = express.Router();
router.use(requireDb);

router.get("/", async function (req, res) {
  var db = req.db;
  var idToken = req.body && req.body.idToken;
  var location = req.body && req.body.location;
  var occupation = req.body && req.body.occupation;

  if (!idToken || typeof idToken !== "string" || !idToken.trim()) {
    return res.status(400).json({ error: "idToken (string) is required" });
  }

  var googleTokens = await getDecryptedTokens(db, idToken);
  if (!googleTokens) {
    return res.status(401).json({ error: "Invalid Google tokens" });
  }

  upcomingEvents = await getUpcomingEvents(googleTokens);

  var timeOfDay = new Date().getHours()
  var dayOfWeek = new Date().getDay() + 1;

  var userContext = `Events Today: ${upcomingEvents.join("\n")}\nTime of Day: ${timeOfDay}\nDay of Week: ${dayOfWeek}\nOccupational Status: ${occupation}\nCurrent Location: ${location}`;
  var stressSources = await llmCall(userContext);
  res.json(stressSources);
});

async function getUpcomingEvents(googleTokens) {
  try {
    const oauth2Client = new google.auth.OAuth2(
      process.env.GOOGLE_CLIENT_ID,
      process.env.GOOGLE_CLIENT_SECRET
    );

    oauth2Client.setCredentials(googleTokens);
    const calendar = google.calendar({ version: "v3", auth: oauth2Client });

    const now = new Date();
    const endOfToday = new Date();
    endOfToday.setHours(23, 59, 59, 999);
    const response = await calendar.events.list({
      calendarId: "primary",
      timeMin: now.toISOString(),
      timeMax: endOfToday.toISOString(),
      maxResults: 10,
      singleEvents: true,
      orderBy: "startTime",
    });

    const events = response.data.items || [];
    return events.map((event) => ({
      summary: event.summary,
      start: event.start.dateTime || event.start.date,
      description: event.description,
    }));
  } catch (error) {
    throw error;
  }
}

async function llmCall(userContext) {
  const anthropic = new Anthropic({
    apiKey: process.env.ANTHROPIC_API_KEY,
  });

  const response = await anthropic.messages.create({
    model: "claude-sonnet-4-5-20250929",
    max_tokens: 10000,
    betas: ["structured-outputs-2025-11-13"],
    temperature: 0,
    system:
      "You are a seasoned therapist tasked with analyzing sources of stress in a client's life given particular context.",
    messages: [
      {
        role: "user",
        content: [
          {
            type: "text",
            text: `You will be generating possible sources of stress for a user based on their current context. This is for Gear 1 of Jud Brewer\'s 3 gears framework, which focuses on awareness of the “habit loop” – becoming conscious of the triggers of a particular stress response.\n\nHere is the user\'s context information:\n<user_context>\n${userContext}\n</user_context>\n\nYour task is to generate 4-6 possible sources of stress that are relevant to this user based on their location, calendar events, time of day (in hours), day of the week (1-7), and occupational status. \n\nBefore generating your list, use the scratchpad to think through what might be stressing this person given their context.\n\n<scratchpad>\nConsider:\n- What upcoming events or deadlines might be causing stress?\n- Are there time pressures based on the current time and scheduled events?\n- What work or personal obligations might be weighing on them?\n- Are there contextual factors (day of week, location) that suggest particular stressors?\n- What common stressors apply to someone with their occupational status?\n</scratchpad>\n\nNow generate your list of stress sources. Each stress source should have:\n1. A very short title (3-4 words) (e.g., "11am meeting with John", "Unfinished project deadline", "Traffic on commute ")\n2. An SF symbol name that visually represents the stressor, or "null" if no suitable symbol exists. Make the stress sources realistic and specific to the user\'s context. Vary the types of stressors (work-related, time pressure, social, personal obligations, etc.) to give a comprehensive picture of potential stress in their current situation.`,
          },
        ],
      },
    ],
    output_format: {
      type: "json_schema",
      schema: {
        type: "object",
        properties: {
          stressSources: {
            type: "array",
            items: {
              type: "object",
              properties: {
                title: { type: "string" },
                symbol: { type: "string" },
              },
              required: ["title", "symbol"],
              additionalProperties: false,
            },
          },
        },
        required: ["stressSources"],
        additionalProperties: false,
      },
    },
  });
  return response.content[0].text;
}
