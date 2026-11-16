# YShop API v2

NestJS 11 · PostgreSQL 16 · Prisma 7

```bash
cp .env.example .env        # fill the secrets: openssl rand -hex 48
createdb yshop
npm install
npx prisma migrate dev
npm run dev                 # http://localhost:3000/api/v2 · docs at /docs
```

The server listens on `0.0.0.0`, so an iPhone on the same Wi-Fi reaches it at the LAN address printed on start.

## Auth
| Method | Path | |
|---|---|---|
| POST | `/auth/register` | e-mail + password |
| POST | `/auth/login` | migrated bcrypt hashes are upgraded to argon2 on first login |
| POST | `/auth/apple` | Sign in with Apple identity token |
| POST | `/auth/google` | Google ID token |
| POST | `/auth/refresh` | rotating refresh token; reuse of an old one revokes every session |
| POST | `/auth/logout` | |
| GET  | `/auth/me` | |
| POST | `/auth/change-password` | signs out every other device |

Errors always look like `{ "error": { "status", "code", "message" } }`.
