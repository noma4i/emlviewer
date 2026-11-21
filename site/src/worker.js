import { EmailMessage } from "cloudflare:email";

const sender = "feedback@emlviewer.noma4i.com";
const recipient = "noma4i@gmail.com";

function json(data, status = 200) {
  return Response.json(data, { status });
}

function base64(text) {
  const bytes = new TextEncoder().encode(text);
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary);
}

async function feedback(request, env) {
  if (!/^application\/json(?:\s*;|\s*$)/i.test(request.headers.get("content-type") || "")) {
    return json({ ok: false, error: "Expected JSON." }, 415);
  }

  let data;
  try {
    data = await request.json();
  } catch {
    return json({ ok: false, error: "Invalid JSON." }, 400);
  }

  if (!data || typeof data !== "object" || Array.isArray(data)) {
    return json({ ok: false, error: "Invalid feedback." }, 400);
  }
  const { name = "", email = "", version = "", message = "", website = "" } = data;
  if (
    [name, email, version, message, website].some((value) => typeof value !== "string") ||
    name.length > 100 ||
    version.length > 40 ||
    website !== "" ||
    message.trim().length < 1 ||
    message.length > 5000 ||
    (email !== "" && (email.length > 254 || !/^[^\s@<>\x00-\x1f]+@[^\s@<>\x00-\x1f]+\.[^\s@<>\x00-\x1f]+$/.test(email)))
  ) {
    return json({ ok: false, error: "Please check the feedback fields." }, 400);
  }

  const subject = `EMLViewer feedback: ${Array.from(message.trim()).slice(0, 60).join("")}`;
  const body = `Name: ${name}\nEmail: ${email}\nApp version: ${version}\n\n${message}`;
  const encodedBody = base64(body)
    .match(/.{1,76}/g)
    .join("\r\n");
  const subjectWords = Array.from(subject)
    .reduce((chunks, char) => {
      if (!chunks.length || new TextEncoder().encode(chunks[chunks.length - 1] + char).length > 42) chunks.push("");
      chunks[chunks.length - 1] += char;
      return chunks;
    }, [])
    .map((chunk) => `=?UTF-8?B?${base64(chunk)}?=`)
    .join("\r\n ");
  const headers = [
    `From: ${sender}`,
    `To: ${recipient}`,
    ...(email ? [`Reply-To: ${email}`] : []),
    `Date: ${new Date().toUTCString()}`,
    `Message-ID: <${crypto.randomUUID()}@emlviewer.noma4i.com>`,
    `Subject: ${subjectWords}`,
    "MIME-Version: 1.0",
    "Content-Type: text/plain; charset=UTF-8",
    "Content-Transfer-Encoding: base64",
  ];

  try {
    await env.FEEDBACK.send(new EmailMessage(sender, recipient, `${headers.join("\r\n")}\r\n\r\n${encodedBody}\r\n`));
    return json({ ok: true });
  } catch {
    return json({ ok: false, error: "Unable to send feedback." }, 500);
  }
}

export default {
  fetch(request, env) {
    if (request.method === "POST" && new URL(request.url).pathname === "/api/feedback") {
      return feedback(request, env);
    }
    return env.ASSETS.fetch(request);
  },
};
