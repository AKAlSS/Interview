import { OpenAIApi, Configuration } from 'openai';

class AnswerGenerator {
  private openai: OpenAIApi;
  private context: string[] = [];
  
  constructor(apiKey: string) {
    const configuration = new Configuration({ apiKey });
    this.openai = new OpenAIApi(configuration);
  }
  
  async generateTechnicalAnswer(question: string, analysis: any): Promise<string> {
    // Update context with the new question
    this.context.push(`Interviewer: ${question}`);
    
    // Craft prompt based on analysis
    const prompt = this.createPrompt(question, analysis);
    
    try {
      const response = await this.openai.createChatCompletion({
        model: "gpt-4",
        messages: [
          {
            role: "system",
            content: "You are an expert Senior UX Developer in an interview. Provide concise, accurate, and impressive answers."
          },
          { role: "user", content: prompt }
        ],
        max_tokens: 500,
        temperature: 0.7
      });
      
      const answer = response.data.choices[0].message?.content || "I'm not sure about this question.";
      
      // Update context with the answer
      this.context.push(`My Answer: ${answer}`);
      
      return answer;
    } catch (error) {
      console.error("Error generating answer:", error);
      return "Sorry, I couldn't generate a response for this question.";
    }
  }
  
  async generateCodeWithExplanation(question: string): Promise<{code: string, explanation: string}> {
    try {
      const response = await this.openai.createChatCompletion({
        model: "gpt-4",
        messages: [
          {
            role: "system",
            content: "You are an expert Senior UX Developer. Write clean, efficient code with line-by-line explanations."
          },
          { 
            role: "user", 
            content: `Write code for the following task and provide a line-by-line explanation: ${question}` 
          }
        ],
        max_tokens: 1000,
        temperature: 0.5
      });
      
      const result = response.data.choices[0].message?.content || "";
      
      // Parse code and explanation from the result
      const codeMatch = result.match(/```(?:javascript|js|html|css|typescript|ts)([\s\S]*?)```/);
      const code = codeMatch ? codeMatch[1].trim() : "";
      
      // Everything outside the code blocks is considered explanation
      const explanation = result.replace(/```(?:javascript|js|html|css|typescript|ts)[\s\S]*?```/g, "").trim();
      
      return { code, explanation };
    } catch (error) {
      console.error("Error generating code:", error);
      return { 
        code: "// Error generating code", 
        explanation: "Sorry, I couldn't generate code for this question." 
      };
    }
  }
  
  private createPrompt(question: string, analysis: any): string {
    // Create a tailored prompt based on the question analysis
    let prompt = `Answer this ${analysis.question_type} question for a Senior UX Developer interview: "${question}"`;
    
    if (analysis.keywords_detected.length > 0) {
      prompt += `\nFocus on these key concepts: ${analysis.keywords_detected.join(", ")}`;
    }
    
    // Add context from previous Q&A for continuity
    if (this.context.length > 0) {
      prompt += "\n\nInterview context so far:\n" + this.context.slice(-6).join("\n");
    }
    
    return prompt;
  }
  
  // Clear context at the end of the interview
  clearContext(): void {
    this.context = [];
  }
} 