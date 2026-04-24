import assert from "node:assert/strict";
import test from "node:test";

import {
  computeRatingDelta,
  computeSessionFinalScore,
  computeSubmissionScore,
} from "../src/scoring.js";

test("computeSubmissionScore applies weighted scoring", () => {
  const score = computeSubmissionScore({ correctness: 80, performance: 70, quality: 60 });
  assert.equal(score, 58);
});

test("computeRatingDelta increases for hard + fast solves", () => {
  const delta = computeRatingDelta({ score: 90, difficulty: "hard", solveTimeSec: 300 });
  assert.ok(delta > 0);
});

test("computeRatingDelta penalizes low scores", () => {
  const delta = computeRatingDelta({ score: 20, difficulty: "medium", solveTimeSec: 900 });
  assert.ok(delta < 0);
});

test("computeSessionFinalScore uses required formula", () => {
  const finalScore = computeSessionFinalScore({
    codingCorrectness: 80,
    codingEfficiency: 60,
    codeQuality: 70,
    systemDesign: 90,
  });
  assert.equal(finalScore, 76);
});
