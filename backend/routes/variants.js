var express = require('express');

var router = express.Router();

var PERMUTATIONS = [
  [1, 2, 3],
  [1, 3, 2],
  [2, 1, 3],
  [2, 3, 1],
  [3, 1, 2],
  [3, 2, 1]
];

router.post('/', async function(req, res) {
  var db = req.db;
  var userId = req.body && req.body.userId;
  if (!userId || typeof userId !== 'string' || !userId.trim()) {
    return res.status(400).json({ error: 'userId (string) is required' });
  }
  var trimmedUserId = userId.trim();

  try {
    var assignments = db.collection('assignments');
    var existing = await assignments.findOne({ userId: trimmedUserId });
    if (existing) {
      var currentPhase = existing.currentPhase || 0;
      var order = existing.order || [existing.variant];
      var variant = order[currentPhase] || existing.variant;
      return res.json({
        userId: existing.userId,
        variant: variant,
        order: order,
        currentPhase: currentPhase,
        assignedAt: existing.assignedAt
      });
    }

    var counts = {};
    for (var i = 0; i < PERMUTATIONS.length; i++) {
      counts[i] = 0;
    }

    var aggregation = await assignments.aggregate([
      { $group: { _id: '$order', count: { $sum: 1 } } }
    ]).toArray();

    aggregation.forEach(function(doc) {
      if (doc._id && Array.isArray(doc._id)) {
        for (var i = 0; i < PERMUTATIONS.length; i++) {
          if (JSON.stringify(PERMUTATIONS[i]) === JSON.stringify(doc._id)) {
            counts[i] = doc.count;
            break;
          }
        }
      }
    });

    var minCount = Math.min.apply(null, Object.values(counts));
    var candidates = Object.keys(counts).filter(function(key) {
      return counts[key] === minCount;
    });
    var chosenIndex = parseInt(
      candidates[Math.floor(Math.random() * candidates.length)],
      10
    );
    var chosenOrder = PERMUTATIONS[chosenIndex];

    var now = new Date();
    await assignments.insertOne({
      userId: trimmedUserId,
      order: chosenOrder,
      currentPhase: 0,
      variant: chosenOrder[0],
      assignedAt: now
    });

    res.status(201).json({
      userId: trimmedUserId,
      variant: chosenOrder[0],
      order: chosenOrder,
      currentPhase: 0,
      assignedAt: now
    });
  } catch (err) {
    console.error('Error assigning variant', err);
    res.status(500).json({ error: 'Failed to assign variant' });
  }
});

router.get('/:userId', async function(req, res) {
  var db = req.db;
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

    var currentPhase = existing.currentPhase || 0;
    var order = existing.order || [existing.variant];
    var variant = order[currentPhase] || existing.variant;

    res.json({
      userId: existing.userId,
      variant: variant,
      order: order,
      currentPhase: currentPhase,
      assignedAt: existing.assignedAt
    });
  } catch (err) {
    console.error('Error fetching variant', err);
    res.status(500).json({ error: 'Failed to fetch variant' });
  }
});

module.exports = router;
