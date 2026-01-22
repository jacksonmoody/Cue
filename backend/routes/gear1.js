var Anthropic = require("@anthropic-ai/sdk");
var { betaZodOutputFormat } = require("@anthropic-ai/sdk/helpers/beta/zod");
var z = require("zod");
var express = require("express");
var { getUserInfo } = require("./users");
var { google } = require("googleapis");
var crypto = require("crypto");

var router = express.Router();

router.post("/", async function (req, res) {
  try {
    var db = req.db;
    var idToken = req.body && req.body.idToken;
    var location = req.body && req.body.location;

    if (!idToken || typeof idToken !== "string" || !idToken.trim()) {
      return res.status(400).json({ error: "idToken (string) is required" });
    }

    if (!location || typeof location !== "string" || !location.trim()) {
      return res.status(400).json({ error: "location (string) is required" });
    }

    var [googleTokens, occupation] = await getUserInfo(db, idToken);
    if (!googleTokens || !occupation) {
      return res.status(401).json({ error: "Invalid user info" });
    }

    var upcomingEvents = await getUpcomingEvents(googleTokens, occupation);

    var timeOfDay = new Date().getHours();
    var dayOfWeek = new Date().getDay();
    var eventsText = upcomingEvents
      .map(
        (event) =>
          `${event.summary} at ${event.start}${
            event.description ? ": " + event.description : ""
          }`
      )
      .join("\n");

    var userContext = `Events Today:\n${eventsText}\nTime of Day: ${timeOfDay}\nDay of Week: ${dayOfWeek}\nOccupational Status: ${occupation}\nCurrent Location: ${location}`;
    var stressSources = await llmCall(userContext);
    var formattedStressSources = stressSources.map(function (source) {
      return {
        ...source,
        id: crypto.randomUUID(),
      };
    });
    res.json(formattedStressSources);
  } catch (error) {
    console.error("Error in gear1 route:", error);
    res.status(500).json({ error: error.message });
  }
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
    const nextDay = new Date(now.getTime() + 24 * 60 * 60 * 1000);
    const response = await calendar.events.list({
      calendarId: "primary",
      timeMin: now.toISOString(),
      timeMax: nextDay.toISOString(),
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
  const client = new Anthropic({
    apiKey: process.env.ANTHROPIC_API_KEY,
  });

  const schema = z.array(z.object({
      text: z.string(),
      icon: z.string(),
  }));

  const outputFormat = betaZodOutputFormat(schema);

  const response = await client.beta.messages.parse({
    model: "claude-sonnet-4-5",
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
            text: `You will be generating possible sources of stress for a user based on their current context. This is for Gear 1 of Jud Brewer\'s 3 gears framework, which focuses on awareness of the “habit loop” – becoming conscious of the triggers of a particular stress response.\n\nHere is the user\'s context information:\n<user_context>\n${userContext}\n</user_context>\n\nYour task is to generate 4-5 possible sources of stress that are relevant to this user based on their calendar events today, time of day (in hours), day of the week (1-7), occupational status, and most recent location. \n\nBefore generating your list, use the scratchpad to think through what might be stressing this person given their context.\n\n<scratchpad>\nConsider:\n- What upcoming events or deadlines might be causing stress?\n- Are there time pressures based on the current time and scheduled events?\n- What work or personal obligations might be weighing on them?\n- Are there contextual factors (day of week, location) that suggest particular stressors?\n- What common stressors apply to someone with their occupational status?\n</scratchpad>\n\nNow generate your list of stress sources. Each stress source should have:\n1. A very short title in title case (2-4 words) (e.g., "11am Meeting with John", "Staying up Late", "Traffic on Commute")\n2. An SF symbol name that visually represents the stressor, or an empty string if no suitable symbol exists. Make the stress sources realistic and specific to the user\'s context. Vary the types of stressors (work-related, time pressure, social, personal obligations, etc.) to give a comprehensive picture of potential stress in their current situation. Do not create new stressors that are not already present in the user\'s context; it is better to have less stressors than more. Do not include leading or trailing spaces in the title or icon names.`,
          },
        ],
      },
    ],
    output_format: outputFormat,
  });
  return response.parsed_output;
}

module.exports = router;
