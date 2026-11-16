import * as argon2 from 'argon2';
import * as bcrypt from 'bcryptjs';

export const hashPassword = (plain: string) => argon2.hash(plain, { type: argon2.argon2id });

/**
 * Accounts migrated from the old MySQL backend carry bcrypt hashes ($2…).
 * They still sign in; `needsRehash` tells the caller to upgrade to argon2.
 */
export async function verifyPassword(hash: string, plain: string): Promise<{ ok: boolean; needsRehash: boolean }> {
  if (hash.startsWith('$2')) {
    return { ok: await bcrypt.compare(plain, hash), needsRehash: true };
  }
  return { ok: await argon2.verify(hash, plain), needsRehash: false };
}
