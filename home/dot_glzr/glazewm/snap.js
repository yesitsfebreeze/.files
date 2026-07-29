#!/usr/bin/env node
// GlazeWM snap — put the focused window at an absolute screen zone. GlazeWM keybindings
// can only pass a fixed `set-floating --x-pos/--y-pos/--width/--height`, and those numbers
// depend on which monitor owns the window, so the arithmetic lives here: query the focused
// window, find its monitor, compute the zone rect inside that monitor's working area, then
// send one set-floating. Gaps match config.yaml.tmpl (outer 8px sides/bottom, top already
// inside the Zebar window; inner 8px between zones) so a snapped window lines up with tiles.
// Zero-dependency (Node >=21, global WebSocket); launched fire-and-forget by the keybinding.
//
// Usage: node snap.js <zone>
//   tl tr bl br   quadrants
//   lh rh th bh   halves
//   full          whole working area

const PORT = 6123;
const GAP = 8;
const zone = (process.argv[2] || "").toLowerCase();

const ZONES = new Set(["tl", "tr", "bl", "br", "lh", "rh", "th", "bh", "full"]);
if (!ZONES.has(zone)) process.exit(0);

const pending = new Map();

function send(message) {
	return new Promise((resolve, reject) => {
		let key = message;
		while (pending.has(key)) key += " ";
		const timer = setTimeout(() => {
			pending.delete(key);
			reject(new Error("timeout"));
		}, 4000);
		pending.set(key, { resolve, reject, timer });
		ws.send(key);
	});
}

// The monitor that owns the window is the one containing its center point. Falling back to
// the first monitor keeps a window with a stale rect snappable instead of silently ignored.
function monitorFor(monitors, win) {
	const cx = win.x + win.width / 2;
	const cy = win.y + win.height / 2;
	return (
		monitors.find(
			(m) =>
				cx >= m.x && cx < m.x + m.width && cy >= m.y && cy < m.y + m.height,
		) || monitors[0]
	);
}

// Working area minus outer gaps: the box every zone is carved out of. workingRect.top is
// already below the bar (the bar docks to the edge), so no top gap is subtracted here —
// same reasoning as outer_gap.top: '0px' in the config.
function areaOf(mon) {
	const r = mon.workingRect || {
		left: mon.x,
		top: mon.y,
		right: mon.x + mon.width,
		bottom: mon.y + mon.height,
	};
	return {
		x: r.left + GAP,
		y: r.top,
		w: r.right - r.left - GAP * 2,
		h: r.bottom - r.top - GAP,
	};
}

function rectFor(area) {
	const halfW = Math.floor((area.w - GAP) / 2);
	const halfH = Math.floor((area.h - GAP) / 2);
	const rightX = area.x + area.w - halfW;
	const bottomY = area.y + area.h - halfH;

	switch (zone) {
		case "tl":
			return { x: area.x, y: area.y, w: halfW, h: halfH };
		case "tr":
			return { x: rightX, y: area.y, w: halfW, h: halfH };
		case "bl":
			return { x: area.x, y: bottomY, w: halfW, h: halfH };
		case "br":
			return { x: rightX, y: bottomY, w: halfW, h: halfH };
		case "lh":
			return { x: area.x, y: area.y, w: halfW, h: area.h };
		case "rh":
			return { x: rightX, y: area.y, w: halfW, h: area.h };
		case "th":
			return { x: area.x, y: area.y, w: area.w, h: halfH };
		case "bh":
			return { x: area.x, y: bottomY, w: area.w, h: halfH };
		default:
			return { x: area.x, y: area.y, w: area.w, h: area.h };
	}
}

const ws = new WebSocket(`ws://localhost:${PORT}`);

ws.addEventListener("error", () => process.exit(0));

ws.addEventListener("message", (ev) => {
	let msg;
	try {
		msg = JSON.parse(
			typeof ev.data === "string" ? ev.data : ev.data.toString(),
		);
	} catch {
		return;
	}
	if (msg.messageType !== "client_response") return;
	const entry = pending.get(msg.clientMessage);
	if (!entry) return;
	pending.delete(msg.clientMessage);
	clearTimeout(entry.timer);
	if (msg.success) entry.resolve(msg.data);
	else entry.reject(new Error(msg.error || "command failed"));
});

ws.addEventListener("open", async () => {
	try {
		const [focusedData, monitorData] = await Promise.all([
			send("query focused"),
			send("query monitors"),
		]);
		const win = focusedData && focusedData.focused;
		if (!win || win.type !== "window") return;
		const monitors = (monitorData && monitorData.monitors) || [];
		if (!monitors.length) return;

		const r = rectFor(areaOf(monitorFor(monitors, win)));
		await send(
			`command --id ${win.id} set-floating --x-pos ${r.x} --y-pos ${r.y}` +
				` --width ${r.w} --height ${r.h}`,
		);
	} catch {
		// best-effort; a failed snap leaves the window exactly as it was
	} finally {
		try {
			ws.close();
		} catch {}
		process.exit(0);
	}
});
