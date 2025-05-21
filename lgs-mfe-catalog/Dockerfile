FROM node:22 AS builder

WORKDIR /app

COPY . .

RUN npm install
RUN npm run build

RUN ls -l /app/dist/lgs-mfe-catalog

FROM nginx:alpine

COPY --from=builder /app/dist/lgs-mfe-catalog /usr/share/nginx/html

RUN rm /etc/nginx/conf.d/default.conf

COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]