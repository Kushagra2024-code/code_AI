import { genkit, z } from "genkit";
import { googleAI } from "@genkit-ai/google-genai";

const ai = genkit({
  plugins: [googleAI({ apiKey: process.env.GEMINI_API_KEY })],
  model: googleAI.model("gemini-2.5-flash"),
});

const QuestionSchema = z.object({
  title: z.string(),
  difficulty: z.string(),
  tags: z.array(z.string()),
  statement: z.string(),
  constraints: z.array(z.string()),
  examples: z.array(z.object({ input: z.string(), output: z.string() })),
  hiddenTests: z.array(z.object({ input: z.string(), output: z.string() })),
});

const FeedbackSchema = z.object({
  timeComplexity: z.string(),
  memoryComplexity: z.string(),
  readability: z.number(),
  smells: z.array(z.string()),
  edgeCases: z.array(z.string()),
  suggestions: z.array(z.string()),
});

const DesignEvalSchema = z.object({
  score: z.number(),
  scalability: z.string(),
  faultTolerance: z.string(),
  databaseDesign: z.string(),
  caching: z.string(),
  improvements: z.array(z.string()),
});

const InterviewMessageSchema = z.object({
  message: z.string(),
  followUps: z.array(z.string()),
});

export const questionGenerationFlow = ai.defineFlow(
  {
    name: "questionGenerationFlow",
    inputSchema: z.object({ difficulty: z.string(), tags: z.array(z.string()) }),
    outputSchema: QuestionSchema,
  },
  async (input) => {
    const prompt = `Generate a competitive programming problem with constraints, examples and hidden test cases. Difficulty=${input.difficulty}. Tags=${input.tags.join(",")}.`;
    const { output } = await ai.generate({ prompt, output: { schema: QuestionSchema } });
    if (!output) throw new Error("Failed to generate question");
    return output;
  }
);

export const codeFeedbackFlow = ai.defineFlow(
  {
    name: "codeFeedbackFlow",
    inputSchema: z.object({ code: z.string(), language: z.string(), problem: z.string() }),
    outputSchema: FeedbackSchema,
  },
  async (input) => {
    const prompt = `Analyze this ${input.language} solution for problem: ${input.problem}. Return complexity, readability score (0-100), smells, edge cases, and suggestions.`;
    const { output } = await ai.generate({
      prompt: `${prompt}\n\nCode:\n${input.code}`,
      output: { schema: FeedbackSchema },
    });
    if (!output) throw new Error("Failed to generate feedback");
    return output;
  }
);

export const systemDesignEvaluationFlow = ai.defineFlow(
  {
    name: "systemDesignEvaluationFlow",
    inputSchema: z.object({ question: z.string(), diagram: z.any() }),
    outputSchema: DesignEvalSchema,
  },
  async (input) => {
    const prompt = `Evaluate this system design answer for: ${input.question}. Diagram JSON: ${JSON.stringify(input.diagram)}. Score out of 100 and provide improvements.`;
    const { output } = await ai.generate({ prompt, output: { schema: DesignEvalSchema } });
    if (!output) throw new Error("Failed to evaluate design");
    return output;
  }
);

export const aiInterviewerFlow = ai.defineFlow(
  {
    name: "aiInterviewerFlow",
    inputSchema: z.object({ stage: z.string(), context: z.string() }),
    outputSchema: InterviewMessageSchema,
  },
  async (input) => {
    const prompt = `You are a technical interviewer. Stage=${input.stage}. Context=${input.context}. Ask interview-quality clarifying and optimization questions.`;
    const { output } = await ai.generate({ prompt, output: { schema: InterviewMessageSchema } });
    if (!output) throw new Error("Failed to generate interviewer response");
    return output;
  }
);
