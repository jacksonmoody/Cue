var express = require("express");
var { OAuth2Client } = require("google-auth-library");
var { encryptObject, decryptObject } = require("../utils/encryption");

var router = express.Router();

function getDb(req) {
  return req.db || (req.app && req.app.locals && req.app.locals.db);
}

function missingDb(res) {
  return res.status(503).json({ error: "Database not available" });
}

async function getDecryptedTokens(db, userId) {
  var encryptionKey = process.env.ENCRYPTION_KEY;
  if (!encryptionKey) {
    throw new Error("ENCRYPTION_KEY is not configured");
  }

  var users = db.collection("users");
  var user = await users.findOne({ userId: userId });

  if (!user || !user.tokens) {
    return null;
  }

  // Decrypt the encrypted token fields
  var decryptedTokens = decryptObject(
    user.tokens,
    ["access_token", "refresh_token"],
    encryptionKey
  );

  return decryptedTokens;
}

router.post("/sign-in", async function (req, res) {
  var db = getDb(req);
  if (!db) {
    return missingDb(res);
  }

  var idToken = req.body && req.body.idToken;
  var authCode = req.body && req.body.authCode;
  var appleIdToken = req.body && req.body.appleIdToken;

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
    } else {
      return res.status(400).json({ error: "authCode (string) is required" });
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
      var encryptionKey = process.env.ENCRYPTION_KEY;
      if (!encryptionKey) {
        return res.status(500).json({
          error: "Server error: encryption key not set",
        });
      }

      var tokensToStore = {
        access_token: tokens.access_token,
        refresh_token: tokens.refresh_token,
        expiry_date: tokens.expiry_date,
        token_type: tokens.token_type,
      };

      var encryptedTokens = encryptObject(
        tokensToStore,
        ["access_token", "refresh_token"],
        encryptionKey
      );

      updateDoc.$set.tokens = encryptedTokens;
    }

    await users.updateOne({ userId: appleIdToken }, updateDoc, {
      upsert: true,
    });

    if (encryptedTokens) {
      res.json(true);
    } else {
      res.json(false);
    }
  } catch (err) {
    console.error("Error in authentication", err);
    res.status(401).json({ error: "Failed to authenticate" });
  }
});

router.post("/occupation", async function(req, res) {
  var db = getDb(req);
  if (!db) {
    return missingDb(res);
  }

  var userId = req.body && req.body.userId;
  var occupation = req.body && req.body.occupation;

  if (!userId || typeof userId !== "string" || !userId.trim()) {
    return res.status(400).json({ error: "userId (string) is required" });
  }

  if (!occupation || typeof occupation !== "string" || !occupation.trim()) {
    return res.status(400).json({ error: "occupation (string) is required" });
  }

  try {
    var users = db.collection("users");
    var updateDoc = {
      $set: {
        occupation: occupation,
      },
    };
    await users.updateOne({ userId: userId }, updateDoc);
    res.json(true);
  } catch (err) {
    console.error("Error updating occupation", err);
    res.status(500).json({ error: "Failed to update occupation" });
  }
});

module.exports = router;
