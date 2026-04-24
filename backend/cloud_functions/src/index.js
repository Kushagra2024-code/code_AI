import { onRequest } from "firebase-functions/v2/https";
import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { computeRatingDelta, computeSessionFinalScore, computeSubmissionScore } from "./scoring.js";

initializeApp();
const db = getFirestore();
const genkitBaseUrl = process.env.GENKIT_BASE_URL || "";
const judgeBaseUrl = process.env.JUDGE_SERVICE_URL || "";

const json = (res, status, body) => res.status(status).json(body);

async function callJson(url, body) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 10000);
  try {
    const response = await fetch(url, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(body),
      signal: controller.signal,
    });
    if (!response.ok) {
      throw new Error(await response.text());
    }
    return await response.json();
  } finally {
    clearTimeout(timeout);
  }
}

async function checkAuth(req) {
  const auth = req.headers.authorization || "";
  if (!auth.startsWith("Bearer ")) return null;
  const token = auth.slice(7);

  if (process.env.FUNCTIONS_EMULATOR === "true" && token.startsWith("demo-")) {
    return token;
  }

  try {
    const decoded = await getAuth().verifyIdToken(token);
    return decoded.uid;
  } catch (_) {
    return null;
  }
}

async function rateLimit(userId) {
  const now = Date.now();
  const minute = Math.floor(now / 60000);
  const key = `rate_${userId}_${minute}`;
  const ref = db.collection("_rateLimits").doc(key);
  const limit = Number(process.env.RATE_LIMIT_PER_MINUTE || 30);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const count = (snap.exists ? snap.data().count : 0) || 0;
    if (count >= limit) throw new Error("rate_limited");
    tx.set(ref, { count: count + 1, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
  });
}

async function guard(req, res) {
  const userId = await checkAuth(req);
  if (!userId) {
    json(res, 401, { error: "Unauthorized" });
    return null;
  }
  try {
    await rateLimit(userId);
  } catch (e) {
    json(res, 429, { error: "Rate limit exceeded" });
    return null;
  }
  return userId;
}

function requireFields(obj, fields) {
  for (const field of fields) {
    if (!(field in obj)) return field;
  }
  return null;
}

export const generateQuestion = onRequest(async (req, res) => {
  if (req.method !== "POST") return json(res, 405, { error: "Method not allowed" });
  const userId = await guard(req, res);
  if (!userId) return;

  const missing = requireFields(req.body || {}, ["difficulty", "tags"]);
  if (missing) return json(res, 400, { error: `Missing field: ${missing}` });

  let generated;
  if (genkitBaseUrl) {
    try {
      generated = await callJson(`${genkitBaseUrl}/questionGenerationFlow`, {
        difficulty: req.body.difficulty,
        tags: req.body.tags,
      });
    } catch (_) {
      generated = null;
    }
  }

  const question = {
    title: generated?.title || "Two Sum Variant",
    difficulty: generated?.difficulty || req.body.difficulty,
    tags: generated?.tags || req.body.tags,
    statement: generated?.statement || "Given an array and target, return indices of two numbers that add to target.",
    constraints: generated?.constraints || ["2 <= n <= 1e5", "-1e9 <= nums[i] <= 1e9"],
    examples: generated?.examples || [{ input: "nums=[2,7,11,15], target=9", output: "[0,1]" }],
    hiddenTests: generated?.hiddenTests || [{ input: "[3,3], 6", output: "[0,1]" }],
    createdBy: userId,
    createdAt: FieldValue.serverTimestamp(),
  };

  const ref = await db.collection("questions").add(question);
  json(res, 200, { questionId: ref.id, question });
});

export const runCode = onRequest(async (req, res) => {
  if (req.method !== "POST") return json(res, 405, { error: "Method not allowed" });
  const userId = await guard(req, res);
  if (!userId) return;

  const missing = requireFields(req.body || {}, ["code", "language"]);
  if (missing) return json(res, 400, { error: `Missing field: ${missing}` });

  const payload = req.body;

  if (judgeBaseUrl) {
    try {
      const result = await callJson(`${judgeBaseUrl}/run`, {
        code: payload.code,
        language: payload.language,
        stdin: payload.stdin || "",
      });
      return json(res, 200, result);
    } catch (_) {
      // Fallback below if Judge service is unavailable.
    }
  }

  return json(res, 200, {
    stdout: "",
    stderr: "Judge service unavailable. Configure JUDGE_SERVICE_URL to enable real execution.",
    compileOutput: "",
    time: null,
    memory: null,
    status: "Unavailable",
  });
});

export const submitCode = onRequest(async (req, res) => {
  if (req.method !== "POST") return json(res, 405, { error: "Method not allowed" });
  const userId = await guard(req, res);
  if (!userId) return;

  const missing = requireFields(req.body || {}, ["sessionId", "code", "language"]);
  if (missing) return json(res, 400, { error: `Missing field: ${missing}` });

  const payload = req.body;
  let correctness = Number(payload.result?.correctness || 0);
  let performance = Number(payload.result?.performance || 0);
  const quality = Number(payload.result?.quality || 0);
  let execution = payload.result?.execution || {};
  let passedTests = payload.result?.passedTests || 0;

  if (judgeBaseUrl && (payload.sampleTests || payload.hiddenTests)) {
    try {
      const judge = await callJson(`${judgeBaseUrl}/submit`, {
        code: payload.code,
        language: payload.language,
        sampleTests: payload.sampleTests || [],
        hiddenTests: payload.hiddenTests || [],
      });
      correctness = Number(judge.correctness || 0);
      performance = Number(judge.performance || 0);
      passedTests = Number(judge.passed || 0);
      execution = { details: judge.details || [] };
    } catch (_) {
      // If Judge0 integration fails, keep fallback result payload.
    }
  }

  const score = computeSubmissionScore({ correctness, performance, quality });
  const ratingDelta = computeRatingDelta({
    score,
    difficulty: payload.difficulty,
    solveTimeSec: payload.solveTimeSec,
  });

  const doc = {
    sessionId: payload.sessionId,
    userId,
    code: payload.code,
    language: payload.language,
    correctness,
    performance,
    quality,
    passedTests,
    execution,
    score,
    createdAt: FieldValue.serverTimestamp()
  };

  const ref = await db.collection("submissions").add(doc);

  const userRef = db.collection("users").doc(userId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(userRef);
    const currentRating = Number(snap.exists ? snap.data().rating || 1200 : 1200);
    const nextRating = Math.max(800, currentRating + ratingDelta);
    tx.set(
      userRef,
      {
        rating: nextRating,
        lastSubmissionAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  });

  json(res, 200, { submissionId: ref.id, score, ratingDelta });
});

export const interviewTurn = onRequest(async (req, res) => {
  if (req.method !== "POST") return json(res, 405, { error: "Method not allowed" });
  const userId = await guard(req, res);
  if (!userId) return;

  const missing = requireFields(req.body || {}, ["stage", "context"]);
  if (missing) return json(res, 400, { error: `Missing field: ${missing}` });

  let response;
  if (genkitBaseUrl) {
    try {
      response = await callJson(`${genkitBaseUrl}/aiInterviewerFlow`, {
        stage: req.body.stage,
        context: req.body.context,
      });
    } catch (_) {
      response = null;
    }
  }

  response = response || {
    message: "Walk me through your approach and justify your complexity trade-offs.",
    followUps: [
      "What edge cases can break this solution?",
      "How would you optimize this for very large input?",
    ],
  };

  json(res, 200, response);
});

export const evaluateDesign = onRequest(async (req, res) => {
  if (req.method !== "POST") return json(res, 405, { error: "Method not allowed" });
  const userId = await guard(req, res);
  if (!userId) return;

  const missing = requireFields(req.body || {}, ["sessionId", "diagram"]);
  if (missing) return json(res, 400, { error: `Missing field: ${missing}` });

  let evalResult;
  if (genkitBaseUrl) {
    try {
      evalResult = await callJson(`${genkitBaseUrl}/systemDesignEvaluationFlow`, {
        question: req.body.question || "Design a scalable distributed system",
        diagram: req.body.diagram,
      });
    } catch (_) {
      evalResult = null;
    }
  }

  evalResult = evalResult || {
    score: 78,
    missingComponents: ["cache invalidation strategy", "read replica failover"],
    improvements: ["Add CDN for static media", "Use async queue for heavy writes"],
  };

  const ref = await db.collection("designSubmissions").add({
    sessionId: req.body.sessionId,
    userId,
    diagram: req.body.diagram,
    evaluation: evalResult,
    createdAt: FieldValue.serverTimestamp()
  });

  json(res, 200, { designId: ref.id, evaluation: evalResult });
});

export const detectCheating = onRequest(async (req, res) => {
  if (req.method !== "POST") return json(res, 405, { error: "Method not allowed" });
  const userId = await guard(req, res);
  if (!userId) return;

  const missing = requireFields(req.body || {}, ["sessionId", "signals"]);
  if (missing) return json(res, 400, { error: `Missing field: ${missing}` });

  const s = req.body.signals;
  const score = (s.tabSwitches || 0) * 10 + (s.largePaste ? 30 : 0) + (s.tooFast ? 20 : 0) + (s.similarityHigh ? 40 : 0);
  const flagged = score >= 40;

  const ref = await db.collection("cheatFlags").add({
    sessionId: req.body.sessionId,
    userId,
    signals: s,
    suspiciousScore: score,
    flagged,
    createdAt: FieldValue.serverTimestamp()
  });

  json(res, 200, { flagId: ref.id, flagged, suspiciousScore: score });
});

export const generateFeedback = onRequest(async (req, res) => {
  if (req.method !== "POST") return json(res, 405, { error: "Method not allowed" });
  const userId = await guard(req, res);
  if (!userId) return;

  const missing = requireFields(req.body || {}, ["submissionId", "code"]);
  if (missing) return json(res, 400, { error: `Missing field: ${missing}` });

  let feedback;
  if (genkitBaseUrl) {
    try {
      feedback = await callJson(`${genkitBaseUrl}/codeFeedbackFlow`, {
        code: req.body.code,
        language: req.body.language || "unknown",
        problem: req.body.problem || "General coding interview problem",
      });
    } catch (_) {
      feedback = null;
    }
  }

  feedback = feedback || {
    timeComplexity: "O(n^2)",
    optimalComplexity: "O(n log n)",
    memoryComplexity: "O(n)",
    suggestions: ["Use sorting + binary search", "Handle empty input edge case"],
  };

  json(res, 200, { feedback });
});

export const sessionScore = onRequest(async (req, res) => {
  if (req.method !== "GET") return json(res, 405, { error: "Method not allowed" });
  const userId = await guard(req, res);
  if (!userId) return;

  const sessionId = req.query.sessionId;
  if (!sessionId) return json(res, 400, { error: "Missing sessionId" });

  const subs = await db.collection("submissions").where("sessionId", "==", sessionId).get();
  const designs = await db.collection("designSubmissions").where("sessionId", "==", sessionId).get();

  const codingCorrectness = subs.empty ? 0 : Math.max(...subs.docs.map((d) => Number(d.data().correctness || 0)));
  const codingEfficiency = subs.empty ? 0 : Math.max(...subs.docs.map((d) => Number(d.data().performance || 0)));
  const codeQuality = subs.empty ? 0 : Math.max(...subs.docs.map((d) => Number(d.data().quality || 0)));
  const designScore = designs.empty ? 0 : Math.max(...designs.docs.map((d) => d.data().evaluation?.score || 0));

  const finalScore = computeSessionFinalScore({
    codingCorrectness,
    codingEfficiency,
    codeQuality,
    systemDesign: Number(designScore || 0),
  });

  json(res, 200, {
    sessionId,
    components: {
      codingCorrectness,
      codingEfficiency,
      codeQuality,
      systemDesign: Number(designScore || 0),
    },
    finalScore,
  });
});

export const analytics = onRequest(async (req, res) => {
  if (req.method !== "GET") return json(res, 405, { error: "Method not allowed" });
  const userId = await guard(req, res);
  if (!userId) return;

  const subs = await db.collection("submissions").where("userId", "==", userId).get();
  const total = subs.size;
  let passed = 0;
  let avgScore = 0;
  subs.forEach((d) => {
    const data = d.data();
    if ((data.passedTests || 0) > 0) passed += 1;
    avgScore += Number(data.score || 0);
  });

  avgScore = total ? Math.round(avgScore / total) : 0;

  json(res, 200, {
    userId,
    metrics: {
      totalSubmissions: total,
      accuracyRate: total ? Number(((passed / total) * 100).toFixed(2)) : 0,
      averageScore: avgScore,
      difficultyProgress: {
        easy: avgScore,
        medium: Math.max(avgScore - 5, 0),
        hard: Math.max(avgScore - 12, 0)
      }
    }
  });
});
