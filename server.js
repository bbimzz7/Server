const WebSocket = require("ws");

const PORT = process.env.PORT || 8080;
const wss = new WebSocket.Server({ port: PORT });

const clients = new Map();

function broadcast(data, excludeWs) {
    const msg = JSON.stringify(data);
    for (const [ws] of clients) {
        if (ws !== excludeWs && ws.readyState === WebSocket.OPEN) {
            ws.send(msg);
        }
    }
}

wss.on("connection", (ws) => {
    console.log("[+] Client connected. Total:", wss.clients.size);

    ws.on("message", (raw) => {
        let data;
        try { data = JSON.parse(raw); } catch { return; }

        if (data.type === "join") {
            const username = String(data.username || "Unknown").slice(0, 32);
            clients.set(ws, { username });
            broadcast({ type: "system", msg: username + " bergabung ke chat." }, ws);
            const online = [...clients.values()].map(c => c.username);
            ws.send(JSON.stringify({ type: "online", users: online }));
            console.log("[join]", username);

        } else if (data.type === "chat") {
            const client = clients.get(ws);
            if (!client) return;
            const msg = String(data.msg || "").slice(0, 200);
            if (!msg.trim()) return;
            const payload = JSON.stringify({
                type: "chat",
                username: client.username,
                msg: msg,
                time: new Date().toISOString(),
            });
            for (const [w] of clients) {
                if (w.readyState === WebSocket.OPEN) w.send(payload);
            }
            console.log("[chat]", client.username, ":", msg);
        }
    });

    ws.on("close", () => {
        const client = clients.get(ws);
        if (client) {
            broadcast({ type: "system", msg: client.username + " keluar." }, ws);
            console.log("[-]", client.username, "disconnected");
        }
        clients.delete(ws);
    });

    ws.on("error", (err) => {
        console.error("[ws error]", err.message);
        clients.delete(ws);
    });
});

console.log("VH Chat Server running on port", PORT);

