def test_chat_history_persistence_flow(client):
    # 1. Initially chat history may be empty
    res = client.get("/v1/chat/history")
    assert res.status_code == 200
    data = res.json()
    assert "messages" in data

    # 2. Send a message to chat
    send_res = client.post("/v1/chat", json={
        "message": "Gợi ý hẹn hò cuối tuần này",
        "history": []
    })
    assert send_res.status_code == 200
    reply_data = send_res.json()
    assert "reply" in reply_data

    # 3. Check history contains both user message and AI response
    res_after = client.get("/v1/chat/history")
    assert res_after.status_code == 200
    after_msgs = res_after.json()["messages"]
    assert len(after_msgs) >= 2
    assert after_msgs[-2]["isUser"] is True
    assert after_msgs[-2]["text"] == "Gợi ý hẹn hò cuối tuần này"
    assert after_msgs[-1]["isUser"] is False

    # 4. Clear chat history
    del_res = client.delete("/v1/chat/history")
    assert del_res.status_code == 200

    # 5. History should now be empty
    res_cleared = client.get("/v1/chat/history")
    assert res_cleared.status_code == 200
    assert len(res_cleared.json()["messages"]) == 0
