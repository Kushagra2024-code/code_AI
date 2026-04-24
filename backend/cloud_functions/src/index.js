import { onRequest } from "firebase-functions/v2/https";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

initializeApp();
const db = getFirestore();

const json = (res, status, body) => res.status(status).json(body);

async function checkAuth(req) {
  const auth = req.headers.authorization || "";
  if (!auth.startsWith("Bearer ")) return null;
  return auth.slice(7);
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

  const question = {
    title: "Two Sum Variant",
    difficulty: req.body.difficulty,
    tags: req.body.tags,
    statement: "Given an array and target, return indices of two numbers that add to target.",
    constraints: ["2 <= n <= 1e5", "-1e9 <= nums[i] <= 1e9"],
    examples: [{ input: "nums=[2,7,11,15], target=9", output: "[0,1]" }],
    hiddenTests: [{ input: "[3,3], 6", output: "[0,1]" }],
    createdBy: userId,
    createdAt: FieldValue.serverTimestamp()
  };

  const ref = await db.collection("questions").add(question);
  json(res, 200, { questionId: ref.id, question });
});

export const submitCode = onRequest(async (req, res) => {
  if (req.method !== "POST") return json(res, 405, { error: "Method not allowed" });
  const userId = await guard(req, res);
  if (!userId) return;

  const missing = requireFields(req.body || {}, ["sessionId", "code", "language", "result"]);
  if (missing) return json(res, 400, { error: `Missing field: ${missing}` });

  const payload = req.body;
  const correctness = Number(payload.result?.correctness || 0);
  const performance = Number(payload.result?.performance || 0);
  const quality = Number(payload.result?.quality || 0);

  const score = Math.round(correctness * 0.4 + performance * 0.2 + quality * 0.2);

  const doc = {
    sessionId: payload.sessionId,
    userId,
    code: payload.code,
    language: payload.language,
    passedTests: payload.result?.passedTests || 0,
    execution: payload.result?.execution || {},
    score,
    createdAt: FieldValue.serverTimestamp()
  };

  const ref = await db.collection("submissions").add(doc);
  json(res, 200, { submissionId: ref.id, score });
});

export const evaluateDesign = onRequest(async (req, res) => {
  if (req.method !== "POST") return json(res, 405, { error: "Method not allowed" });
  const userId = await guard(req, res);
  if (!userId) return;

  const missing = requireFields(req.body || {}, ["sessionId", "diagram"]);
  if (missing) return json(res, 400, { error: `Missing field: ${missing}` });

  const evalResult = {
    score: 78,
    missingComponents: ["cache invalidation strategy", "read replica failover"],
    improvements: ["Add CDN for static media", "Use async queue for heavy writes"]
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

  json(res, 200, {
    feedback: {
      timeComplexity: "O(n^2)",
      optimalComplexity: "O(n log n)",
      suggestions: ["Use sorting + binary search", "Handle empty input edge case"]
    }
  });
});

export const sessionScore = onRequest(async (req, res) => {
  if (req.method !== "GET") return json(res, 405, { error: "Method not allowed" });
  const userId = await guard(req, res);
  if (!userId) return;

  const sessionId = req.query.sessionId;
  if (!sessionId) return json(res, 400, { error: "Missing sessionId" });

  const subs = await db.collection("submissions").where("sessionId", "==", sessionId).get();
  const designs = await db.collection("designSubmissions").where("sessionId", "==", sessionId).get();

  const codingScore = subs.empty ? 0 : Math.max(...subs.docs.map((d) => d.data().score || 0));
  const designScore = designs.empty ? 0 : Math.max(...designs.docs.map((d) => d.data().evaluation?.score || 0));

  const finalScore = Math.round(codingScore * 0.8 + designScore * 0.2);
  json(res, 200, { sessionId, codingScore, designScore, finalScore });
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
