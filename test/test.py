import base64
from openai import OpenAI

client = OpenAI(base_url="https://council-ensure-broad-extended.trycloudflare.com/v1", api_key="APNI-SECRET-KEY")
b64 = lambda p: base64.b64encode(open(p, "rb").read()).decode()

# image
r = client.chat.completions.create(model="gemma-3n-E2B-it", messages=[{
    "role": "user", "content": [
        {"type": "text", "text": "Is image mein kya hai?"},
        {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64," + b64("test/test.jpeg")}}]}])
print(r.choices[0].message.content)

# audio (wav)
r = client.chat.completions.create(model="gemma-3n-E2B-it", messages=[{
    "role": "user", "content": [
        {"type": "text", "text": "Transcribe this audio."},
        {"type": "input_audio", "input_audio": {"data": b64("test/test.wav"), "format": "wav"}}]}])
print(r.choices[0].message.content)