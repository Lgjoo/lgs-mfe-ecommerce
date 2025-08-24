FROM node:22 AS builder

WORKDIR /app

COPY . .

COPY package*.json ./
RUN npm install --verbose --progress=false

# Simular build lento
COPY . .
RUN echo "🚧 Simulando build lento para teste científico..." && \
    sleep 180 && \
    npm run build

FROM nginx:alpine

COPY --from=builder /app/dist/lgs-mfe-container /usr/share/nginx/html

RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf.template
COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]