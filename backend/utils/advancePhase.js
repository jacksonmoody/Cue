const EIGHT_HOURS_IN_SECONDS = 28800;

async function tryAdvancePhase(db, userId, variant) {
  var sessions = db.collection("sessions");
  var reflections = db.collection("reflections");
  var assignments = db.collection("assignments");

  var [totalResult, reflectionCount, assignment] = await Promise.all([
    sessions
      .aggregate([
        { $match: { userId: userId, variant: variant } },
        { $group: { _id: null, total: { $sum: "$duration" } } },
      ])
      .toArray(),
    reflections.countDocuments({
      userId: userId,
      variant: variant,
      "reflection.endDate": { $exists: true, $ne: null },
    }),
    assignments.findOne({ userId: userId }),
  ]);

  var totalDuration = totalResult.length > 0 ? totalResult[0].total : 0;

  var result = {
    secondsLogged: totalDuration,
    variantSwitched: false,
    newVariant: null,
    newPhase: null,
    experimentComplete: false,
  };

  if (!assignment || !assignment.order) {
    return result;
  }

  var durationMet = totalDuration >= EIGHT_HOURS_IN_SECONDS;
  var reflectionMet = reflectionCount >= 1;

  // Advance to next phase requirements are met
  if (durationMet && reflectionMet && assignment.currentPhase < 2) {
    var newPhase = assignment.currentPhase + 1;
    var newVariant = assignment.order[newPhase];

    await assignments.updateOne(
      { userId: userId },
      { $set: { currentPhase: newPhase, variant: newVariant } },
    );

    result.variantSwitched = true;
    result.newVariant = newVariant;
    result.newPhase = newPhase;
  }

  // Check if experiment is complete if on last phase
  if (assignment.currentPhase === 2 && durationMet) {
    var perVariantReflections = await reflections
      .aggregate([
        {
          $match: {
            userId: userId,
            "reflection.endDate": { $exists: true, $ne: null },
            variant: { $in: assignment.order },
          },
        },
        { $group: { _id: "$variant", count: { $sum: 1 } } },
      ])
      .toArray();

    var variantsWithReflections = new Set(
      perVariantReflections.map(function (doc) {
        return doc._id;
      }),
    );
    var allReflectionsComplete = assignment.order.every(function (v) {
      return variantsWithReflections.has(v);
    });

    if (allReflectionsComplete) {
      result.experimentComplete = true;
    }
  }
  return result;
}

module.exports = { tryAdvancePhase, EIGHT_HOURS_IN_SECONDS };
