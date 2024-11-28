# Base 이미지 설정
FROM node:20-alpine AS base
# Installer 단계 - 패키지 설치
FROM base AS installer
RUN apk add --no-cache libc6-compat
# 작업 디렉토리 설정
WORKDIR /app
# 패키지 파일 복사
COPY package.json package-lock.json ./
# 의존성 설치
RUN npm install --frozen-lockfile
# Builder 단계 - 애플리케이션 빌드
FROM base AS builder
# 작업 디렉토리 유지
WORKDIR /app
# 소스 코드 복사
COPY . .
# node_modules 복사 (installer에서 가져옴)
COPY --from=installer /app/node_modules ./node_modules
# 환경 변수 설정 및 빌드
ARG APP_ENV=production
ENV APP_ENV=$APP_ENV
ARG NEXT_PUBLIC_APP_SERVER_URL
ENV NEXT_PUBLIC_APP_SERVER_URL=$NEXT_PUBLIC_APP_SERVER_URL
RUN echo "APP_ENV: $APP_ENV" && \
    echo "NEXT_PUBLIC_APP_SERVER_URL: $NEXT_PUBLIC_APP_SERVER_URL" && \
    npm run build
# Runner 단계 - 프로덕션 실행 환경 준비
FROM base AS runner
# 환경 변수 설정
ENV NODE_ENV=production
# 작업 디렉토리 설정
WORKDIR /app
# 프로덕션 실행을 위한 소유권 변경 및 사용자 설정
RUN mkdir .next && \
    chown -R 1100:1100 .
USER 1100:1100
# 빌드 결과물 복사
COPY --from=builder --chown=1100:1100 /app/.next/standalone ./
COPY --from=builder --chown=1100:1100 /app/.next/static ./.next/static
COPY --from=builder --chown=1100:1100 /app/public ./public

# NEXT_PUBLIC_APP_SERVER_URL 환경 변수를 런타임에도 사용할 수 있도록 설정
ARG NEXT_PUBLIC_APP_SERVER_URL
ENV NEXT_PUBLIC_APP_SERVER_URL=$NEXT_PUBLIC_APP_SERVER_URL

# 포트 설정
EXPOSE 3000
ENV PORT=3000
# 서버 실행
CMD ["node", "server.js"]