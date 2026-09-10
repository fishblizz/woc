import crypto from "node:crypto";
import fs from "node:fs/promises";
import path from "node:path";
import express from "express";
import mysql from "mysql2/promise";

const app = express();
const port = Number(process.env.PORT || 3000);
const downloadDir = process.env.DOWNLOAD_DIR || "/downloads";

const db = mysql.createPool({
  host: process.env.DB_HOST || "ac-database",
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || "root",
  password: process.env.DB_PASSWORD,
  database: process.env.AUTH_DB || "acore_auth",
  waitForConnections: true,
  connectionLimit: 6,
  namedPlaceholders: true
});

app.set("view engine", "ejs");
app.set("views", path.join(process.cwd(), "src", "views"));
app.use(express.urlencoded({ extended: false }));
app.use(express.static(path.join(process.cwd(), "public"), {
  maxAge: "1h",
  etag: true
}));

const REALM_NAME = process.env.REALM_NAME || "Zwarteweg";
const LAN_IP = process.env.LAN_IP || "127.0.0.1";
const PUBLIC_HOST = process.env.PUBLIC_HOST || LAN_IP;
const PORTAL_PUBLIC_URL = process.env.PORTAL_PUBLIC_URL || "";
const WORLD_PORT = process.env.WORLD_PORT || "8085";
const AUTH_PORT = process.env.AUTH_PORT || "3724";
const EMPTY_STATUS = {
  realms: [],
  accountCount: 0,
  characterCount: 0,
  auctionCount: 0,
  factionCounts: { alliance: 0, horde: 0 },
  auctionHouseCounts: { alliance: 0, horde: 0, neutral: 0 }
};

function sha1(...chunks) {
  const hash = crypto.createHash("sha1");
  for (const chunk of chunks) hash.update(chunk);
  return hash.digest();
}

function bigintFromLittleEndian(buffer) {
  let value = 0n;
  for (let i = buffer.length - 1; i >= 0; i -= 1) {
    value = (value << 8n) + BigInt(buffer[i]);
  }
  return value;
}

function littleEndianFromBigint(value, length) {
  const out = Buffer.alloc(length);
  let remaining = value;
  for (let i = 0; i < length; i += 1) {
    out[i] = Number(remaining & 0xffn);
    remaining >>= 8n;
  }
  return out;
}

function modPow(base, exponent, modulus) {
  let result = 1n;
  let b = base % modulus;
  let e = exponent;
  while (e > 0n) {
    if (e & 1n) result = (result * b) % modulus;
    e >>= 1n;
    b = (b * b) % modulus;
  }
  return result;
}

function makeRegistrationData(username, password) {
  const salt = crypto.randomBytes(32);
  const identityHash = sha1(`${username}:${password}`);
  const x = bigintFromLittleEndian(sha1(salt, identityHash));
  const n = BigInt("0x894B645E89E1535BBDAD5B8B290650530801B18EBFBF5E8FAB3C82872A3E9BB7");
  const verifier = littleEndianFromBigint(modPow(7n, x, n), 32);
  return { salt, verifier };
}

function normalizeAccountInput(username, password, email) {
  const cleanName = String(username || "").trim().toUpperCase();
  const cleanPass = String(password || "").trim().toUpperCase();
  const cleanEmail = String(email || "").trim().toUpperCase();

  if (!/^[A-Z0-9_.-]{3,32}$/.test(cleanName)) {
    throw new Error("Accountnaam: 3-32 tekens, alleen letters, cijfers, punt, streepje of underscore.");
  }

  if (cleanPass.length < 4 || cleanPass.length > 16) {
    throw new Error("Wachtwoord: 4-16 tekens. WoW 3.3.5a accepteert maximaal 16.");
  }

  if (cleanEmail && cleanEmail.length > 255) {
    throw new Error("E-mailadres is te lang.");
  }

  return { cleanName, cleanPass, cleanEmail };
}

async function getStatus() {
  const [realms] = await db.query(
    "SELECT id, name, address, port, icon, flag, population FROM realmlist ORDER BY id LIMIT 5"
  );
  const [accounts] = await db.query("SELECT COUNT(*) total FROM account");
  const [characters] = await db.query(
    "SELECT COUNT(*) total FROM acore_characters.characters"
  );
  const [factions] = await db.query(
    `SELECT
       SUM(CASE WHEN race IN (1, 3, 4, 7, 11) THEN 1 ELSE 0 END) alliance,
       SUM(CASE WHEN race IN (2, 5, 6, 8, 10) THEN 1 ELSE 0 END) horde
     FROM acore_characters.characters`
  );
  const [auctions] = await db.query("SELECT COUNT(*) total FROM acore_characters.auctionhouse");
  const [auctionHouses] = await db.query(
    `SELECT
       SUM(CASE WHEN houseid = 2 THEN 1 ELSE 0 END) alliance,
       SUM(CASE WHEN houseid = 6 THEN 1 ELSE 0 END) horde,
       SUM(CASE WHEN houseid = 7 THEN 1 ELSE 0 END) neutral
     FROM acore_characters.auctionhouse`
  );

  return {
    realms,
    accountCount: accounts[0]?.total || 0,
    characterCount: characters[0]?.total || 0,
    auctionCount: auctions[0]?.total || 0,
    factionCounts: {
      alliance: Number(factions[0]?.alliance || 0),
      horde: Number(factions[0]?.horde || 0)
    },
    auctionHouseCounts: {
      alliance: Number(auctionHouses[0]?.alliance || 0),
      horde: Number(auctionHouses[0]?.horde || 0),
      neutral: Number(auctionHouses[0]?.neutral || 0)
    }
  };
}

async function listDownloads() {
  try {
    const entries = await fs.readdir(downloadDir, { withFileTypes: true });
    const files = await Promise.all(entries
      .filter((entry) => entry.isFile())
      .map(async (entry) => {
        const fullPath = path.join(downloadDir, entry.name);
        const stat = await fs.stat(fullPath);
        return {
          name: entry.name,
          size: stat.size,
          href: `/downloads/${encodeURIComponent(entry.name)}`
        };
      }));

    return files.sort((a, b) => a.name.localeCompare(b.name));
  } catch {
    return [];
  }
}

function formatBytes(bytes) {
  if (!bytes) return "0 B";
  const units = ["B", "KB", "MB", "GB", "TB"];
  const index = Math.min(Math.floor(Math.log(bytes) / Math.log(1024)), units.length - 1);
  return `${(bytes / 1024 ** index).toFixed(index === 0 ? 0 : 1)} ${units[index]}`;
}

app.get("/", async (req, res) => {
  const flash = req.query.created ? "Account aangemaakt. Je kunt nu inloggen." : "";
  try {
    const [status, downloads] = await Promise.all([getStatus(), listDownloads()]);
    res.render("index", { status, downloads, flash, error: "", formatBytes, REALM_NAME, LAN_IP, PUBLIC_HOST, PORTAL_PUBLIC_URL, WORLD_PORT, AUTH_PORT });
  } catch (error) {
    res.status(503).render("index", {
      status: EMPTY_STATUS,
      downloads: [],
      flash: "",
      error: `Database nog niet klaar: ${error.message}`,
      formatBytes,
      REALM_NAME,
      LAN_IP,
      PUBLIC_HOST,
      PORTAL_PUBLIC_URL,
      WORLD_PORT,
      AUTH_PORT
    });
  }
});

app.post("/accounts", async (req, res) => {
  let input;
  try {
    input = normalizeAccountInput(req.body.username, req.body.password, req.body.email);
  } catch (error) {
    const [status, downloads] = await Promise.all([getStatus().catch(() => EMPTY_STATUS), listDownloads()]);
    return res.status(400).render("index", { status, downloads, flash: "", error: error.message, formatBytes, REALM_NAME, LAN_IP, PUBLIC_HOST, PORTAL_PUBLIC_URL, WORLD_PORT, AUTH_PORT });
  }

  const connection = await db.getConnection();
  try {
    const [existing] = await connection.query("SELECT id FROM account WHERE username = ? LIMIT 1", [input.cleanName]);
    if (existing.length) throw new Error("Die accountnaam bestaat al.");

    const { salt, verifier } = makeRegistrationData(input.cleanName, input.cleanPass);
    await connection.beginTransaction();
    await connection.query(
      "INSERT INTO account(username, salt, verifier, expansion, reg_mail, email, joindate) VALUES(?, ?, ?, 2, ?, ?, NOW())",
      [input.cleanName, salt, verifier, input.cleanEmail, input.cleanEmail]
    );
    await connection.query(
      "INSERT INTO realmcharacters (realmid, acctid, numchars) SELECT realmlist.id, account.id, 0 FROM realmlist, account LEFT JOIN realmcharacters ON acctid=account.id WHERE acctid IS NULL"
    );
    await connection.commit();
    res.redirect("/?created=1");
  } catch (error) {
    await connection.rollback().catch(() => {});
    const [status, downloads] = await Promise.all([getStatus().catch(() => EMPTY_STATUS), listDownloads()]);
    res.status(400).render("index", { status, downloads, flash: "", error: error.message, formatBytes, REALM_NAME, LAN_IP, PUBLIC_HOST, PORTAL_PUBLIC_URL, WORLD_PORT, AUTH_PORT });
  } finally {
    connection.release();
  }
});

app.get("/downloads/:file", async (req, res) => {
  const decoded = path.basename(req.params.file);
  const baseDir = path.resolve(downloadDir);
  const fullPath = path.resolve(baseDir, decoded);
  if (!fullPath.startsWith(`${baseDir}${path.sep}`)) {
    return res.sendStatus(404);
  }
  res.download(fullPath, decoded);
});

app.get("/health", async (_req, res) => {
  await db.query("SELECT 1");
  res.json({ ok: true });
});

app.listen(port, () => {
  console.log(`World of Cees portal listening on ${port}`);
});
