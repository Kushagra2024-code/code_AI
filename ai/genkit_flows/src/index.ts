import { z } from "zod";
import { configureGenkit, defineFlow } from "genkit";
import { googleAI } from "@genkit-ai/googleai";

configureGenkit({
  plugins: [googleAI({ apiKey: process.env.GEMINI_API_KEY })],
  model: googleAI.model("gemini-1.5-flash"),
});

export const questionGenerationFlow = defineFlow(
  {
    name: "questionGenerationFlow",
    inputSchema: z.object({ difficulty: z.string(), tags: z.array(z.string()) }),
    outputSchema: z.object({
      title: z.string(),
      difficulty: z.string(),
      tags: z.array(z.string()),
      statement: z.string(),
      constraints: z.array(z.string()),
      examples: z.array(z.object({ input: z.string(), output: z.string() })),
      hiddenTests: z.array(z.object({ input: z.string(), output: z.string() })),
    }),
  },
  async (input, { ai }) => {
    const prompt = `Generate a competitive programming problem with constraints, examples and hidden test cases. Difficulty=${input.difficulty}. Tags=${input.tags.join(",")}. Return strict JSON.`;
    const result = await ai.generate({ prompt });
    return JSON.parse(result.text);
  }
);

export const codeFeedbackFlow = defineFlow(
  {
    name: "codeFeedbackFlow",
    inputSchema: z.object({ code: z.string(), language: z.string(), problem: z.string() }),
    outputSchema: z.object({
      timeComplexity: z.string(),
      memoryComplexity: z.string(),
      readability: z.number(),
      smells: z.array(z.string()),
      edgeCases: z.array(z.string()),
      suggestions: z.array(z.string()),
    }),
  },
  async (input, { ai }) => {
    const prompt = `Analyze this ${input.language} solution for problem: ${input.problem}. Return strict JSON with complexity, readability score, smells, edge cases, suggestions. Code:\n${input.code}`;
    const result = await ai.generate({ prompt });
    return JSON.parse(result.text);
  }
);

export const systemDesignEvaluationFlow = defineFlow(
  {
    name: "systemDesignEvaluationFlow",
    inputSchema: z.object({ question: z.string(), diagram: z.any() }),
    outputSchema: z.object({
      score: z.number(),
      scalability: z.string(),
      faultTolerance: z.string(),
      databaseDesign: z.string(),
      caching: z.string(),
      improvements: z.array(z.string()),
    }),
  },
  async (input, { ai }) => {
    const prompt = `Evaluate this system design answer for: ${input.question}. Diagram JSON: ${JSON.stringify(input.diagram)}. Score out of 100 and provide improvement list. Return strict JSON.`;
    const result = await ai.generate({ prompt });
    return JSON.parse(result.text);
  }
);

export const aiInterviewerFlow = defineFlow(
  {
    name: "aiInterviewerFlow",
    inputSchema: z.object({ stage: z.string(), context: z.string() }),
    outputSchema: z.object({ message: z.string(), followUps: z.array(z.string()) }),
  },
  async (input, { ai }) => {
    const prompt = `You are a technical interviewer. Stage=${input.stage}. Context=${input.context}. Ask interview-quality clarifying and optimization questions. Return strict JSON.`;
    const result = await ai.generate({ prompt });
    return JSON.parse(result.text);
  }
);
