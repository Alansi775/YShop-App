import 'dotenv/config';

import { networkInterfaces } from 'node:os';
import { join } from 'node:path';

import { Logger, ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';

import { AppModule } from './app.module';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  const config = app.get(ConfigService);

  app.set('trust proxy', 1);
  app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
  app.enableCors();
  app.setGlobalPrefix('api/v2', { exclude: ['health'] });
  app.useStaticAssets(join(process.cwd(), 'uploads'), { prefix: '/uploads', maxAge: '30d' });
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
  app.useGlobalFilters(new HttpExceptionFilter());

  const doc = new DocumentBuilder().setTitle('YShop API').setVersion('2.0').addBearerAuth().build();
  SwaggerModule.setup('docs', app, SwaggerModule.createDocument(app, doc));

  const port = config.getOrThrow<number>('port');
  await app.listen(port, config.getOrThrow<string>('host'));

  const lan = Object.values(networkInterfaces())
    .flat()
    .find((i) => i?.family === 'IPv4' && !i.internal)?.address;
  const log = new Logger('YShop');
  log.log(`API      http://localhost:${port}/api/v2`);
  if (lan) log.log(`iPhone   http://${lan}:${port}/api/v2  (same Wi-Fi)`);
  log.log(`Docs     http://localhost:${port}/docs`);
}
bootstrap();
