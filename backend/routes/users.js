var express = require("express");
var { OAuth2Client } = require("google-auth-library");

var router = express.Router();

function getDb(req) {
  return req.db || (req.app && req.app.locals && req.app.locals.db);
}

function missingDb(res) {
  return res.status(503).json({ error: "Database not available" });
}

router.post("/sign-in", async function (req, res) {
  var db = getDb(req);
  if (!db) {
    return missingDb(res);
  }

  var idToken = req.body && req.body.idToken;
  var authCode = req.body && req.body.authCode;

  var webClientId = process.env.GOOGLE_CLIENT_ID;
  var webClientSecret = process.env.GOOGLE_CLIENT_SECRET;

  if (!webClientId) {
    return res.status(500).json({ error: "Google Client ID not configured" });
  }

  if (!webClientSecret) {
    return res
      .status(500)
      .json({ error: "Google Client Secret not configured" });
  }

  try {
    var userid;
    var email;
    var name;
    var tokens = null;

    if (idToken) {
      var client = new OAuth2Client();
      var ticket = await client.verifyIdToken({
        idToken: idToken,
        audience: webClientId,
      });

      var payload = ticket.getPayload();
      userid = payload["sub"];
      email = payload["email"];
      name = payload["name"];
    } else {
      return res.status(400).json({ error: "idToken (string) is required" });
    }

    if (authCode) {
      var oauth2ClientOptions = {
        clientId: webClientId,
        clientSecret: webClientSecret,
      };
      var oauth2Client = new OAuth2Client(oauth2ClientOptions);

      var tokenResponse = await oauth2Client.getToken(authCode.trim());
      tokens = tokenResponse.tokens;
    }

    var users = db.collection("users");
    var updateDoc = {
      $set: {
        email: email,
        name: name,
        lastSignIn: new Date(),
      },
      $setOnInsert: {
        createdAt: new Date(),
      },
    };

    if (tokens) {
      updateDoc.$set.tokens = {
        access_token: tokens.access_token,
        refresh_token: tokens.refresh_token,
        expiry_date: tokens.expiry_date,
        token_type: tokens.token_type,
      };
    }

    await users.updateOne({ userId: userid }, updateDoc, { upsert: true });

    var response = {
      userId: userid,
      email: email,
      name: name,
    };

    if (tokens) {
      response.calendarAuthorized = true;
    }

    res.json(response);
  } catch (err) {
    console.error("Error in sign-in", err);
    res.status(401).json({ error: "Failed to authenticate" });
  }
});

module.exports = router;
