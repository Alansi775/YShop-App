import { OAuth2Client } from 'google-auth-library';
import type { createRemoteJWKSet } from 'jose';

export interface ExternalIdentity {
  sub: string;
  email: string;
  firstName?: string;
  lastName?: string;
}

let appleKeys: ReturnType<typeof createRemoteJWKSet> | null = null;

/**
 * Verifies a Sign in with Apple identity token the way Apple documents:
 * signature against Apple's published keys, issuer appleid.apple.com,
 * audience = our bundle id(s), not expired. Only what the TOKEN says is
 * trusted — never an e-mail the app sends alongside it.
 */
export async function verifyApple(token: string, audiences: string[]): Promise<ExternalIdentity> {
  const { createRemoteJWKSet, jwtVerify } = await import('jose');
  appleKeys ??= createRemoteJWKSet(new URL('https://appleid.apple.com/auth/keys'), {
    timeoutDuration: 10_000,
    cacheMaxAge: 24 * 60 * 60 * 1000,
  });
  const options = { issuer: 'https://appleid.apple.com', audience: audiences };
  const { payload } = await jwtVerify(token, appleKeys, options).catch(async (e: { code?: string }) => {
    if (e.code !== 'ERR_JWKS_TIMEOUT') throw e;
    return jwtVerify(token, appleKeys!, options);
  });
  const email = typeof payload.email === 'string' ? payload.email.trim().toLowerCase() : '';
  if (!payload.sub || !email) throw new Error('Apple identity has no e-mail.');
  return { sub: payload.sub, email };
}

const google = new OAuth2Client();

export async function verifyGoogle(idToken: string, audiences: string[]): Promise<ExternalIdentity> {
  const ticket = await google.verifyIdToken({ idToken, audience: audiences });
  const p = ticket.getPayload();
  if (!p?.sub || !p.email || !p.email_verified) throw new Error('Google identity has no verified e-mail.');
  return { sub: p.sub, email: p.email.toLowerCase(), firstName: p.given_name, lastName: p.family_name };
}
