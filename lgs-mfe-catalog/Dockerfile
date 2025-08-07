FROM node:18 AS builder

WORKDIR /app

COPY . .

RUN npm install
RUN npm run build

FROM nginx:alpine

COPY --from=builder /app/dist/lgs-mfe-catalog /usr/share/nginx/html

RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf.template
COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]