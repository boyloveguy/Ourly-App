def test_voice_tts_endpoint(client):
    res = client.get("/v1/voice/tts?text=Chào+Bé+Chó")
    assert res.status_code == 200
    assert res.headers.get("content-type") == "audio/mpeg"
    assert len(res.content) > 1000
