import { ArgumentsHost, Catch, ExceptionFilter, HttpException, HttpStatus, Logger } from '@nestjs/common';
import type { Response } from 'express';

/**
 * Every error leaves in one shape the apps can rely on:
 *   { "error": { "status": 400, "code": "EMAIL_TAKEN", "message": "…" } }
 * Unknown errors are logged and returned as a plain 500 — no stack traces.
 */
@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger('HTTP');

  catch(exception: unknown, host: ArgumentsHost) {
    const res = host.switchToHttp().getResponse<Response>();
    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const body = exception.getResponse() as string | { message?: string | string[]; code?: string };
      const raw = typeof body === 'string' ? body : body.message;
      const message = Array.isArray(raw) ? raw[0] : (raw ?? exception.message);
      const code = typeof body === 'object' && body.code ? body.code : HttpStatus[status];
      res.status(status).json({ error: { status, code, message } });
      return;
    }
    this.logger.error(exception instanceof Error ? exception.stack : String(exception));
    res.status(500).json({ error: { status: 500, code: 'INTERNAL', message: 'Something went wrong. Try again.' } });
  }
}
