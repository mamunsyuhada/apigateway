import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import { Logger } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const config = app.get(ConfigService);

  app.enableCors({
    origin: '*',
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    preflightContinue: false,
    optionsSuccessStatus: 204,
  });

  const envStage = config.get<string>('ENV_STAGE', 'local');
  const docConfig = new DocumentBuilder()
    .setTitle(`Big Project - Studi Devops - Env: ${envStage}`)
    .setDescription('API Documentation for Big Project v1')
    .setVersion('1')
    .build();

  const document = SwaggerModule.createDocument(app, docConfig);
  SwaggerModule.setup('api-docs', app, document, {
    customSiteTitle: 'Test API Documentation',
    customCss: 'div.renderedMarkdown p { margin:0 !important; }',
    customfavIcon:
      'https://static-00.iconduck.com/assets.00/nestjs-icon-512x510-9nvpcyc3.png',
  });

  const port = config.get<number>('PORT', 3000);
  await app.listen(port);
  Logger.debug('Swagger at http://localhost:3000/api-docs');
}
bootstrap();
