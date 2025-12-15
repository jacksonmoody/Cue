var express = require('express');

var router = express.Router();

function getDb(req) {
  return req.db || (req.app && req.app.locals && req.app.locals.db);
}

function missingDb(res) {
  return res.status(503).json({ error: 'Database not available' });
}

router.post('/', async function(req, res) {
  var db = getDb(req);
  if (!db) {
    return missingDb(res);
  }

  var userId = req.body && req.body.userId;
  if (!userId || typeof userId !== 'string' || !userId.trim()) {
    return res.status(400).json({ error: 'userId (string) is required' });
  }
  var trimmedUserId = userId.trim();

  try {
    var assignments = db.collection('assignments');
    var existing = await assignments.findOne({ userId: trimmedUserId });
    if (existing) {
      return res.json({
        userId: existing.userId,
        variant: existing.variant,
        assignedAt: existing.assignedAt
      });
    }

    var counts = { 1: 0, 2: 0, 3: 0 };
    var aggregation = await assignments.aggregate([
      { $group: { _id: '$variant', count: { $sum: 1 } } }
    ]).toArray();

    aggregation.forEach(function(doc) {
      if (counts.hasOwnProperty(doc._id)) {
        counts[doc._id] = doc.count;
      }
    });

    var minCount = Math.min(counts[1], counts[2], counts[3]);
    var candidates = Object.keys(counts).filter(function(key) {
      return counts[key] === minCount;
    });
    var chosenVariant = parseInt(
      candidates[Math.floor(Math.random() * candidates.length)],
      10
    );

    var now = new Date();
    await assignments.insertOne({
      userId: trimmedUserId,
      variant: chosenVariant,
      assignedAt: now
    });

    res.status(201).json({
      userId: trimmedUserId,
      variant: chosenVariant,
      assignedAt: now
    });
  } catch (err) {
    console.error('Error assigning variant', err);
    res.status(500).json({ error: 'Failed to assign variant' });
  }
});

router.get('/:userId', async function(req, res) {
  var db = getDb(req);
  if (!db) {
    return missingDb(res);
  }

  var userId = req.params.userId;
  if (!userId) {
    return res.status(400).json({ error: 'userId is required' });
  }

  try {
    var assignments = db.collection('assignments');
    var existing = await assignments.findOne({ userId: userId });

    if (!existing) {
      return res.status(404).json({ error: 'Variant not found for user' });
    }

    res.json({
      userId: existing.userId,
      variant: existing.variant,
      assignedAt: existing.assignedAt
    });
  } catch (err) {
    console.error('Error fetching variant', err);
    res.status(500).json({ error: 'Failed to fetch variant' });
  }
});

module.exports = router;

