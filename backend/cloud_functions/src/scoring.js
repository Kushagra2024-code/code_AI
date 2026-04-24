export function computeSubmissionScore({ correctness, performance, quality }) {
  const c = Number(correctness || 0);
  const p = Number(performance || 0);
  const q = Number(quality || 0);
  return Math.round(c * 0.4 + p * 0.2 + q * 0.2);
}

export function computeRatingDelta({ score, difficulty, solveTimeSec }) {
  const difficultyWeights = { easy: 0.8, medium: 1.0, hard: 1.3 };
  const level = String(difficulty || "medium").toLowerCase();
  const timeSec = Number(solveTimeSec || 1800);
  const speedFactor = Math.max(0.6, Math.min(1.4, 1200 / Math.max(timeSec, 120)));
  return Math.round((Number(score || 0) - 50) * (difficultyWeights[level] || 1.0) * speedFactor * 0.12);
}

export function computeSessionFinalScore({ codingCorrectness, codingEfficiency, codeQuality, systemDesign }) {
  return Math.round(
    Number(codingCorrectness || 0) * 0.4 +
      Number(codingEfficiency || 0) * 0.2 +
      Number(codeQuality || 0) * 0.2 +
      Number(systemDesign || 0) * 0.2
  );
}
