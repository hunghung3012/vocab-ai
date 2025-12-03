import google.generativeai as genai
from fastapi import FastAPI, UploadFile, File, Form
from fastapi.responses import StreamingResponse

genai.configure(api_key="AIzaSyBp7HgX3kWpxFbYRofDCMpLol8P0u92Gd8")

app = FastAPI()

# =====================================
# TEXT STREAM – dùng gemini-pro
# =====================================
@app.post("/chat")
async def chat(message: str = Form(...)):
    model = genai.GenerativeModel("gemini-2.5-flash")

    async def event_stream():
        try:
            stream = model.generate_content(message, stream=True)
            for chunk in stream:
                if chunk.text:
                    # thêm xuống dòng để tránh Android đóng kết nối
                    yield (chunk.text + "\n").encode("utf-8")
        except Exception as e:
            yield f"[ERROR STREAM] {str(e)}\n".encode("utf-8")

    return StreamingResponse(event_stream(), media_type="text/plain")


# =====================================
# IMAGE STREAM – dùng gemini-pro-vision
# =====================================
@app.post("/vision")
async def vision(prompt: str = Form(...), image: UploadFile = File(...)):
    img = await image.read()

    model = genai.GenerativeModel("gemini-2.5-flash")

    async def event_stream():
        try:
            stream = model.generate_content(
                [prompt, {"mime_type": "image/jpeg", "data": img}],
                stream=True
            )
            for chunk in stream:
                if chunk.text:
                    yield (chunk.text + "\n").encode("utf-8")
        except Exception as e:
            yield f"[ERROR STREAM] {str(e)}\n".encode("utf-8")

    return StreamingResponse(event_stream(), media_type="text/plain")
