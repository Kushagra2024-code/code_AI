import express from "express";
import type { Request, Response } from "express";

import {
  aiInterviewerFlow,
  codeFeedbackFlow,
  questionGenerationFlow,
  systemDesignEvaluationFlow,
} from "./index";

const app = express();
app.use(express.json({ limit: "1mb" }));

app.get("/health", (_req: Request, res: Response) => {
  res.json({ ok: true });
});

app.post("/questionGenerationFlow", async (req: Request, res: Response) => {
  try {
    const output = await questionGenerationFlow(req.body);
    res.json(output);
  } catch (e) {
    res.status(500).json({ error: e instanceof Error ? e.message : "Unknown error" });
  }
});

app.post("/codeFeedbackFlow", async (req: Request, res: Response) => {
  try {
    const output = await codeFeedbackFlow(req.body);
    res.json(output);
  } catch (e) {
    res.status(500).json({ error: e instanceof Error ? e.message : "Unknown error" });
  }
});

app.post("/systemDesignEvaluationFlow", async (req: Request, res: Response) => {
  try {
    const output = await systemDesignEvaluationFlow(req.body);
    res.json(output);
  } catch (e) {
    res.status(500).json({ error: e instanceof Error ? e.message : "Unknown error" });
  }
});

app.post("/aiInterviewerFlow", async (req: Request, res: Response) => {
  try {
    const output = await aiInterviewerFlow(req.body);
    res.json(output);
  } catch (e) {
    res.status(500).json({ error: e instanceof Error ? e.message : "Unknown error" });
  }
});

const port = Number(process.env.PORT || 3400);
app.listen(port, () => {
  console.log(`genkit flow server running on ${port}`);
});
