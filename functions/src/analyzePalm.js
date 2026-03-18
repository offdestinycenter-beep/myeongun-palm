const fetch = require("node-fetch");

// Gemini 프롬프트 생성 함수 — handType에 따라 프롬프트 조정
function buildPalmReadingPrompt(handType) {
  let handContext;
  if (handType === "left") {
    handContext = "이 사진은 왼손입니다. 왼손은 선천적 운명과 타고난 잠재력을 나타냅니다.";
  } else {
    handContext = "이 사진은 오른손입니다. 오른손은 후천적 노력과 현재의 운세를 나타냅니다.";
  }

  return `당신은 전문 손금 분석가입니다. 제공된 손바닥 이미지를 분석하여 손금을 해석해주세요.

${handContext}

반드시 아래 JSON 형식으로만 응답해주세요. 다른 텍스트는 포함하지 마세요.

{
  "success": true,
  "lines": {
    "life_line": {
      "name": "생명선",
      "description": "생명선에 대한 상세 해석 (3~5문장)"
    },
    "heart_line": {
      "name": "감정선",
      "description": "감정선에 대한 상세 해석 (3~5문장)"
    },
    "fate_line": {
      "name": "운명선",
      "description": "운명선에 대한 상세 해석 (3~5문장)"
    },
    "head_line": {
      "name": "두뇌선",
      "description": "두뇌선에 대한 상세 해석 (3~5문장)"
    }
  },
  "fortune": {
    "love": {
      "name": "연애운",
      "description": "연애운에 대한 상세 해석 (3~5문장)",
      "score": 1
    },
    "wealth": {
      "name": "재물운",
      "description": "재물운에 대한 상세 해석 (3~5문장)",
      "score": 1
    },
    "health": {
      "name": "건강운",
      "description": "건강운에 대한 상세 해석 (3~5문장)",
      "score": 1
    },
    "career": {
      "name": "직업운",
      "description": "직업운에 대한 상세 해석 (3~5문장)",
      "score": 1
    },
    "academic": {
      "name": "학업운",
      "description": "학업운에 대한 상세 해석 (3~5문장)",
      "score": 1
    }
  },
  "summary": "전체적인 손금 종합 해석 (3~5문장)"
}

score는 1~100 사이의 점수이며, 손금의 선 모양, 길이, 깊이 등을 종합적으로 고려하여 산출해주세요.
해석은 긍정적이고 희망적인 톤으로, 한국어로 작성해주세요.
만약 손바닥 이미지가 아니거나 손금을 식별할 수 없는 경우:
{
  "success": false,
  "error": "손바닥을 명확하게 인식할 수 없습니다. 밝은 곳에서 손바닥을 펴고 다시 촬영해주세요."
}`;
}

const API_TIMEOUT = 30 * 1000; // 30초

/**
 * Gemini 3 Flash Preview API를 호출하여 손금 분석
 * @param {string} base64Image - Base64 인코딩된 손바닥 이미지
 * @param {string} apiKey - Gemini API Key
 * @param {string} handType - 손 유형 ("left" 또는 "right", 기본값 "right")
 * @returns {string} Gemini 응답 텍스트
 */
async function callGeminiApi(base64Image, apiKey, handType = "right") {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent?key=${apiKey}`;

  const prompt = buildPalmReadingPrompt(handType);

  const requestBody = {
    contents: [
      {
        parts: [
          { text: prompt },
          {
            inline_data: {
              mime_type: "image/jpeg",
              data: base64Image,
            },
          },
        ],
      },
    ],
    generationConfig: {
      temperature: 0.7,
      maxOutputTokens: 4096,
    },
  };

  // AbortController 기반 타임아웃
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), API_TIMEOUT);

  try {
    const response = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(requestBody),
      signal: controller.signal,
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Gemini API 호출 실패: ${response.status}`);
    }

    const data = await response.json();

    // 응답에서 텍스트 추출
    const textContent =
      data.candidates &&
      data.candidates[0] &&
      data.candidates[0].content &&
      data.candidates[0].content.parts &&
      data.candidates[0].content.parts[0] &&
      data.candidates[0].content.parts[0].text;

    if (!textContent) {
      throw new Error("Gemini API 응답에서 텍스트를 찾을 수 없습니다.");
    }

    return textContent;
  } catch (error) {
    if (error.name === "AbortError") {
      throw new Error("Gemini API 요청 시간이 초과되었습니다.");
    }
    throw error;
  } finally {
    clearTimeout(timeoutId);
  }
}

/**
 * Gemini 응답 텍스트에서 JSON을 추출하여 파싱
 * @param {string} text - Gemini 응답 텍스트
 * @returns {object} 파싱된 JSON 객체
 */
function parseGeminiResponse(text) {
  // JSON 블록 추출 (```json ... ``` 또는 순수 JSON)
  let jsonStr = text;

  // 코드 블록에서 JSON 추출
  const codeBlockMatch = text.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (codeBlockMatch) {
    jsonStr = codeBlockMatch[1].trim();
  } else {
    // 중괄호로 시작하는 JSON 추출
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      jsonStr = jsonMatch[0];
    }
  }

  return JSON.parse(jsonStr);
}

module.exports = { callGeminiApi, parseGeminiResponse, buildPalmReadingPrompt };
