const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { callGeminiApi, parseGeminiResponse } = require("./src/analyzePalm");

// Firebase Admin 초기화
admin.initializeApp();

// Gemini API Key는 functions/.env 파일로 관리 (process.env.GEMINI_API_KEY)

// --- Rate Limiting (Firestore 기반) ---
const RATE_LIMIT_WINDOW = 60 * 1000; // 1분
const RATE_LIMIT_MAX = 5; // IP당 최대 5회

async function checkRateLimit(ip) {
  const db = admin.firestore();
  const docRef = db.collection("rate_limits").doc(ip);
  const now = Date.now();

  try {
    const result = await db.runTransaction(async (transaction) => {
      const doc = await transaction.get(docRef);

      if (!doc.exists) {
        transaction.set(docRef, { count: 1, windowStart: now });
        return true;
      }

      const data = doc.data();

      // 윈도우 만료 시 리셋
      if (now - data.windowStart > RATE_LIMIT_WINDOW) {
        transaction.update(docRef, { count: 1, windowStart: now });
        return true;
      }

      // 제한 초과
      if (data.count >= RATE_LIMIT_MAX) {
        return false;
      }

      // 카운트 증가
      transaction.update(docRef, { count: data.count + 1 });
      return true;
    });

    return result;
  } catch (error) {
    console.error("Rate limit check 실패:", error.message);
    // Firestore 오류 시 요청 허용 (서비스 가용성 우선)
    return true;
  }
}

// --- 입력 검증 ---
const MAX_IMAGE_SIZE = 7 * 1024 * 1024; // ~5MB 원본 → Base64 ~6.7MB
const BASE64_REGEX = /^[A-Za-z0-9+/\n\r]+=*$/;

function validateImageInput(image) {
  if (!image || typeof image !== "string") {
    return "이미지 데이터가 없습니다.";
  }
  if (image.length > MAX_IMAGE_SIZE) {
    return "이미지 크기가 너무 큽니다. (최대 5MB)";
  }
  if (!BASE64_REGEX.test(image)) {
    return "유효하지 않은 이미지 형식입니다.";
  }
  return null;
}

// --- 보안 헤더 ---
function setSecurityHeaders(res) {
  res.set("X-Content-Type-Options", "nosniff");
  res.set("X-Frame-Options", "DENY");
}

// --- CORS (모바일 앱 허용, 웹 Origin 제한) ---
const ALLOWED_ORIGINS = []; // 필요 시 허용할 웹 Origin 추가

function handleCors(req, res) {
  const origin = req.headers.origin;

  if (!origin) {
    // 모바일 앱은 Origin 헤더가 없음 → 허용
    res.set("Access-Control-Allow-Origin", "*");
  } else if (ALLOWED_ORIGINS.length > 0 && ALLOWED_ORIGINS.includes(origin)) {
    res.set("Access-Control-Allow-Origin", origin);
  } else if (ALLOWED_ORIGINS.length === 0) {
    // 허용 목록 미설정 시 모든 Origin 허용 (개발 단계)
    res.set("Access-Control-Allow-Origin", origin);
  } else {
    // 허용되지 않은 Origin
    return false;
  }

  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");
  res.set("Access-Control-Max-Age", "3600");
  return true;
}

exports.analyzePalm = functions.https.onRequest(async (req, res) => {
  // 보안 헤더
  setSecurityHeaders(res);

  // CORS
  if (!handleCors(req, res)) {
    res.status(403).json({ success: false, error: "허용되지 않은 요청입니다." });
    return;
  }

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "POST") {
    res.status(405).json({
      success: false,
      error: "POST 메서드만 허용됩니다.",
    });
    return;
  }

  // Content-Type 검증
  const contentType = req.headers["content-type"] || "";
  if (!contentType.includes("application/json")) {
    res.status(415).json({
      success: false,
      error: "Content-Type은 application/json이어야 합니다.",
    });
    return;
  }

  // Rate Limiting (Firestore 기반)
  const clientIp = req.headers["x-forwarded-for"] || req.ip || "unknown";
  const allowed = await checkRateLimit(clientIp);
  if (!allowed) {
    res.status(429).json({
      success: false,
      error: "요청이 너무 많습니다. 잠시 후 다시 시도해주세요.",
    });
    return;
  }

  // 입력 검증
  const { image, handType } = req.body;
  const validationError = validateImageInput(image);
  if (validationError) {
    res.status(400).json({
      success: false,
      error: validationError,
    });
    return;
  }

  // handType 검증 (유효하지 않으면 기본값 "right")
  const validHandType = handType === "left" ? "left" : "right";

  // API Key 가져오기
  const apiKey = process.env.GEMINI_API_KEY;

  if (!apiKey) {
    console.error("Gemini API Key가 설정되지 않았습니다.");
    res.status(500).json({
      success: false,
      error: "서버 설정 오류가 발생했습니다. 잠시 후 다시 시도해주세요.",
    });
    return;
  }

  // 최대 2회 시도 (1회 재시도)
  for (let attempt = 0; attempt < 2; attempt++) {
    try {
      const responseText = await callGeminiApi(image, apiKey, validHandType);
      const result = parseGeminiResponse(responseText);

      res.status(200).json(result);
      return;
    } catch (error) {
      console.error(`분석 시도 ${attempt + 1} 실패:`, error.message);

      if (attempt === 1) {
        res.status(500).json({
          success: false,
          error: "손금 분석에 실패했습니다. 잠시 후 다시 시도해주세요.",
        });
      }
    }
  }
});
