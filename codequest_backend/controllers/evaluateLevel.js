 
const evaluateLevel = (req, res) => {
  try {
    const { answers } = req.body;
 
    // ── Input validation ───────────────────────────────────────────────────
    if (!answers || !Array.isArray(answers) || answers.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'answers array is required and must not be empty',
      });
    }
 
    // ── Scoring setup ──────────────────────────────────────────────────────
    const weights = { Sequential: 1, Conditional: 2, Loop: 3 };
 
    const categoryScore = { Sequential: 0, Conditional: 0, Loop: 0 };
    const categoryCount = { Sequential: 0, Conditional: 0, Loop: 0 };
    let totalScore = 0;
 
    answers.forEach(({ category, isCorrect }) => {
      if (!categoryScore.hasOwnProperty(category)) return; // ignore unknown categories
 
      categoryCount[category]++;
      if (isCorrect) {
        totalScore += weights[category] ?? 1;
        categoryScore[category]++;
      }
    });
 
    // ── Per-category accuracy (guard against divide-by-zero) ───────────────
    const accuracy = {};
    Object.keys(categoryScore).forEach((cat) => {
      accuracy[cat] = categoryCount[cat] > 0
        ? categoryScore[cat] / categoryCount[cat]
        : 0;
    });
 
    // ── Overall accuracy (average of the three categories) ─────────────────
    const answeredCategories = Object.keys(accuracy).filter(
      (cat) => categoryCount[cat] > 0
    );
    const overallAccuracy = answeredCategories.length > 0
      ? answeredCategories.reduce((sum, cat) => sum + accuracy[cat], 0) / answeredCategories.length
      : 0;
 
    // ── Level determination ────────────────────────────────────────────────
    let level = 'Beginner';
    if (overallAccuracy >= 0.75 && accuracy.Loop >= 0.6) {
      level = 'Advanced';
    } else if (overallAccuracy >= 0.5) {
      level = 'Intermediate';
    }
 
    // ── Learner type ───────────────────────────────────────────────────────
    let learnerType = 'Step-by-Step Thinker';
    if (accuracy.Loop >= accuracy.Conditional && accuracy.Loop >= accuracy.Sequential) {
      learnerType = 'Logic Builder';
    } else if (accuracy.Conditional >= accuracy.Sequential) {
      learnerType = 'Decision Maker';
    }
 
    // ── Response ───────────────────────────────────────────────────────────
    // IMPORTANT: Flutter reads these exact field names:
    //   result['level']           → String
    //   result['learnerType']     → String
    //   result['overallAccuracy'] → double (0.0 – 1.0)
    return res.status(200).json({
      success: true,
      totalScore,
      level,
      learnerType,
      overallAccuracy,   // value between 0.0 and 1.0
      accuracy,          // per-category breakdown
    });
 
  } catch (error) {
    console.error('evaluateLevel error:', error);
    return res.status(500).json({
      success: false,
      message: 'Error evaluating level',
    });
  }
};
 
export default evaluateLevel;