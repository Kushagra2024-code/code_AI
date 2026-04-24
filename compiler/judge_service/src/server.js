import express from "express";

const app = express();
app.use(express.json({ limit: "1mb" }));

const base = process.env.JUDGE0_BASE_URL;
const key = process.env.JUDGE0_API_KEY;
const port = Number(process.env.PORT || 8080);

const headers = {
  "content-type": "application/json",
  ...(key ? { "x-rapidapi-key": key } : {}),
};

const languageMap = {
  cpp: 54,
  python: 71,
  java: 62,
  javascript: 63,
};

async function submitToJudge0({ code, languageId, stdin, expectedOutput }) {
  const create = await fetch(`${base}/submissions?base64_encoded=false&wait=false`, {
    method: "POST",
    headers,
    body: JSON.stringify({
      source_code: code,
      language_id: languageId,
      stdin,
      expected_output: expectedOutput,
    }),
  });

  if (!create.ok) {
    throw new Error(`Judge0 create failed: ${await create.text()}`);
  }

  const { token } = await create.json();
  let result;

  for (let i = 0; i < 20; i++) {
    const poll = await fetch(`${base}/submissions/${token}?base64_encoded=false`, { headers });
    if (!poll.ok) throw new Error(`Judge0 poll failed: ${await poll.text()}`);
    result = await poll.json();
    if (result.status?.id && result.status.id >= 3) break;
    await new Promise((resolve) => setTimeout(resolve, 500));
  }

  return result;
}

app.get("/health", (_req, res) => {
  res.json({ ok: true });
});

app.post("/run", async (req, res) => {
  try {
    const { code, language, stdin } = req.body || {};
    if (!code || !language) {
      return res.status(400).json({ error: "code and language are required" });
    }

    const result = await submitToJudge0({
      code,
      languageId: languageMap[language],
      stdin: stdin || "",
      expectedOutput: undefined,
    });

    return res.json({
      stdout: result.stdout || "",
      stderr: result.stderr || "",
      compileOutput: result.compile_output || "",
      time: result.time || null,
      memory: result.memory || null,
      status: result.status?.description || "Unknown",
    });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

app.post("/submit", async (req, res) => {
  try {
    const { code, language, sampleTests = [], hiddenTests = [] } = req.body || {};
    if (!code || !language) {
      return res.status(400).json({ error: "code and language are required" });
    }

    const allTests = [
      ...sampleTests.map((t) => ({ ...t, kind: "sample" })),
      ...hiddenTests.map((t) => ({ ...t, kind: "hidden" })),
    ];

    let passed = 0;
    let hiddenPassed = 0;
    const details = [];

    for (const t of allTests) {
      const result = await submitToJudge0({
        code,
        languageId: languageMap[language],
        stdin: t.input,
        expectedOutput: t.output,
      });
      const ok = result.status?.id === 3;
      if (ok) passed += 1;
      if (ok && t.kind === "hidden") hiddenPassed += 1;
      details.push({ kind: t.kind, ok, status: result.status?.description || "Unknown" });
    }

    const correctness = allTests.length ? (passed / allTests.length) * 100 : 0;
    const performance = 70;

    return res.json({
      passed,
      total: allTests.length,
      hiddenPassed,
      correctness,
      performance,
      details,
    });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
});

app.listen(port, () => {
  console.log(`judge service running on ${port}`);
});
