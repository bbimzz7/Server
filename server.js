const WebSocket = require("ws");

const PORT = process.env.PORT || 8080;
const wss  = new WebSocket.Server({ port: PORT });

const clients = new Map(); // ws -> { username, room }

function broadcastToRoom(room, data, excludeWs) {
    const msg = JSON.stringify(data);
    for (const [ws, info] of clients) {
        if (ws === excludeWs) continue;
        if (info.room !== room) continue;
        if (ws.readyState === WebSocket.OPEN) ws.send(msg);
    }
}

function broadcastToAll(room, data) {
    const msg = JSON.stringify(data);
    for (const [ws, info] of clients) {
        if (info.room !== room) continue;
        if (ws.readyState === WebSocket.OPEN) ws.send(msg);
    }
}

wss.on("connection", (ws) => {
    console.log("[+] connected. total:", wss.clients.size);

    ws.on("message", (raw) => {
        let data;
        try { data = JSON.parse(raw); } catch { return; }

        if (data.type === "join") {
            const username = String(data.username || "Unknown").slice(0, 32);
            const room     = String(data.room || "global").slice(0, 64);
            clients.set(ws, { username, room });

            broadcastToRoom(room, { type: "system", msg: username + " bergabung." }, ws);

            const online = [...clients.values()]
                .filter(c => c.room === room)
                .map(c => c.username);
            ws.send(JSON.stringify({ type: "online", users: online }));

            console.log("[join]", username, "->", room.slice(0, 12));

        } else if (data.type === "leave") {
            // client mau pindah room, broadcast keluar ke room lama
            const client = clients.get(ws);
            if (client) {
                broadcastToRoom(client.room, {
                    type: "system",
                    msg: client.username + " keluar."
                }, ws);
                console.log("[leave]", client.username, "from", client.room.slice(0, 12));
            }
            // hapus dari map, koneksi ws masih hidup tapi akan join ulang
            clients.delete(ws);

        } else if (data.type === "chat") {
            const client = clients.get(ws);
            if (!client) return;
            const msg = String(data.msg || "").slice(0, 200);
            if (!msg.trim()) return;

            broadcastToAll(client.room, {
                type:     "chat",
                username: client.username,
                msg:      msg,
                time:     new Date().toISOString(),
            });

            console.log("[" + client.room.slice(0, 8) + "]", client.username, ":", msg);
        }
    });

    ws.on("close", () => {
        const client = clients.get(ws);
        if (client) {
            broadcastToRoom(client.room, {
                type: "system",
                msg: client.username + " keluar."
            }, ws);
            console.log("[-]", client.username);
        }
        clients.delete(ws);
    });

    ws.on("error", (err) => {
        console.error("[ws error]", err.message);
        clients.delete(ws);
    });
});

console.log("VH Chat Server running on port", PORT);
